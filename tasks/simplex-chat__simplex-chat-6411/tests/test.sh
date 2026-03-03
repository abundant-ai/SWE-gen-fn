#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/OperatorTests.hs" "tests/OperatorTests.hs"

# Build and run the specific operator tests only
# Note: This will build dependencies on first run (which may take time)
# Using -O0 to disable optimization for faster builds
cabal test simplex-chat-test \
  --test-show-details=streaming \
  --ghc-options="-O0" \
  --test-option=--match \
  --test-option="managing server operators"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
