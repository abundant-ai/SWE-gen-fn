#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test/cli"
cp "/tests/hledger/test/cli/date-options.test" "hledger/test/cli/date-options.test"
mkdir -p "hledger/test/register"
cp "/tests/hledger/test/register/intervals.test" "hledger/test/register/intervals.test"

# Run the specific test files with shelltestrunner
shelltest --execdir hledger/test/cli/date-options.test hledger/test/register/intervals.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
