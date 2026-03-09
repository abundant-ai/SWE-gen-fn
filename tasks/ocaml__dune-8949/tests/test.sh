#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Rebuild dune if source files were modified (by Oracle agent)
# This ensures we test the current code state
echo "Rebuilding dune to reflect any code changes..."
opam exec -- ocaml boot/bootstrap.ml > /dev/null 2>&1
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap > /dev/null 2>&1

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Manual test: replicate the cram test scenario
# The test checks if menhir modules work with (include_subdirs qualified)
cd /tmp
mkdir -p test_scenario
cd test_scenario

# Set up the test project structure
cat >dune-project <<'EOF'
(lang dune 3.7)
(using menhir 2.1)
(name foo)
EOF

cat >foo.ml <<'EOF'
let _ =
  Bar.Baz.unit (fun _ -> Bar.Baz.EOF) (Lexing.from_string "")
EOF

mkdir -p bar
cat >bar/baz.mly <<'EOF'
%token EOF
%start <unit> unit
%%
unit: EOF {}
EOF

cat >bar/dune <<'EOF'
(menhir
 (modules baz))
EOF

# The actual test: try building with (include_subdirs qualified)
cat >dune <<'EOF'
(include_subdirs qualified)
(executable (name foo))
EOF

# In the buggy state, this should fail with an error about not being able to
# determine what library/executable the menhir stanza is part of.
# In the fixed state, this should succeed.
test_output=$(dune build foo.exe 2>&1)
test_status=$?

# The test PASSES (reward=1) if the build SUCCEEDS (exit code 0)
# The test FAILS (reward=0) if the build FAILS (exit code non-zero)
if [ $test_status -eq 0 ]; then
  # Build succeeded - test passed
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  # Build failed - test failed
  echo "$test_output"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
