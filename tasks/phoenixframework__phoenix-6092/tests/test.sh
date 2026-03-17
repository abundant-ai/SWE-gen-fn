#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/test/phoenix/integration"
cp "/tests/phoenix/integration/long_poll_channels_test.exs" "/app/src/test/phoenix/integration/long_poll_channels_test.exs"
cp "/tests/phoenix/integration/long_poll_socket_test.exs" "/app/src/test/phoenix/integration/long_poll_socket_test.exs"
cp "/tests/phoenix/integration/websocket_channels_test.exs" "/app/src/test/phoenix/integration/websocket_channels_test.exs"
cp "/tests/phoenix/integration/websocket_socket_test.exs" "/app/src/test/phoenix/integration/websocket_socket_test.exs"

# Run the specific test files for PR #6092
cd /app/src
mix test test/phoenix/integration/long_poll_channels_test.exs test/phoenix/integration/long_poll_socket_test.exs test/phoenix/integration/websocket_channels_test.exs test/phoenix/integration/websocket_socket_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
