#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Hadolint"
cp "/tests/Hadolint/PragmaSpec.hs" "test/Hadolint/PragmaSpec.hs"

# Rebuild to incorporate the updated test files
cabal build all -j$(nproc) 2>&1 | tail -20
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "Build failed after copying test files"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Find and run the test binary directly with Pragma filter
TEST_BIN=$(find dist-newstyle -name hadolint-unit-tests -type f -executable | head -1)
if [ -z "$TEST_BIN" ]; then
  echo "Test binary not found!"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

$TEST_BIN --match "Pragma"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
