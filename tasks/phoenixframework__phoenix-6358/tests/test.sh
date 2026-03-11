#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.auth_test.exs" "test/mix/tasks/phx.gen.auth_test.exs"
mkdir -p "test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.context_test.exs" "test/mix/tasks/phx.gen.context_test.exs"
mkdir -p "test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.html_test.exs" "test/mix/tasks/phx.gen.html_test.exs"
mkdir -p "test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.json_test.exs" "test/mix/tasks/phx.gen.json_test.exs"
mkdir -p "test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.live_test.exs" "test/mix/tasks/phx.gen.live_test.exs"

# Run the specific test files for this PR
mix test test/mix/tasks/phx.gen.auth_test.exs test/mix/tasks/phx.gen.context_test.exs test/mix/tasks/phx.gen.html_test.exs test/mix/tasks/phx.gen.json_test.exs test/mix/tasks/phx.gen.live_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
