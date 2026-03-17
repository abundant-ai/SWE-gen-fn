#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy support files needed for tests
mkdir -p "/app/src/test/support"
cp "/tests/support/http_client.exs" "/app/src/test/support/http_client.exs"
cp "/tests/support/websocket_client.exs" "/app/src/test/support/websocket_client.exs"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/test/phoenix/integration"
cp "/tests/phoenix/integration/websocket_socket_test.exs" "/app/src/test/phoenix/integration/websocket_socket_test.exs"

# Run the specific test file for PR #5621
cd /app/src
mix test test/phoenix/integration/websocket_socket_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
