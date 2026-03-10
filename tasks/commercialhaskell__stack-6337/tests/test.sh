#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/integration/tests/3685-config-yaml-for-allow-newer"
cp "/tests/integration/tests/3685-config-yaml-for-allow-newer/Main.hs" "tests/integration/tests/3685-config-yaml-for-allow-newer/Main.hs"
mkdir -p "tests/unit/Stack/Ghci"
cp "/tests/unit/Stack/Ghci/ScriptSpec.hs" "tests/unit/Stack/Ghci/ScriptSpec.hs"
mkdir -p "tests/unit/Stack"
cp "/tests/unit/Stack/GhciSpec.hs" "tests/unit/Stack/GhciSpec.hs"

# Rebuild to pick up the copied test file changes
stack build --test --no-run-tests --fast --flag stack:integration-tests

# Run the test suite including integration tests
# The test suite will include the updated tests since we copied the updated files
stack test --fast --flag stack:integration-tests
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
