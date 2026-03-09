#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/expect-tests/memo"
cp "/tests/expect-tests/memo/main.ml" "test/expect-tests/memo/main.ml"

# Run the inline tests for the memo library using dune from opam
opam exec -- dune runtest test/expect-tests/memo
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
