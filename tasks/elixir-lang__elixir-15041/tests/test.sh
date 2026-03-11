#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export ELIXIR_ASSERT_TIMEOUT=2000
export ELIXIRC_OPTS=""
export LANG=C.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "lib/elixir/test/elixir"
cp "/tests/lib/elixir/test/elixir/application_test.exs" "lib/elixir/test/elixir/application_test.exs"
mkdir -p "lib/elixir/test/elixir/calendar"
cp "/tests/lib/elixir/test/elixir/calendar/iso_test.exs" "lib/elixir/test/elixir/calendar/iso_test.exs"
mkdir -p "lib/elixir/test/elixir/module/types"
cp "/tests/lib/elixir/test/elixir/module/types/descr_test.exs" "lib/elixir/test/elixir/module/types/descr_test.exs"
mkdir -p "lib/elixir/test/elixir/module/types"
cp "/tests/lib/elixir/test/elixir/module/types/pattern_test.exs" "lib/elixir/test/elixir/module/types/pattern_test.exs"

# Rebuild Elixir to pick up any changes made by the Oracle agent
# Use normal compile (with type inference) since the fix should make it work
# If this fails, we're still in buggy state and tests should fail
make clean && make compile 2>/dev/null || echo "Compilation failed or still in buggy state"

# Start epmd (Erlang Port Mapper Daemon) in background
epmd -daemon || true

# Run only the specific test files from this PR
# Tests are in lib/elixir/test/elixir/: application_test.exs, calendar/iso_test.exs,
# module/types/descr_test.exs, and module/types/pattern_test.exs
cd lib/elixir && ../../bin/elixir --sname primary -r "test/elixir/test_helper.exs" -pr "test/elixir/application_test.exs" -pr "test/elixir/calendar/iso_test.exs" -pr "test/elixir/module/types/descr_test.exs" -pr "test/elixir/module/types/pattern_test.exs"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
