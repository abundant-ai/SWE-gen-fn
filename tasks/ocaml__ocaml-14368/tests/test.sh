#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/basic-more"
cp "/tests/testsuite/tests/basic-more/simplif_under_lambda.ml" "testsuite/tests/basic-more/simplif_under_lambda.ml"
mkdir -p "testsuite/tests/basic-more"
cp "/tests/testsuite/tests/basic-more/simplif_under_lambda.reference" "testsuite/tests/basic-more/simplif_under_lambda.reference"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite

# Run tests for the modified test files
make one TEST=tests/basic-more/simplif_under_lambda.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
