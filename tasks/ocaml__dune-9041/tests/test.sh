#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases"
cp "/tests/blackbox-tests/test-cases/corrections.t" "test/blackbox-tests/test-cases/corrections.t"
mkdir -p "test/blackbox-tests/test-cases"
cp "/tests/blackbox-tests/test-cases/sandboxing.t" "test/blackbox-tests/test-cases/sandboxing.t"

# Run the specific tests for this PR
# For cram tests in dune, use the @ alias syntax without the .t extension
cd test/blackbox-tests/test-cases
dune build @corrections @sandboxing
test_status=$?
cd /app/src

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
