#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test/print"
cp "/tests/hledger/test/print/beancount.test" "hledger/test/print/beancount.test"

# Run the specific test file with shelltestrunner
shelltest --execdir hledger/test/print/beancount.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
