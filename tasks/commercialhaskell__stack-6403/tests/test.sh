#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/unit/Stack"
cp "/tests/unit/Stack/PackageDumpSpec.hs" "tests/unit/Stack/PackageDumpSpec.hs"

# Rebuild to pick up the copied test file changes
stack build --test --no-run-tests --fast

# Run the test suite
# The test suite will include Stack.PackageDumpSpec tests since we copied the updated file
stack test --fast
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
