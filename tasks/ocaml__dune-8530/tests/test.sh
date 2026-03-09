#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/expect-tests/dune_rpc_impl"
cp "/tests/expect-tests/dune_rpc_impl/dune_rpc_impl_tests.ml" "test/expect-tests/dune_rpc_impl/dune_rpc_impl_tests.ml"

# Use the bootstrapped dune binary for testing (already built in Dockerfile)
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific expect tests for this PR
# Note: We use the pre-built dune from the Dockerfile because rebuilding after
# applying fix.patch would fail due to incomplete changes in bin/import.ml
echo "Running expect tests for dune_rpc_impl..."
opam exec -- ./_boot/dune.exe build @test/expect-tests/dune_rpc_impl/runtest 2>&1
test_status=$?
echo "Test dune_rpc_impl exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
