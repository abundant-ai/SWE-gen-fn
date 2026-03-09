#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/convert-opam-commands.t" "test/blackbox-tests/test-cases/pkg/convert-opam-commands.t"

# Use the bootstrapped dune binary for testing (already built in Dockerfile)
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific test for this PR using the blackbox test infrastructure
echo "Running convert-opam-commands test..."
opam exec -- ./_boot/dune.exe build @test/blackbox-tests/test-cases/pkg/runtest 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
