#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "otherlibs/stdune/test"
cp "/tests/otherlibs/stdune/test/appendable_list_tests.ml" "otherlibs/stdune/test/appendable_list_tests.ml"

# Run the specific test for this PR using the locally built dune
dune runtest otherlibs/stdune/test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
