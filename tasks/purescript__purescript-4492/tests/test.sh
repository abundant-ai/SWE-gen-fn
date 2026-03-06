#!/bin/bash

cd /app/src

# Set environment variable for golden file generation
export HSPEC_ACCEPT=false

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/warning"
cp "/tests/purs/warning/VTAsWildcardInferred.out" "tests/purs/warning/VTAsWildcardInferred.out"
mkdir -p "tests/purs/warning"
cp "/tests/purs/warning/VTAsWildcardInferred.purs" "tests/purs/warning/VTAsWildcardInferred.purs"

# Run the specific test case for VTAsWildcardInferred
# HSpec uses pattern matching to run only tests matching this pattern
stack test --fast --ta "--match 'VTAsWildcardInferred.purs'"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
