#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/duplicate-c-cxx-obj/diff-stanza.t"
cp "/tests/blackbox-tests/test-cases/duplicate-c-cxx-obj/diff-stanza.t/run.t" "test/blackbox-tests/test-cases/duplicate-c-cxx-obj/diff-stanza.t/run.t"
mkdir -p "test/blackbox-tests/test-cases/duplicate-c-cxx/diff-stanza.t"
cp "/tests/blackbox-tests/test-cases/duplicate-c-cxx/diff-stanza.t/run.t" "test/blackbox-tests/test-cases/duplicate-c-cxx/diff-stanza.t/run.t"

# Run the specific tests for this PR
# Run only the duplicate-c-cxx-obj and duplicate-c-cxx cram tests
opam exec -- dune build @test/blackbox-tests/test-cases/duplicate-c-cxx-obj/diff-stanza
test_status_1=$?

opam exec -- dune build @test/blackbox-tests/test-cases/duplicate-c-cxx/diff-stanza
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
