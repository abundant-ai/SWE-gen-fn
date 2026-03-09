#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/expect-tests"
cp "/tests/expect-tests/dune" "test/expect-tests/dune"
mkdir -p "test/expect-tests"
cp "/tests/expect-tests/persistent_tests.ml" "test/expect-tests/persistent_tests.ml"
mkdir -p "test/expect-tests"
cp "/tests/expect-tests/persistent_tests.mli" "test/expect-tests/persistent_tests.mli"

# Rebuild dune to reflect the current code state (buggy for NOP, fixed for Oracle)
echo "Rebuilding dune..."

# Clean build directory to avoid stale artifacts from the buggy build in Dockerfile
rm -rf _build

# Build the full dune using the bootstrapped dune
opam exec -- ./_boot/dune.exe build @install --release 2>&1
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Build failed with exit code $build_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific inline tests for persistent_tests library
echo "Running tests for PR #8213 (persistent_tests)..."
opam exec -- ./_boot/dune.exe runtest test/expect-tests --force 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
