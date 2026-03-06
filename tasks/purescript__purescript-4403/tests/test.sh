#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/json-compat/v0.14.0"
cp "/tests/json-compat/v0.14.0/prelude-5.0.1.json" "tests/json-compat/v0.14.0/prelude-5.0.1.json"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific json-compat test
# HSpec pattern matches test descriptions - this will match the prelude-5.0.1.json test
stack test --fast --ta "--match prelude-5.0.1.json"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
