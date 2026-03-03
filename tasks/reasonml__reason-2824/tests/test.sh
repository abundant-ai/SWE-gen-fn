#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/jsx.t"
cp "/tests/jsx.t/input.re" "test/jsx.t/input.re"
mkdir -p "test/jsx.t"
cp "/tests/jsx.t/run.t" "test/jsx.t/run.t"
mkdir -p "test/sequences.t"
cp "/tests/sequences.t/input.re" "test/sequences.t/input.re"
mkdir -p "test/sequences.t"
cp "/tests/sequences.t/run.t" "test/sequences.t/run.t"
mkdir -p "test/typeDeclarations.t"
cp "/tests/typeDeclarations.t/input.re" "test/typeDeclarations.t/input.re"
mkdir -p "test/typeDeclarations.t"
cp "/tests/typeDeclarations.t/run.t" "test/typeDeclarations.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/jsx.t test/sequences.t test/typeDeclarations.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
