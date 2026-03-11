#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export MIX_ENV=test
export FORCE_COLOR=1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/ecto/repo"
cp "/tests/ecto/repo/autogenerate_test.exs" "test/ecto/repo/autogenerate_test.exs"
mkdir -p "test/ecto"
cp "/tests/ecto/uuid_test.exs" "test/ecto/uuid_test.exs"

# Run the specific test files from the PR
mix test test/ecto/repo/autogenerate_test.exs test/ecto/uuid_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
