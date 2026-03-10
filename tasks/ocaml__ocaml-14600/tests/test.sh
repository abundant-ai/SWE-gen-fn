#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-misc"
cp "/tests/testsuite/tests/typing-misc/unbound_type_variables.ml" "testsuite/tests/typing-misc/unbound_type_variables.ml"

# Run the specific test file using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/typing-misc/unbound_type_variables.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
