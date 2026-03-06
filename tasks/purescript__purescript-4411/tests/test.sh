#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/NestedRecordLabelOnTypeError.out" "tests/purs/failing/NestedRecordLabelOnTypeError.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/NestedRecordLabelOnTypeError.purs" "tests/purs/failing/NestedRecordLabelOnTypeError.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/RecordLabelOnTypeError.out" "tests/purs/failing/RecordLabelOnTypeError.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/RecordLabelOnTypeError.purs" "tests/purs/failing/RecordLabelOnTypeError.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/RecordLabelOnTypeErrorImmediate.out" "tests/purs/failing/RecordLabelOnTypeErrorImmediate.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/RecordLabelOnTypeErrorImmediate.purs" "tests/purs/failing/RecordLabelOnTypeErrorImmediate.purs"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific failing tests
# HSpec pattern matches test descriptions - this will match the three RecordLabel tests
stack test --fast --ta "--match RecordLabelOnTypeError"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
