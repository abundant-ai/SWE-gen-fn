#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/4.10/attributes-re.t"
cp "/tests/4.10/attributes-re.t/run.t" "test/4.10/attributes-re.t/run.t"
mkdir -p "test/4.12/attributes-re.t"
cp "/tests/4.12/attributes-re.t/run.t" "test/4.12/attributes-re.t/run.t"
mkdir -p "test/basicStructures.t"
cp "/tests/basicStructures.t/run.t" "test/basicStructures.t/run.t"
mkdir -p "test/general-syntax-re.t"
cp "/tests/general-syntax-re.t/run.t" "test/general-syntax-re.t/run.t"
mkdir -p "test/patternMatching.t"
cp "/tests/patternMatching.t/run.t" "test/patternMatching.t/run.t"
mkdir -p "test/wrapping-re.t"
cp "/tests/wrapping-re.t/run.t" "test/wrapping-re.t/run.t"

# Run specific cram tests using dune
opam exec -- dune runtest test/4.10/attributes-re.t test/4.12/attributes-re.t test/basicStructures.t test/general-syntax-re.t test/patternMatching.t test/wrapping-re.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
