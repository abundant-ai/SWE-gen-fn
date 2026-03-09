#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/dune" "test/dune"
mkdir -p "test/fdLeak.t"
cp "/tests/fdLeak.t/input.re" "test/fdLeak.t/input.re"
mkdir -p "test/fdLeak.t"
cp "/tests/fdLeak.t/run.t" "test/fdLeak.t/run.t"
mkdir -p "test/lib"
cp "/tests/lib/dune" "test/lib/dune"
mkdir -p "test/lib"
cp "/tests/lib/fdLeak.ml" "test/lib/fdLeak.ml"

# Run the specific cram test for this PR (dune will build what's needed)
opam exec -- dune runtest test/fdLeak.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
