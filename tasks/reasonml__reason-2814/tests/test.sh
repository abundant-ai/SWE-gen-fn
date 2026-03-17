#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/5.2.0
export PATH="/root/.opam/5.2.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/extension-exprs.t"
cp "/tests/extension-exprs.t/input.re" "test/extension-exprs.t/input.re"
mkdir -p "test/extension-exprs.t"
cp "/tests/extension-exprs.t/run.t" "test/extension-exprs.t/run.t"
mkdir -p "test/extensions.t"
cp "/tests/extensions.t/run.t" "test/extensions.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/extension-exprs.t test/extensions.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
