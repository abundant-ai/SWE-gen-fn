#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix_live_view/integrations"
cp "/tests/phoenix_live_view/integrations/hooks_test.exs" "test/phoenix_live_view/integrations/hooks_test.exs"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/lifecycle.ex" "test/support/live_views/lifecycle.ex"

# Run mix test for the specific test file from the PR
mix test test/phoenix_live_view/integrations/hooks_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
