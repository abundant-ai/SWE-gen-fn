#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/letop.t"
cp "/tests/letop.t/input.re" "test/letop.t/input.re"
mkdir -p "test/letop.t"
cp "/tests/letop.t/run.t" "test/letop.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/letop.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
