#!/bin/bash

cd /app/src

# Set environment variables for test execution
export MIX_ENV=test

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/ecto"
cp "/tests/ecto/repo_test.exs" "test/ecto/repo_test.exs"

# Run the specific test file
mix test test/ecto/repo_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
