#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Set environment variable for test mode
export MIX_ENV=test

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix_live_view"
cp "/tests/phoenix_live_view/html_engine_test.exs" "test/phoenix_live_view/html_engine_test.exs"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/debug_anno_opt_out.exs" "test/support/live_views/debug_anno_opt_out.exs"
mkdir -p "test"
cp "/tests/test_helper.exs" "test/test_helper.exs"

# Run the specific test files using mix test
mix test test/phoenix_live_view/html_engine_test.exs test/support/live_views/debug_anno_opt_out.exs test/test_helper.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
