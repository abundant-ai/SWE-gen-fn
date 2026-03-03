#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/lib"
cp "/tests/lib/fdLeak.ml" "test/lib/fdLeak.ml"

# Rebuild the test executable with the updated file
opam exec -- dune build test/lib/fdLeak.exe

# Run the cram test for fdLeak
opam exec -- dune runtest test/fdLeak.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
