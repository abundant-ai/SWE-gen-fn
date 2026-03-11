#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Clean build required when stdlib files are modified
make clean && make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file"
cp "/tests/testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/foo.ml" "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/foo.ml"
mkdir -p "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file"
cp "/tests/testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/foo.mli" "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/foo.mli"
mkdir -p "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file"
cp "/tests/testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/parse_and_marshall.ml" "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/parse_and_marshall.ml"
mkdir -p "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file"
cp "/tests/testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/test_renamed.compilers.reference" "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/test_renamed.compilers.reference"
mkdir -p "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file"
cp "/tests/testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/test_renamed.ml" "testsuite/tests/typing-modules/inclusion_errors_with_renamed_source_file/test_renamed.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# Use "make one TEST=..." to run a single test file
cd testsuite

# Run the test for the modified test file
make one TEST=tests/typing-modules/inclusion_errors_with_renamed_source_file/test_renamed.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
