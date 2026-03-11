#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "assets/test"
cp "/tests/assets/test/view_test.ts" "assets/test/view_test.ts"

# Build TypeScript before running tests
npm run build

# Run Jest tests for the specific test files from the PR
npx jest \
  assets/test/view_test.ts \
  --coverage=false
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
