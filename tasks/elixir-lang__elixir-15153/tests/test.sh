#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export ELIXIR_ASSERT_TIMEOUT=2000
export ELIXIRC_OPTS="--warnings-as-errors"
export LANG=C.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "lib/elixir/test/elixir/module/types"
cp "/tests/lib/elixir/test/elixir/module/types/expr_test.exs" "lib/elixir/test/elixir/module/types/expr_test.exs"
mkdir -p "lib/elixir/test/elixir/module/types"
cp "/tests/lib/elixir/test/elixir/module/types/pattern_test.exs" "lib/elixir/test/elixir/module/types/pattern_test.exs"

# Start epmd (Erlang Port Mapper Daemon) in background
epmd -daemon || true

# Run only the specific test files using Elixir's test runner
cd lib/elixir && ../../bin/elixir --sname primary -r "test/elixir/test_helper.exs" -pr "test/elixir/module/types/expr_test.exs" "test/elixir/module/types/pattern_test.exs"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
