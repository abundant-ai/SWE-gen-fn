#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix/controller"
cp "/tests/phoenix/controller/render_test.exs" "test/phoenix/controller/render_test.exs"
mkdir -p "test/phoenix/endpoint"
cp "/tests/phoenix/endpoint/render_errors_test.exs" "test/phoenix/endpoint/render_errors_test.exs"

# Run the specific test files for this PR
mix test test/phoenix/controller/render_test.exs test/phoenix/endpoint/render_errors_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
