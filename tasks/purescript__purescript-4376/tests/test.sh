#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/4376.purs" "tests/purs/passing/4376.purs"
mkdir -p "tests/purs/warning"
cp "/tests/purs/warning/4376.out" "tests/purs/warning/4376.out"
mkdir -p "tests/purs/warning"
cp "/tests/purs/warning/4376.purs" "tests/purs/warning/4376.purs"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific 4376 test
# HSpec pattern matches test descriptions - this will match the 4376 test
stack test --fast --ta "--match 4376"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
