#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-warnings"
cp "/tests/testsuite/tests/typing-warnings/warning16.ml" "testsuite/tests/typing-warnings/warning16.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite

# Run the test for the modified test file
make one TEST=tests/typing-warnings/warning16.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
