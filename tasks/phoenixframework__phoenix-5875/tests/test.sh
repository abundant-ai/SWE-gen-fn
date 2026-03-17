#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/test/phoenix/endpoint"
cp "/tests/phoenix/endpoint/supervisor_test.exs" "/app/src/test/phoenix/endpoint/supervisor_test.exs"

# Run the specific test files for PR #5875
cd /app/src
mix test test/phoenix/endpoint/supervisor_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
