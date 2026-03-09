#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-misc"
cp "/tests/testsuite/tests/typing-misc/pr14603.ml" "testsuite/tests/typing-misc/pr14603.ml"

# Run the specific test file using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/typing-misc/pr14603.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
