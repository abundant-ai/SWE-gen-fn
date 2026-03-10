#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/lib-int"
cp "/tests/testsuite/tests/lib-int/test.ml" "testsuite/tests/lib-int/test.ml"
mkdir -p "testsuite/tests/lib-int64"
cp "/tests/testsuite/tests/lib-int64/test.ml" "testsuite/tests/lib-int64/test.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite

# Run tests for the modified test files
make one TEST=tests/lib-int/test.ml
lib_int_status=$?

make one TEST=tests/lib-int64/test.ml
lib_int64_status=$?

# Overall test status: pass only if all tests pass
test_status=0
if [ $lib_int_status -ne 0 ] || [ $lib_int64_status -ne 0 ]; then
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
