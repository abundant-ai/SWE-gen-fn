#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export ELIXIR_ASSERT_TIMEOUT=2000
export ELIXIRC_OPTS=""
export LANG=C.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "lib/elixir/test/elixir"
cp "/tests/lib/elixir/test/elixir/inspect_test.exs" "lib/elixir/test/elixir/inspect_test.exs"
mkdir -p "lib/elixir/test/elixir"
cp "/tests/lib/elixir/test/elixir/regex_test.exs" "lib/elixir/test/elixir/regex_test.exs"
mkdir -p "lib/mix/test/mix/tasks"
cp "/tests/lib/mix/test/mix/tasks/compile.app_test.exs" "lib/mix/test/mix/tasks/compile.app_test.exs"
mkdir -p "lib/mix/test"
cp "/tests/lib/mix/test/test_helper.exs" "lib/mix/test/test_helper.exs"

# Rebuild Elixir to pick up any changes made by the Oracle agent
# Use normal compile (with type inference) since the fix should make it work
# If this fails, we're still in buggy state and tests should fail
make clean && make compile 2>/dev/null || echo "Compilation failed or still in buggy state"

# Start epmd (Erlang Port Mapper Daemon) in background
epmd -daemon || true

# Run the specific test files from this PR
# For elixir tests: run from lib/elixir directory
cd lib/elixir && ../../bin/elixir --sname elixir_test -r "test/elixir/test_helper.exs" -pr "test/elixir/inspect_test.exs" -pr "test/elixir/regex_test.exs"
elixir_status=$?

# For mix tests: run from lib/mix directory with a different node name
cd /app/src/lib/mix && ../../bin/elixir --sname mix_test -r "test/test_helper.exs" -pr "test/mix/tasks/compile.app_test.exs"
mix_status=$?

# Combine test statuses - pass only if both succeed
if [ $elixir_status -eq 0 ] && [ $mix_status -eq 0 ]; then
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
