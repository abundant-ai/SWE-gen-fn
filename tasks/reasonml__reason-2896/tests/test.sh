#!/bin/bash

cd /app/src

# Set opam environment
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
export PATH="/root/.opam/4.14.0/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/lib"
cp "/tests/lib/outcometreePrinter.cppo.ml" "test/lib/outcometreePrinter.cppo.ml"

# Build the specific test executable
opam exec -- dune build test/lib/outcometreePrinter.exe
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
