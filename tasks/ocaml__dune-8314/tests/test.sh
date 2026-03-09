#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/just-print-solver-env.t" "test/blackbox-tests/test-cases/pkg/just-print-solver-env.t"

# Create temporary directory to run just our specific tests as cram tests
mkdir -p "test/blackbox-tests/test-cases/pkg-test-temp"

# Copy the test files into the temporary directory
cp "test/blackbox-tests/test-cases/pkg/just-print-solver-env.t" "test/blackbox-tests/test-cases/pkg-test-temp/"

# Create dune file to run these tests
echo "(cram (applies_to :whole_subtree))" > "test/blackbox-tests/test-cases/pkg-test-temp/dune"

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
echo "Running tests for PR #8314..."

# Run the temporary directory with our tests
opam exec -- ./_boot/dune.exe runtest test/blackbox-tests/test-cases/pkg-test-temp 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
