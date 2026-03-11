#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/phoenix_live_view"
cp "/tests/phoenix_live_view/colocated_js_test.exs" "test/phoenix_live_view/colocated_js_test.exs"

# Run tests in test environment (not e2e) to avoid compiling E2E support files
MIX_ENV=test mix test test/phoenix_live_view/colocated_js_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
