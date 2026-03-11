#!/bin/bash

cd /app/src

# Set environment variables for Elixir tests
export ELIXIR_ASSERT_TIMEOUT=2000
export ELIXIRC_OPTS=""
export LANG=C.UTF-8

# Copy HEAD test files from /tests (overwrites BASE state)
# These test files expect elixir_checker_v6 which will fail with buggy code (v5)
# but pass with fixed code (v6)
mkdir -p "lib/elixir/test/elixir/module/types"
cp "/tests/lib/elixir/test/elixir/module/types/integration_test.exs" "lib/elixir/test/elixir/module/types/integration_test.exs"
mkdir -p "lib/elixir/test/elixir/protocol"
cp "/tests/lib/elixir/test/elixir/protocol/consolidation_test.exs" "lib/elixir/test/elixir/protocol/consolidation_test.exs"

# Rebuild Elixir to pick up any changes made by the Oracle agent
# Use normal compile (with type inference) since the fix should make it work
# If this fails, we're still in buggy state and tests should fail
make clean && make compile 2>/dev/null || echo "Compilation failed or still in buggy state"

# Disable type inference in test_helper.exs to avoid errors if still in buggy state
sed -i 's/Code.compiler_options(debug_info: true, infer_signatures: \[:elixir\])/Code.compiler_options(debug_info: true, infer_signatures: [])/' lib/elixir/test/elixir/test_helper.exs

# Start epmd (Erlang Port Mapper Daemon) in background
epmd -daemon || true

# Run only the specific test files using Elixir's test runner
cd lib/elixir && ../../bin/elixir --sname primary -r "test/elixir/test_helper.exs" -pr "test/elixir/module/types/integration_test.exs" "test/elixir/protocol/consolidation_test.exs"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
