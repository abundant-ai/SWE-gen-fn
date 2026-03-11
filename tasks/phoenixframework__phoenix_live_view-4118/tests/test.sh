#!/bin/bash

cd /app/src

# Source asdf to get Elixir/Erlang in PATH
. /opt/asdf/asdf.sh

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/e2e/support"
cp "/tests/e2e/support/form_live.ex" "test/e2e/support/form_live.ex"
mkdir -p "test/e2e/tests"
cp "/tests/e2e/tests/forms.spec.js" "test/e2e/tests/forms.spec.js"

# Clean and rebuild assets with dev env (esbuild config only exists in dev)
rm -rf priv/static/*
MIX_ENV=dev mix assets.build

# Now compile Elixir code for e2e tests
export MIX_ENV=e2e
mix compile --force

# Run Playwright tests for the specific test file from the e2e directory
cd test/e2e
npx playwright test tests/forms.spec.js --project chromium
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
