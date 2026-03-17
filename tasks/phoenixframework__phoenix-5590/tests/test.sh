#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "installer/test"
cp "/tests/installer/test/phx_new_test.exs" "installer/test/phx_new_test.exs"
mkdir -p "installer/test"
cp "/tests/installer/test/phx_new_umbrella_test.exs" "installer/test/phx_new_umbrella_test.exs"

# Clean up tmp directory from any previous test runs
rm -rf /app/src/tmp

# Run the specific test files for PR #5590
cd /app/src/installer
mix test --trace --max-cases 1 test/phx_new_test.exs test/phx_new_umbrella_test.exs
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
