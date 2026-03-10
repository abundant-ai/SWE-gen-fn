#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/lib-string"
cp "/tests/testsuite/tests/lib-string/test_string.ml" "testsuite/tests/lib-string/test_string.ml"
mkdir -p "testsuite/tests/match-side-effects"
cp "/tests/testsuite/tests/match-side-effects/partiality.ml" "testsuite/tests/match-side-effects/partiality.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/lib-string/test_string.ml
test_status1=$?
make one TEST=tests/match-side-effects/partiality.ml
test_status2=$?

# Both tests must pass
if [ $test_status1 -eq 0 ] && [ $test_status2 -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
