#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/lib-floatarray"
cp "/tests/testsuite/tests/lib-floatarray/floatarray.ml" "testsuite/tests/lib-floatarray/floatarray.ml"

# Run the specific test file using OCaml's testsuite infrastructure
cd testsuite
make one TEST=tests/lib-floatarray/floatarray.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
