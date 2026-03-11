#!/bin/bash

cd /app/src

export MIX_ENV=test
export PHX_CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "assets/test"
cp "/tests/assets/test/socket_http_test.js" "assets/test/socket_http_test.js"
mkdir -p "assets/test"
cp "/tests/assets/test/socket_test.js" "assets/test/socket_test.js"

# Run the specific JavaScript test files for this PR using Jest
npx jest assets/test/socket_http_test.js assets/test/socket_test.js --coverage=false
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
