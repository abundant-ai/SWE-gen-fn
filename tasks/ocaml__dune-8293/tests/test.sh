#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/ctypes"
cp "/tests/blackbox-tests/test-cases/ctypes/delete-0.1.t" "test/blackbox-tests/test-cases/ctypes/delete-0.1.t"
mkdir -p "test/blackbox-tests/test-cases/ctypes"
cp "/tests/blackbox-tests/test-cases/ctypes/delete-0.2.t" "test/blackbox-tests/test-cases/ctypes/delete-0.2.t"
mkdir -p "test/blackbox-tests/test-cases/ctypes"
cp "/tests/blackbox-tests/test-cases/ctypes/directories.t" "test/blackbox-tests/test-cases/ctypes/directories.t"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-pkg_config-multiple-fd.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-pkg_config-multiple-fd.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-pkg_config-multiple-fd.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-pkg_config.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-pkg_config.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-pkg_config.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-vendored-multiple-fd.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-vendored-multiple-fd.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-vendored-multiple-fd.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-vendored-override-types-generated.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-vendored-override-types-generated.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-vendored-override-types-generated.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-vendored-preamble.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-vendored-preamble.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-vendored-preamble.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/exe-vendored.t"
cp "/tests/blackbox-tests/test-cases/ctypes/exe-vendored.t/dune-project" "test/blackbox-tests/test-cases/ctypes/exe-vendored.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes"
cp "/tests/blackbox-tests/test-cases/ctypes/function-description-collision.t" "test/blackbox-tests/test-cases/ctypes/function-description-collision.t"
mkdir -p "test/blackbox-tests/test-cases/ctypes"
cp "/tests/blackbox-tests/test-cases/ctypes/github-5561-name-mangle.t" "test/blackbox-tests/test-cases/ctypes/github-5561-name-mangle.t"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-external-name-need-mangling.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-external-name-need-mangling.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-external-name-need-mangling.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-pkg_config-multiple-fd.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-pkg_config-multiple-fd.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-pkg_config-multiple-fd.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-pkg_config.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-pkg_config.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-pkg_config.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-return-errno.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-return-errno.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-return-errno.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-vendored-multiple-fd.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-vendored-multiple-fd.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-vendored-multiple-fd.t/dune-project"
mkdir -p "test/blackbox-tests/test-cases/ctypes/lib-vendored.t"
cp "/tests/blackbox-tests/test-cases/ctypes/lib-vendored.t/dune-project" "test/blackbox-tests/test-cases/ctypes/lib-vendored.t/dune-project"

# Clean build artifacts to avoid stale state
rm -rf _build .duneboot.exe _boot

# Rebuild dune after patches have been applied (Oracle applies fix, NOP doesn't)
echo "Rebuilding dune..."
opam exec -- ocaml boot/bootstrap.ml 2>&1
bootstrap_status=$?

if [ $bootstrap_status -ne 0 ]; then
  echo "Bootstrap failed with exit code $bootstrap_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap 2>&1
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Build failed with exit code $build_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific tests for this PR using the bootstrapped dune
echo "Running tests for PR #8293..."

# Run the specific test directory for this PR (ctypes tests)
opam exec -- ./_boot/dune.exe runtest test/blackbox-tests/test-cases/ctypes 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
