#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/lib-obj"
cp "/tests/testsuite/tests/lib-obj/with_tag.ml" "testsuite/tests/lib-obj/with_tag.ml"

# Run the specific test file using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/lib-obj/with_tag.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
