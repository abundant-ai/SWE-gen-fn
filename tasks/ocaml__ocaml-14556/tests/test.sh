#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
make -j$(nproc)

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-misc-bugs"
cp "/tests/testsuite/tests/typing-misc-bugs/pr14554_1.ml" "testsuite/tests/typing-misc-bugs/pr14554_1.ml"
mkdir -p "testsuite/tests/typing-misc"
cp "/tests/testsuite/tests/typing-misc/letitem.ml" "testsuite/tests/typing-misc/letitem.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite
make one TEST=tests/typing-misc-bugs/pr14554_1.ml
test_status_1=$?

make one TEST=tests/typing-misc/letitem.ml
test_status_2=$?

# Both tests must pass
if [ $test_status_1 -eq 0 ] && [ $test_status_2 -eq 0 ]; then
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
