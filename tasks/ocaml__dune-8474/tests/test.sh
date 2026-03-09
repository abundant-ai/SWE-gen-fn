#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Rebuild dune after patches have been applied (Oracle applies fix, NOP doesn't)
echo "Rebuilding dune..."
opam exec -- ocaml boot/bootstrap.ml 2>&1
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap 2>&1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/exec-bin-test"
cp "/tests/blackbox-tests/test-cases/exec-bin.t" "test/blackbox-tests/test-cases/exec-bin-test/exec-bin.t"

# Use the bootstrapped dune binary for testing (already built in Dockerfile)
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific test for this PR using the test subdirectory
echo "Running exec-bin test..."
opam exec -- ./_boot/dune.exe build @test/blackbox-tests/test-cases/exec-bin-test/runtest 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
