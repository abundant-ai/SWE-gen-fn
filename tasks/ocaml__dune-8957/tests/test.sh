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
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/opam-package-cycle-with-or.t" "test/blackbox-tests/test-cases/pkg/opam-package-cycle-with-or.t"
cp "/tests/blackbox-tests/test-cases/pkg/opam-package-cycle.t" "test/blackbox-tests/test-cases/pkg/opam-package-cycle.t"
cp "/tests/blackbox-tests/test-cases/pkg/outdated.t" "test/blackbox-tests/test-cases/pkg/outdated.t"

# Run the pkg tests and capture output
test_output=$(dune build @test/blackbox-tests/test-cases/pkg/runtest 2>&1)
test_status=$?

# Check if our specific test files passed by looking for failures in the output
# If the tests failed, they will appear in the diff output
opam_cycle_with_or_failed=$(echo "$test_output" | grep -c "pkg/opam-package-cycle-with-or.t")
opam_cycle_failed=$(echo "$test_output" | grep -c "pkg/opam-package-cycle.t")
outdated_failed=$(echo "$test_output" | grep -c "pkg/outdated.t")

# The tests PASS if they are NOT mentioned in the error output
# (dune only shows diffs for failed tests)
if [ "$opam_cycle_with_or_failed" -eq 0 ] && [ "$opam_cycle_failed" -eq 0 ] && [ "$outdated_failed" -eq 0 ]; then
  # All three of our tests passed
  echo 1 > /logs/verifier/reward.txt
  exit 0
else
  # At least one of our tests failed
  echo "$test_output"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi
