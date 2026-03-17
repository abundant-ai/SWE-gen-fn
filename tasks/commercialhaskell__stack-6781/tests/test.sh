#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/integration/tests/3940-base-upgrade-warning"
cp "/tests/integration/tests/3940-base-upgrade-warning/Main.hs" "tests/integration/tests/3940-base-upgrade-warning/Main.hs"

# Rebuild Stack executable to pick up any code changes from fix.patch
# Use --fast to skip optimizations, making the build much faster
stack build --fast

# Set STACK_EXE to point to the locally-built stack executable
# Integration tests use this env var to know which stack to test
export STACK_EXE=$(stack exec which stack)

# Run the specific integration test
cd tests/integration
./run-single-test.sh 3940-base-upgrade-warning
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
