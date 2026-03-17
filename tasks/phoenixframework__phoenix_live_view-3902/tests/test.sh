#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix_live_view"
cp "/tests/phoenix_live_view/engine_test.exs" "test/phoenix_live_view/engine_test.exs"

# Compile the Elixir project to pick up changes
mix compile

# Run the specific test file for this PR
mix test test/phoenix_live_view/engine_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
