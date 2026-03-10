#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test"
cp "/tests/hledger/test/close.test" "hledger/test/close.test"
mkdir -p "hledger/test/journal"
cp "/tests/hledger/test/journal/account-types.test" "hledger/test/journal/account-types.test"
mkdir -p "hledger/test"
cp "/tests/hledger/test/query-type.test" "hledger/test/query-type.test"

# Run the specific test files with shelltestrunner
shelltest --execdir hledger/test/close.test hledger/test/journal/account-types.test hledger/test/query-type.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
