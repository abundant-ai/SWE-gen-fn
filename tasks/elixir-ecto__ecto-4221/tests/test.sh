#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export MIX_ENV=test
export FORCE_COLOR=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/ecto/query"
cp "/tests/ecto/query/planner_test.exs" "test/ecto/query/planner_test.exs"

# Update dependencies if mix.lock changed (Oracle applies fix.patch which updates mix.lock)
mix deps.get 2>&1 | grep -v "warning: the VM is running with native name encoding" || true

# Run the specific test file from the PR
mix test test/ecto/query/planner_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
