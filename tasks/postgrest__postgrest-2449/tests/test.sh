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
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for db-pool-acquisition-timeout config option (PR #2449)..."
echo ""
echo "NOTE: This PR adds the db-pool-acquisition-timeout configuration option"
echo "BASE (buggy) does NOT have this configuration option"
echo "HEAD (fixed) DOES have the db-pool-acquisition-timeout configuration option"
echo ""

# Check CHANGELOG - HEAD should mention #2348 and db-pool-acquisition-timeout
echo "Checking CHANGELOG.md mentions PR #2348 and db-pool-acquisition-timeout..."
if grep -q "#2348" "CHANGELOG.md" && grep -q "db-pool-acquisition-timeout" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PR #2348 and db-pool-acquisition-timeout"
else
    echo "✗ CHANGELOG.md does not mention PR #2348 or db-pool-acquisition-timeout - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should use configDbPoolAcquisitionTimeout
echo "Checking src/PostgREST/AppState.hs uses configDbPoolAcquisitionTimeout..."
if grep -q "configDbPoolAcquisitionTimeout" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses configDbPoolAcquisitionTimeout"
else
    echo "✗ AppState.hs does not use configDbPoolAcquisitionTimeout - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should have timeout calculation logic
echo "Checking src/PostgREST/AppState.hs has timeout calculation..."
if grep -q "timeoutMilliseconds" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has timeout calculation logic"
else
    echo "✗ AppState.hs does not have timeout calculation - fix not applied"
    test_status=1
fi

# Check CLI.hs - HEAD should have db-pool-acquisition-timeout in example config
echo "Checking src/PostgREST/CLI.hs includes db-pool-acquisition-timeout in example..."
if grep -q "db-pool-acquisition-timeout" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs includes db-pool-acquisition-timeout in example config"
else
    echo "✗ CLI.hs does not include db-pool-acquisition-timeout - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should have configDbPoolAcquisitionTimeout field
echo "Checking src/PostgREST/Config.hs has configDbPoolAcquisitionTimeout field..."
if grep -q "configDbPoolAcquisitionTimeout" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configDbPoolAcquisitionTimeout field"
else
    echo "✗ Config.hs does not have configDbPoolAcquisitionTimeout field - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should parse db-pool-acquisition-timeout option
echo "Checking src/PostgREST/Config.hs parses db-pool-acquisition-timeout..."
if grep -q '"db-pool-acquisition-timeout"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs parses db-pool-acquisition-timeout option"
else
    echo "✗ Config.hs does not parse db-pool-acquisition-timeout - fix not applied"
    test_status=1
fi

# Check test config files - HEAD should have db-pool-acquisition-timeout
echo "Checking test/io/configs/expected/aliases.config has db-pool-acquisition-timeout..."
if grep -q "db-pool-acquisition-timeout" "test/io/configs/expected/aliases.config"; then
    echo "✓ aliases.config has db-pool-acquisition-timeout"
else
    echo "✗ aliases.config does not have db-pool-acquisition-timeout - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should use timeout in pool acquisition
echo "Checking test/spec/SpecHelper.hs uses timeout in pool setup..."
if grep -q "Nothing" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs references timeout parameter (Nothing placeholder)"
else
    echo "⚠ SpecHelper.hs timeout check skipped (may not be modified in this PR)"
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - db-pool-acquisition-timeout configuration option added successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
