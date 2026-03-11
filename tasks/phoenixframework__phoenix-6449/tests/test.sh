#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "installer/test"
cp "/tests/installer/test/phx_new_test.exs" "installer/test/phx_new_test.exs"

# Run the specific test file from the installer directory
cd installer
mix test test/phx_new_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
