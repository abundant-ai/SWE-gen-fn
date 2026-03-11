#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "installer/test"
cp "/tests/installer/test/phx_new_test.exs" "installer/test/phx_new_test.exs"
mkdir -p "installer/test"
cp "/tests/installer/test/phx_new_umbrella_test.exs" "installer/test/phx_new_umbrella_test.exs"

# Run the specific Elixir test files for this PR from the installer directory
cd /app/src/installer
mix test test/phx_new_test.exs test/phx_new_umbrella_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
