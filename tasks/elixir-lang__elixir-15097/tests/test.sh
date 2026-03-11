#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export ELIXIR_ASSERT_TIMEOUT=2000
export ELIXIRC_OPTS=""
export LANG=C.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "lib/mix/test/fixtures/escript_test/lib"
cp "/tests/lib/mix/test/fixtures/escript_test/lib/escript_test.ex" "lib/mix/test/fixtures/escript_test/lib/escript_test.ex"
mkdir -p "lib/mix/test/mix/tasks"
cp "/tests/lib/mix/test/mix/tasks/escript_test.exs" "lib/mix/test/mix/tasks/escript_test.exs"

# Rebuild Elixir to pick up any changes made by the Oracle agent
# Use normal compile (with type inference) since the fix should make it work
# If this fails, we're still in buggy state and tests should fail
make clean && make compile 2>/dev/null || echo "Compilation failed or still in buggy state"

# Start epmd (Erlang Port Mapper Daemon) in background
epmd -daemon || true

# Run only the specific test files from this PR
cd lib/mix && ../../bin/elixir --sname primary -r "test/test_helper.exs" -pr "test/mix/tasks/escript_test.exs"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
