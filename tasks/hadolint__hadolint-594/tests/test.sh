#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Spec.hs" "test/Spec.hs"

# Rebuild and run tests with Stack
# Stack will rebuild only what's necessary and run the test suite
stack test --fast -j$(nproc)
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
