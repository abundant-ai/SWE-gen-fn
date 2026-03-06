#!/bin/bash

cd /app/src

# Set environment variable for golden file generation
export HSPEC_ACCEPT=false

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/4431-2.purs" "tests/purs/passing/4431-2.purs"
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/4431.purs" "tests/purs/passing/4431.purs"

# Run the specific test cases for 4431
# HSpec pattern matches test descriptions
# This will match both '4431.purs' and '4431-2.purs' test descriptions
stack test --fast --ta "--match 4431"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
