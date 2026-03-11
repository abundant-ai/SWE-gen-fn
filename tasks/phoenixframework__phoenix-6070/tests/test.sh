#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix/socket"
cp "/tests/phoenix/socket/socket_test.exs" "test/phoenix/socket/socket_test.exs"

# Run the specific Elixir test file for this PR
mix test test/phoenix/socket/socket_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
