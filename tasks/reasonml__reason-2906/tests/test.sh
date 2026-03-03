#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/type-constraint-in-body.t"
cp "/tests/type-constraint-in-body.t/input.ml" "test/type-constraint-in-body.t/input.ml"
mkdir -p "test/type-constraint-in-body.t"
cp "/tests/type-constraint-in-body.t/run.t" "test/type-constraint-in-body.t/run.t"

# Run the specific cram test for type-constraint-in-body
opam exec -- dune build @type-constraint-in-body
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
