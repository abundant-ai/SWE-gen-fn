#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/DL4006.hs" "test/DL4006.hs"
mkdir -p "test"
cp "/tests/Shellcheck.hs" "test/Shellcheck.hs"

# Rebuild to incorporate the updated test files
cabal build all -j$(nproc) 2>&1 | tail -20
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "Build failed after copying test files"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Find and run the test binary
TEST_BIN=$(find dist-newstyle -name hadolint-unit-tests -type f -executable | head -1)
if [ -z "$TEST_BIN" ]; then
  echo "Test binary not found!"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run only the specific test files for this PR (DL4006 and Shellcheck)
# Need to run them separately since hspec --match doesn't support OR operators properly
($TEST_BIN --match "/DL4006/" && $TEST_BIN --match "/Shellcheck/")
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
