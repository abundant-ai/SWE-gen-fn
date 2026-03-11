#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix"
cp "/tests/phoenix/verified_routes_test.exs" "test/phoenix/verified_routes_test.exs"

# Run the specific test file using mix test
mix test test/phoenix/verified_routes_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
