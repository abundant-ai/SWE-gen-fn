#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/extensions.t"
cp "/tests/extensions.t/input.re" "test/extensions.t/input.re"
mkdir -p "test/extensions.t"
cp "/tests/extensions.t/run.t" "test/extensions.t/run.t"
mkdir -p "test/unicodeIdentifiers.t"
cp "/tests/unicodeIdentifiers.t/input.re" "test/unicodeIdentifiers.t/input.re"
mkdir -p "test/unicodeIdentifiers.t"
cp "/tests/unicodeIdentifiers.t/run.t" "test/unicodeIdentifiers.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/extensions.t test/unicodeIdentifiers.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
