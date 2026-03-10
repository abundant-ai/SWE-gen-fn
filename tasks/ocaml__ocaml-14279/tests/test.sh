#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/parsetree"
cp "/tests/testsuite/tests/parsetree/source.ml" "testsuite/tests/parsetree/source.ml"
mkdir -p "testsuite/tests/parsing"
cp "/tests/testsuite/tests/parsing/rawidents.ml" "testsuite/tests/parsing/rawidents.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite

# Run tests for the modified test files
make one TEST=tests/parsetree/source.ml
test_status=$?

# If first test passed, run the second test
if [ $test_status -eq 0 ]; then
  make one TEST=tests/parsing/rawidents.ml
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
