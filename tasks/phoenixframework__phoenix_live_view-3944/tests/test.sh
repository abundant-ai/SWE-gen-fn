#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "lib/phoenix_live_view/test"
cp "/tests/lib/phoenix_live_view/test/live_view_test.ex" "lib/phoenix_live_view/test/live_view_test.ex"
mkdir -p "test/phoenix_live_view"
cp "/tests/phoenix_live_view/async_test.exs" "test/phoenix_live_view/async_test.exs"
mkdir -p "test/phoenix_live_view/integrations"
cp "/tests/phoenix_live_view/integrations/stream_async_test.exs" "test/phoenix_live_view/integrations/stream_async_test.exs"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/assign_async.ex" "test/support/live_views/assign_async.ex"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/general.ex" "test/support/live_views/general.ex"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/start_async.ex" "test/support/live_views/start_async.ex"
mkdir -p "test/support/live_views"
cp "/tests/support/live_views/stream_async.ex" "test/support/live_views/stream_async.ex"
mkdir -p "test/support"
cp "/tests/support/router.ex" "test/support/router.ex"

# Run tests in test environment (not e2e) to avoid compiling E2E support files
MIX_ENV=test mix test test/phoenix_live_view/async_test.exs test/phoenix_live_view/integrations/stream_async_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
