#!/bin/bash

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "/app/src/assets/test"
cp "/tests/assets/test/socket_test.js" "/app/src/assets/test/socket_test.js"

# Run the specific test file for PR #5688
cd /app/src/assets
npm test -- test/socket_test.js
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
