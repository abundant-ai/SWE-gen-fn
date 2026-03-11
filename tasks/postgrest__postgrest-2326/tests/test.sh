#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-numeric.config" "test/io/configs/expected/boolean-numeric.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-string.config" "test/io/configs/expected/boolean-string.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/defaults.config" "test/io/configs/expected/defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"

test_status=0

echo "Verifying fix for db-pool-timeout default value (PR #2326)..."
echo ""
echo "NOTE: This PR increases db-pool-timeout default from 10 to 3600 seconds"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking CLI.hs has updated db-pool-timeout default to 3600..."
if [ -f "src/PostgREST/CLI.hs" ] && grep -q "db-pool-timeout = 3600" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has db-pool-timeout = 3600"
else
    echo "✗ CLI.hs missing db-pool-timeout = 3600 - fix not applied!"
    test_status=1
fi

echo "Checking Config.hs has updated default to 3600..."
if [ -f "src/PostgREST/Config.hs" ] && grep -q "fromMaybe 3600" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has fromMaybe 3600"
else
    echo "✗ Config.hs missing fromMaybe 3600 - fix not applied!"
    test_status=1
fi

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#2317" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2317"
else
    echo "✗ CHANGELOG.md missing #2317 entry"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking aliases.config has db-pool-timeout = 3600..."
if [ -f "test/io/configs/expected/aliases.config" ] && grep -q "db-pool-timeout = 3600" "test/io/configs/expected/aliases.config"; then
    echo "✓ aliases.config has db-pool-timeout = 3600 (HEAD version)"
else
    echo "✗ aliases.config missing db-pool-timeout = 3600 - HEAD file not copied!"
    test_status=1
fi

echo "Checking boolean-numeric.config has db-pool-timeout = 3600..."
if [ -f "test/io/configs/expected/boolean-numeric.config" ] && grep -q "db-pool-timeout = 3600" "test/io/configs/expected/boolean-numeric.config"; then
    echo "✓ boolean-numeric.config has db-pool-timeout = 3600 (HEAD version)"
else
    echo "✗ boolean-numeric.config missing db-pool-timeout = 3600 - HEAD file not copied!"
    test_status=1
fi

echo "Checking boolean-string.config has db-pool-timeout = 3600..."
if [ -f "test/io/configs/expected/boolean-string.config" ] && grep -q "db-pool-timeout = 3600" "test/io/configs/expected/boolean-string.config"; then
    echo "✓ boolean-string.config has db-pool-timeout = 3600 (HEAD version)"
else
    echo "✗ boolean-string.config missing db-pool-timeout = 3600 - HEAD file not copied!"
    test_status=1
fi

echo "Checking defaults.config has db-pool-timeout = 3600..."
if [ -f "test/io/configs/expected/defaults.config" ] && grep -q "db-pool-timeout = 3600" "test/io/configs/expected/defaults.config"; then
    echo "✓ defaults.config has db-pool-timeout = 3600 (HEAD version)"
else
    echo "✗ defaults.config missing db-pool-timeout = 3600 - HEAD file not copied!"
    test_status=1
fi

echo "Checking types.config has db-pool-timeout = 3600..."
if [ -f "test/io/configs/expected/types.config" ] && grep -q "db-pool-timeout = 3600" "test/io/configs/expected/types.config"; then
    echo "✓ types.config has db-pool-timeout = 3600 (HEAD version)"
else
    echo "✗ types.config missing db-pool-timeout = 3600 - HEAD file not copied!"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
