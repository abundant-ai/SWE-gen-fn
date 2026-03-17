#!/bin/bash

cd /app/src

# Rebuild OCaml after any patches were applied (by Oracle agent)
# Reconfigure needed since ocamltest_config.ml.in was modified by fix patch
make clean && \
./configure \
    --disable-warn-error \
    --disable-ocamldoc \
    --disable-stdlib-manpages && \
make && make ocamltest

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "testsuite/tests/cxx-api"
cp "/tests/testsuite/tests/cxx-api/cxx_api.ml" "testsuite/tests/cxx-api/cxx_api.ml"
mkdir -p "testsuite/tests/cxx-api"
cp "/tests/testsuite/tests/cxx-api/cxx_api.reference" "testsuite/tests/cxx-api/cxx_api.reference"
mkdir -p "testsuite/tests/cxx-api"
cp "/tests/testsuite/tests/cxx-api/stubs.cpp" "testsuite/tests/cxx-api/stubs.cpp"
mkdir -p "testsuite/tests/lib-unix/unix-sockaddr"
cp "/tests/testsuite/tests/lib-unix/unix-sockaddr/sockaddr_cxx.ml" "testsuite/tests/lib-unix/unix-sockaddr/sockaddr_cxx.ml"

# Run the specific test file using OCaml's testsuite infrastructure
# Note: In the buggy state, all_includes.ml exists; HEAD state restores cxx_api.ml
cd testsuite
make one TEST=tests/cxx-api/all_includes.ml
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
