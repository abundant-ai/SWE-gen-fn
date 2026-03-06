#!/bin/bash

cd /app/src

# Set environment variable for golden file generation
export HSPEC_ACCEPT=false

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/4500.purs" "tests/purs/passing/4500.purs"

# Run the specific test case for 4500
# HSpec uses pattern matching to run only tests matching this pattern
stack test --fast --ta "--match '4500.purs'"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
