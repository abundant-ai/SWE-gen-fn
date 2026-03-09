#!/bin/bash

set -euo pipefail
cd /app/src

# Set up opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Apply the fix patch (fixes package_universe.ml)
patch -p1 < /solution/fix.patch

# WORKAROUND: fix.patch is incomplete - it doesn't restore describe_pkg.ml
# The describe_pkg.ml file should have the List_locked_dependencies module
# which was removed by bug.patch. We need to restore it from HEAD commit.
# Since we don't have .git anymore, we'll apply it as a patch.

# Create patch to restore the List_locked_dependencies module to describe_pkg.ml
cat > /tmp/describe_pkg_fix.patch <<'DESCRIBE_PKG_PATCH'
diff --git a/bin/describe/describe_pkg.ml b/bin/describe/describe_pkg.ml
index 4cc1b6b68..571da5f3d 100644
--- a/bin/describe/describe_pkg.ml
+++ b/bin/describe/describe_pkg.ml
@@ -75,8 +75,135 @@ module Dependency_hash = struct
   let command = Cmd.v info term
 end

+module List_locked_dependencies = struct
+  module Package_universe = Dune_pkg.Package_universe
+  module Lock_dir = Dune_pkg.Lock_dir
+  module Opam_repo = Dune_pkg.Opam_repo
+  module Package_version = Dune_pkg.Package_version
+  module Opam_solver = Dune_pkg.Opam_solver
+
+  let info =
+    let doc = "List the dependencies locked by a lockdir" in
+    let man = [ `S "DESCRIPTION"; `P "List the dependencies locked by a lockdir" ] in
+    Cmd.info "list-locked-dependencies" ~doc ~man
+  ;;
+
+  let package_deps_in_lock_dir_pp package_universe package_name ~transitive =
+    let traverse, traverse_word =
+      if transitive then `Transitive, "Transitive" else `Immediate, "Immediate"
+    in
+    let opam_package =
+      Package_universe.opam_package_of_package package_universe package_name
+    in
+    let list_dependencies which =
+      Package_universe.opam_package_dependencies_of_package
+        package_universe
+        package_name
+        ~which
+        ~traverse
+    in
+    Pp.concat
+      ~sep:Pp.cut
+      [ Pp.hbox
+          (Pp.textf
+             "%s dependencies of local package %s"
+             traverse_word
+             (OpamPackage.to_string opam_package))
+      ; Pp.enumerate (list_dependencies `Non_test) ~f:(fun opam_package ->
+          Pp.text (OpamPackage.to_string opam_package))
+      ; Pp.enumerate (list_dependencies `Test_only) ~f:(fun opam_package ->
+          Pp.textf "%s (test only)" (OpamPackage.to_string opam_package))
+      ]
+    |> Pp.vbox
+  ;;
+
+  let enumerate_lock_dirs_by_path ~context_name_arg ~all_contexts_arg =
+    let open Fiber.O in
+    let+ per_contexts =
+      Pkg_common.Per_context.choose
+        ~context_name_arg
+        ~all_contexts_arg
+        ~version_preference_arg:None
+    in
+    List.filter_map per_contexts ~f:(fun { Pkg_common.Per_context.lock_dir_path; _ } ->
+      if Path.exists (Path.source lock_dir_path)
+      then (
+        try Some (lock_dir_path, Lock_dir.read_disk lock_dir_path) with
+        | User_error.E e ->
+          User_warning.emit
+            [ Pp.textf
+                "Failed to parse lockdir %s:"
+                (Path.Source.to_string_maybe_quoted lock_dir_path)
+            ; User_message.pp e
+            ];
+          None)
+      else None)
+  ;;
+
+  let list_locked_dependencies ~context_name_arg ~all_contexts_arg ~transitive =
+    let open Fiber.O in
+    let+ lock_dirs_by_path =
+      enumerate_lock_dirs_by_path ~context_name_arg ~all_contexts_arg
+    and+ local_packages = Pkg_common.find_local_packages in
+    let pp =
+      Pp.concat
+        ~sep:Pp.cut
+        (List.map lock_dirs_by_path ~f:(fun (lock_dir_path, lock_dir) ->
+           match Package_universe.create local_packages lock_dir with
+           | Error e -> raise (User_error.E e)
+           | Ok package_universe ->
+             Pp.vbox
+               (Pp.concat
+                  ~sep:Pp.cut
+                  [ Pp.hbox
+                      (Pp.textf
+                         "Dependencies of local packages locked in %s"
+                         (Path.Source.to_string_maybe_quoted lock_dir_path))
+                  ; Pp.enumerate
+                      (Package_name.Map.keys local_packages)
+                      ~f:(package_deps_in_lock_dir_pp package_universe ~transitive)
+                    |> Pp.box
+                  ])))
+      |> Pp.vbox
+    in
+    Console.print [ pp ]
+  ;;
+
+  let term =
+    let+ builder = Common.Builder.term
+    and+ context_name =
+      Pkg_common.context_term
+        ~doc:"Print information about the lockdir associated with this context"
+    and+ all_contexts =
+      Arg.(
+        value & flag & info [ "all-contexts" ] ~doc:"Print information about all lockdirs")
+    and+ transitive =
+      Arg.(
+        value
+        & flag
+        & info
+            [ "transitive" ]
+            ~doc:
+              "Display transitive dependencies (by default only immediate dependencies \
+               are displayed)")
+    in
+    let builder = Common.Builder.forbid_builds builder in
+    let common, config = Common.init builder in
+    Scheduler.go ~common ~config
+    @@ fun () ->
+    list_locked_dependencies
+      ~context_name_arg:context_name
+      ~all_contexts_arg:all_contexts
+      ~transitive
+  ;;
+
+  let command = Cmd.v info term
+end
+
 let command =
   let doc = "Subcommands related to package management" in
   let info = Cmd.info ~doc "pkg" in
-  Cmd.group info [ Lock.command; Dependency_hash.command ]
+  Cmd.group
+    info
+    [ Lock.command; List_locked_dependencies.command; Dependency_hash.command ]
 ;;
DESCRIBE_PKG_PATCH

patch -p1 < /tmp/describe_pkg_fix.patch
rm /tmp/describe_pkg_fix.patch

# Rebuild dune after applying all fixes
opam exec -- ocaml boot/bootstrap.ml
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap
