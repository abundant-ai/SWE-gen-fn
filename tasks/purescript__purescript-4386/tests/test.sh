#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/optimize"
cp "/tests/purs/optimize/4386.out.js" "tests/purs/optimize/4386.out.js"
mkdir -p "tests/purs/optimize"
cp "/tests/purs/optimize/4386.purs" "tests/purs/optimize/4386.purs"
mkdir -p "tests/support"
cp "/tests/support/bower.json" "tests/support/bower.json"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific 4386 optimize test
# HSpec pattern matches test descriptions - this will match the 4386 test
stack test --fast --ta "--match 4386"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
