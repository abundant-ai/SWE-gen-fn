#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/e2e/support/issues"
cp "/tests/e2e/support/issues/issue_4147.ex" "test/e2e/support/issues/issue_4147.ex"
mkdir -p "test/e2e"
cp "/tests/e2e/test_helper.exs" "test/e2e/test_helper.exs"
mkdir -p "test/e2e/tests/issues"
cp "/tests/e2e/tests/issues/4147.spec.js" "test/e2e/tests/issues/4147.spec.js"

# Rebuild TypeScript and assets in case fix.patch modified source files
npm run build && MIX_ENV=dev mix assets.build

# Compile the Elixir project in e2e mode to pick up changes
MIX_ENV=e2e mix compile

# Run e2e tests for this specific issue (Playwright will start the server)
# Use --project chromium to only run on one browser
cd test/e2e && npx playwright test tests/issues/4147.spec.js --project chromium
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
