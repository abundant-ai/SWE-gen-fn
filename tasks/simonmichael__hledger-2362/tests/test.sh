#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test/errors"
cp "/tests/hledger/test/errors/tcclockouttime.test" "hledger/test/errors/tcclockouttime.test"
mkdir -p "hledger/test/errors"
cp "/tests/hledger/test/errors/tcorderedactions.test" "hledger/test/errors/tcorderedactions.test"
mkdir -p "hledger/test"
cp "/tests/hledger/test/timeclock.test" "hledger/test/timeclock.test"

# Run the specific test files with shelltestrunner
shelltest --execdir hledger/test/errors/tcclockouttime.test hledger/test/errors/tcorderedactions.test hledger/test/timeclock.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
