#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.auth_test.exs" "/app/src/test/mix/tasks/phx.gen.auth_test.exs"

# Run the specific test files for PR #5794
cd /app/src
mix test test/mix/tasks/phx.gen.auth_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
