#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/dune" "test/blackbox-tests/test-cases/pkg/dune"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/rev-store-lock.t" "test/blackbox-tests/test-cases/pkg/rev-store-lock.t"
mkdir -p "test/expect-tests/dune_pkg"
cp "/tests/expect-tests/dune_pkg/dune" "test/expect-tests/dune_pkg/dune"
mkdir -p "test/expect-tests/dune_pkg"
cp "/tests/expect-tests/dune_pkg/rev_store_tests.ml" "test/expect-tests/dune_pkg/rev_store_tests.ml"

# Run the specific tests for this PR
# Run only the rev-store-lock cram test and the rev_store_tests expect test
opam exec -- dune build @test/blackbox-tests/test-cases/pkg/rev-store-lock
test_status_1=$?

opam exec -- dune runtest test/expect-tests/dune_pkg
test_status_2=$?

# Exit with failure if either test failed
if [ $test_status_1 -ne 0 ] || [ $test_status_2 -ne 0 ]; then
    test_status=1
else
    test_status=0
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
