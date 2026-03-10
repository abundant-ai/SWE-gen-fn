#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs"
cp "/tests/io/configs/aliases.config" "test/io/configs/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"

test_status=0

echo "Verifying fix for db-pool-timeout alias (#2795)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has db-pool-timeout alias entry..."
if grep -q "alias.*db-pool-timeout" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has db-pool-timeout alias entry"
else
    echo "✗ CHANGELOG.md missing db-pool-timeout alias entry - fix not applied"
    test_status=1
fi

# Check Config.hs has the db-pool-timeout alias
echo "Checking src/PostgREST/Config.hs has db-pool-timeout alias..."
if grep -q '"db-pool-timeout"' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has db-pool-timeout alias"
else
    echo "✗ src/PostgREST/Config.hs missing db-pool-timeout alias - fix not applied"
    test_status=1
fi

# Check that test files are present (these were copied from /tests)
echo "Checking test files are present..."
if [ -f "test/io/configs/aliases.config" ]; then
    echo "✓ test/io/configs/aliases.config is present"
else
    echo "✗ test/io/configs/aliases.config missing"
    test_status=1
fi

if [ -f "test/io/configs/expected/aliases.config" ]; then
    echo "✓ test/io/configs/expected/aliases.config is present"
else
    echo "✗ test/io/configs/expected/aliases.config missing"
    test_status=1
fi

# Verify the input config file contains db-pool-timeout
echo "Checking test/io/configs/aliases.config contains db-pool-timeout..."
if grep -q 'db-pool-timeout' "test/io/configs/aliases.config"; then
    echo "✓ Input config file has db-pool-timeout setting"
else
    echo "✗ Input config file missing db-pool-timeout - test data incorrect"
    test_status=1
fi

# Verify the expected config file contains db-pool-max-idletime
echo "Checking test/io/configs/expected/aliases.config contains db-pool-max-idletime..."
if grep -q 'db-pool-max-idletime' "test/io/configs/expected/aliases.config"; then
    echo "✓ Expected config file has db-pool-max-idletime setting"
else
    echo "✗ Expected config file missing db-pool-max-idletime - test data incorrect"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
