#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export MIX_ENV=test
export FORCE_COLOR=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/ecto/query"
cp "/tests/ecto/query/planner_test.exs" "test/ecto/query/planner_test.exs"
mkdir -p "test/support"
cp "/tests/support/test_repo.exs" "test/support/test_repo.exs"

# Run the specific test files from the PR
mix test test/ecto/query/planner_test.exs test/support/test_repo.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
