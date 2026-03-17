#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Reconfigure needed since patches may modify configuration files
make clean && \
./configure \
    --disable-warn-error \
    --disable-ocamldoc \
    --disable-stdlib-manpages && \
make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/typing-fstclassmod"
cp "/tests/testsuite/tests/typing-fstclassmod/scope_escape.ml" "testsuite/tests/typing-fstclassmod/scope_escape.ml"
mkdir -p "testsuite/tests/typing-gadts"
cp "/tests/testsuite/tests/typing-gadts/unexpected_existentials.ml" "testsuite/tests/typing-gadts/unexpected_existentials.ml"
mkdir -p "testsuite/tests/typing-implicit_unpack"
cp "/tests/testsuite/tests/typing-implicit_unpack/implicit_unpack.ml" "testsuite/tests/typing-implicit_unpack/implicit_unpack.ml"
mkdir -p "testsuite/tests/typing-misc"
cp "/tests/testsuite/tests/typing-misc/let_rec_pat.ml" "testsuite/tests/typing-misc/let_rec_pat.ml"

# Run the specific test files using OCaml's testsuite infrastructure
# OCaml uses 'make one TEST=...' to run individual tests
cd testsuite

# Run all 4 test files - they must all pass
make one TEST=tests/typing-fstclassmod/scope_escape.ml && \
make one TEST=tests/typing-gadts/unexpected_existentials.ml && \
make one TEST=tests/typing-implicit_unpack/implicit_unpack.ml && \
make one TEST=tests/typing-misc/let_rec_pat.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
