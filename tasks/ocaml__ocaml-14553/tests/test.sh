#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/array-functions"
cp "/tests/testsuite/tests/array-functions/test.ml" "testsuite/tests/array-functions/test.ml"

# Run the specific test file using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/array-functions/test.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
