#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/modules.t"
cp "/tests/modules.t/run.t" "test/modules.t/run.t"
mkdir -p "test/modules_no_semi.t"
cp "/tests/modules_no_semi.t/run.t" "test/modules_no_semi.t/run.t"
mkdir -p "test/whitespace-rei.t"
cp "/tests/whitespace-rei.t/run.t" "test/whitespace-rei.t/run.t"
mkdir -p "test/wrapping-re.t"
cp "/tests/wrapping-re.t/run.t" "test/wrapping-re.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/modules.t test/modules_no_semi.t test/whitespace-rei.t test/wrapping-re.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
