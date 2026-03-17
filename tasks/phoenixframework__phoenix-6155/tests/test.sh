#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/installer/test"
cp "/tests/installer/test/phx_new_test.exs" "/app/src/installer/test/phx_new_test.exs"
mkdir -p "/app/src/test/mix/tasks"
cp "/tests/mix/tasks/phx.gen.live_test.exs" "/app/src/test/mix/tasks/phx.gen.live_test.exs"

# Run installer test from installer directory (it has its own mix.exs)
cd /app/src/installer
mix test test/phx_new_test.exs
installer_status=$?

# Run main project test from main directory
cd /app/src
mix test test/mix/tasks/phx.gen.live_test.exs
main_status=$?

# Both tests must pass
if [ $installer_status -eq 0 ] && [ $main_status -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
