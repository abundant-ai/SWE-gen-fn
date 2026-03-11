#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/backtrace"
cp "/tests/testsuite/tests/backtrace/backtrace_dynlink.flambda.reference" "testsuite/tests/backtrace/backtrace_dynlink.flambda.reference"
mkdir -p "testsuite/tests/backtrace"
cp "/tests/testsuite/tests/backtrace/backtrace_dynlink.reference" "testsuite/tests/backtrace/backtrace_dynlink.reference"
mkdir -p "testsuite/tests/lib-dynlink-initializers"
cp "/tests/testsuite/tests/lib-dynlink-initializers/test10_main.byte.reference" "testsuite/tests/lib-dynlink-initializers/test10_main.byte.reference"
mkdir -p "testsuite/tests/lib-dynlink-initializers"
cp "/tests/testsuite/tests/lib-dynlink-initializers/test10_main.native.reference" "testsuite/tests/lib-dynlink-initializers/test10_main.native.reference"
mkdir -p "testsuite/tests/lib-dynlink-pr14323"
cp "/tests/testsuite/tests/lib-dynlink-pr14323/test.ml" "testsuite/tests/lib-dynlink-pr14323/test.ml"
mkdir -p "testsuite/tests/lib-dynlink-pr14323"
cp "/tests/testsuite/tests/lib-dynlink-pr14323/test.reference" "testsuite/tests/lib-dynlink-pr14323/test.reference"
mkdir -p "testsuite/tests/lib-dynlink-pr14323"
cp "/tests/testsuite/tests/lib-dynlink-pr14323/test.sh" "testsuite/tests/lib-dynlink-pr14323/test.sh"
chmod +x "testsuite/tests/lib-dynlink-pr14323/test.sh"

# Run the specific test files using OCaml's testsuite infrastructure
cd testsuite

# Run each test directory sequentially
# We'll run the main test files from each directory that was modified
make one TEST=tests/backtrace/backtrace_dynlink.ml && \
make one TEST=tests/lib-dynlink-initializers/test10_main.ml && \
make one TEST=tests/lib-dynlink-pr14323/test.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
