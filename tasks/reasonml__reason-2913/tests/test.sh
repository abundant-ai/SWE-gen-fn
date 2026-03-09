#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/dune" "test/dune"
mkdir -p "test/expr-constraint-with-vbct.t"
cp "/tests/expr-constraint-with-vbct.t/input.re" "test/expr-constraint-with-vbct.t/input.re"
mkdir -p "test/expr-constraint-with-vbct.t"
cp "/tests/expr-constraint-with-vbct.t/run.t" "test/expr-constraint-with-vbct.t/run.t"
mkdir -p "test"
cp "/tests/rtopIntegration.t" "test/rtopIntegration.t"
mkdir -p "test/value-constraint-alias-pattern.t"
cp "/tests/value-constraint-alias-pattern.t/input.re" "test/value-constraint-alias-pattern.t/input.re"
mkdir -p "test/value-constraint-alias-pattern.t"
cp "/tests/value-constraint-alias-pattern.t/run.t" "test/value-constraint-alias-pattern.t/run.t"

# Run the specific cram tests for this PR (dune will build what's needed)
opam exec -- dune runtest test/expr-constraint-with-vbct.t test/rtopIntegration.t test/value-constraint-alias-pattern.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
