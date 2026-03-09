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

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/directory-targets"
cp "/tests/blackbox-tests/test-cases/directory-targets/installed-dependency.t" "test/blackbox-tests/test-cases/directory-targets/installed-dependency.t"

# Run the directory-targets tests and capture output
test_output=$(dune build @test/blackbox-tests/test-cases/directory-targets/runtest 2>&1)
test_status=$?

# Check if our specific test file passed by looking for failures in the output
# If the test failed, it will appear in the diff output
installed_dependency_failed=$(echo "$test_output" | grep -c "directory-targets/installed-dependency.t")

# The test PASSES if it is NOT mentioned in the error output
# (dune only shows diffs for failed tests)
if [ "$installed_dependency_failed" -eq 0 ]; then
  # Our test passed
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  # Our test failed
  echo "$test_output"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
