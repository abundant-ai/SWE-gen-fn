#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/e2e/support/issues"
cp "/tests/e2e/support/issues/issue_4078.ex" "test/e2e/support/issues/issue_4078.ex"
mkdir -p "test/e2e"
cp "/tests/e2e/test_helper.exs" "test/e2e/test_helper.exs"
mkdir -p "test/e2e/tests/issues"
cp "/tests/e2e/tests/issues/4078.spec.js" "test/e2e/tests/issues/4078.spec.js"
mkdir -p "test/phoenix_component"
cp "/tests/phoenix_component/components_test.exs" "test/phoenix_component/components_test.exs"

# Clean and rebuild assets with dev env (esbuild config only exists in dev)
rm -rf priv/static/*
MIX_ENV=dev mix assets.build

# Now compile Elixir code for e2e tests
export MIX_ENV=e2e
mix compile --force

# Run the Elixir unit test first
mix test test/phoenix_component/components_test.exs
unit_test_status=$?

if [ $unit_test_status -ne 0 ]; then
  echo 0 > /logs/verifier/reward.txt
  exit $unit_test_status
fi

# Run Playwright e2e test for the specific test file from the e2e directory
cd test/e2e
npx playwright test tests/issues/4078.spec.js --project chromium
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
