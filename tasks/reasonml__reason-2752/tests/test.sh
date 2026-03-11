#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/5.2.0
export PATH="/root/.opam/5.2.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/rtopIntegration.t" "test/rtopIntegration.t"

# If reason_toploop.cppo.ml exists (fix applied), remove reason_toploop.ml to avoid build conflicts
if [ -f "rtop/reason_toploop.cppo.ml" ]; then
    rm -f rtop/reason_toploop.ml
fi

# Run the specific cram test for this PR (dune will build what's needed)
opam exec -- dune runtest test/rtopIntegration.t
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
