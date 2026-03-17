#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix/endpoint"
cp "/tests/phoenix/endpoint/endpoint_test.exs" "test/phoenix/endpoint/endpoint_test.exs"

# Run the specific test file for PR #5620
cd /app/src
mix test test/phoenix/endpoint/endpoint_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
