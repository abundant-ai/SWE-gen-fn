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
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for db-pool-max-idletime (#2786)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has db-pool-max-idletime entry..."
if grep -q "db-pool-max-idletime" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has db-pool-max-idletime entry"
else
    echo "✗ CHANGELOG.md missing db-pool-max-idletime entry - fix not applied"
    test_status=1
fi

# Check Config.hs has the db-pool-max-idletime configuration field
echo "Checking src/PostgREST/Config.hs has configDbPoolMaxIdletime field..."
if grep -q "configDbPoolMaxIdletime" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configDbPoolMaxIdletime field"
else
    echo "✗ src/PostgREST/Config.hs missing configDbPoolMaxIdletime field - fix not applied"
    test_status=1
fi

# Check AppState.hs passes the idle time parameter to pool
echo "Checking src/PostgREST/AppState.hs passes configDbPoolMaxIdletime to pool..."
if grep -q "configDbPoolMaxIdletime" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs passes configDbPoolMaxIdletime to pool"
else
    echo "✗ src/PostgREST/AppState.hs not passing configDbPoolMaxIdletime - fix not applied"
    test_status=1
fi

# Check CLI.hs has the example config entry
echo "Checking src/PostgREST/CLI.hs has db-pool-max-idletime in example config..."
if grep -q "db-pool-max-idletime" "src/PostgREST/CLI.hs"; then
    echo "✓ src/PostgREST/CLI.hs has db-pool-max-idletime in example config"
else
    echo "✗ src/PostgREST/CLI.hs missing db-pool-max-idletime - fix not applied"
    test_status=1
fi

# Check that hasql-pool version was updated to 0.10
echo "Checking postgrest.cabal has hasql-pool >= 0.10..."
if grep -q "hasql-pool.*>=.*0\.10" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has hasql-pool >= 0.10"
else
    echo "✗ postgrest.cabal not updated to hasql-pool 0.10 - fix not applied"
    test_status=1
fi

# Verify the test config files contain db-pool-max-idletime
echo "Checking test/io/configs/expected/*.config files have db-pool-max-idletime..."
config_file_count=0
for config_file in test/io/configs/expected/*.config; do
    if [ -f "$config_file" ]; then
        if grep -q "db-pool-max-idletime" "$config_file"; then
            echo "✓ $config_file has db-pool-max-idletime"
            config_file_count=$((config_file_count + 1))
        fi
    fi
done

if [ $config_file_count -ge 5 ]; then
    echo "✓ Test config files updated with db-pool-max-idletime"
else
    echo "✗ Test config files not properly updated - fix not applied"
    test_status=1
fi

# Check test/spec/Main.hs uses 4-argument P.acquire
echo "Checking test/spec/Main.hs uses 4-argument P.acquire..."
if grep -q "P\.acquire.*60.*60" "test/spec/Main.hs"; then
    echo "✓ test/spec/Main.hs uses 4-argument P.acquire with idletime"
else
    echo "✗ test/spec/Main.hs not using 4-argument P.acquire - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs has configDbPoolMaxIdletime
echo "Checking test/spec/SpecHelper.hs has configDbPoolMaxIdletime..."
if grep -q "configDbPoolMaxIdletime" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs has configDbPoolMaxIdletime"
else
    echo "✗ test/spec/SpecHelper.hs missing configDbPoolMaxIdletime - fix not applied"
    test_status=1
fi

# Check no-defaults-env.yaml has PGRST_DB_POOL_MAX_IDLETIME
echo "Checking test/io/configs/no-defaults-env.yaml has PGRST_DB_POOL_MAX_IDLETIME..."
if grep -q "PGRST_DB_POOL_MAX_IDLETIME" "test/io/configs/no-defaults-env.yaml"; then
    echo "✓ test/io/configs/no-defaults-env.yaml has PGRST_DB_POOL_MAX_IDLETIME"
else
    echo "✗ test/io/configs/no-defaults-env.yaml missing PGRST_DB_POOL_MAX_IDLETIME - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
