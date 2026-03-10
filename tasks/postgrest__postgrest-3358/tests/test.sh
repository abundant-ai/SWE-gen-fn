#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml"
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
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md does NOT have entry for #3061 (it should be removed in fix)
echo "Checking that CHANGELOG.md does NOT have entry for #3061..."
if grep -q "#3061, Apply all function settings as transaction-scoped settings" "CHANGELOG.md"; then
    echo "✗ CHANGELOG.md still has entry for #3061 - fix not applied"
    test_status=1
else
    echo "✓ CHANGELOG.md does not have entry for #3061 (correctly removed)"
fi

# Check that CHANGELOG.md HAS the entry for #3242 (it should be present in fix)
echo "Checking that CHANGELOG.md has entry for #3242..."
if grep -q "#3242. Add config \`db-hoisted-tx-settings\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3242"
else
    echo "✗ CHANGELOG.md missing entry for #3242 - fix not applied"
    test_status=1
fi

# Check that docs/references/configuration.rst HAS db-hoisted-tx-settings section
echo "Checking that docs/references/configuration.rst has db-hoisted-tx-settings..."
if grep -q "db-hoisted-tx-settings" "docs/references/configuration.rst"; then
    echo "✓ docs/references/configuration.rst has db-hoisted-tx-settings"
else
    echo "✗ docs/references/configuration.rst missing db-hoisted-tx-settings - fix not applied"
    test_status=1
fi

# Check that docs/references/transactions.rst has the correct note (references db-hoisted-tx-settings)
echo "Checking that docs/references/transactions.rst has correct note..."
if grep -q "Only the transactions that are hoisted by config :ref:\`db-hoisted-tx-settings\`" "docs/references/transactions.rst"; then
    echo "✓ docs/references/transactions.rst has correct note"
else
    echo "✗ docs/references/transactions.rst has incorrect note - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Config.hs HAS configDbHoistedTxSettings
echo "Checking that src/PostgREST/Config.hs has configDbHoistedTxSettings..."
if grep -q "configDbHoistedTxSettings" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configDbHoistedTxSettings"
else
    echo "✗ src/PostgREST/Config.hs missing configDbHoistedTxSettings - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Config/Database.hs HAS db_hoisted_tx_settings
echo "Checking that src/PostgREST/Config/Database.hs has db_hoisted_tx_settings..."
if grep -q "db_hoisted_tx_settings" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has db_hoisted_tx_settings"
else
    echo "✗ src/PostgREST/Config/Database.hs missing db_hoisted_tx_settings - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/SchemaCache.hs has correct function signature (with hoisted settings parameter)
echo "Checking that src/PostgREST/SchemaCache.hs has correct allFunctions signature..."
if grep -q "allFunctions :: PgVersion -> Bool -> SQL.Statement (\\[Schema\\], \\[Text\\]) RoutineMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has correct allFunctions signature"
else
    echo "✗ src/PostgREST/SchemaCache.hs has incorrect allFunctions signature - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/SchemaCache.hs has correct accessibleFuncs signature
echo "Checking that src/PostgREST/SchemaCache.hs has correct accessibleFuncs signature..."
if grep -q "accessibleFuncs :: PgVersion -> Bool -> SQL.Statement (Schema, \\[Text\\]) RoutineMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has correct accessibleFuncs signature"
else
    echo "✗ src/PostgREST/SchemaCache.hs has incorrect accessibleFuncs signature - fix not applied"
    test_status=1
fi

# Check that test/io/configs/expected/defaults.config HAS db-hoisted-tx-settings line
echo "Checking that test/io/configs/expected/defaults.config has db-hoisted-tx-settings..."
if grep -q "db-hoisted-tx-settings" "test/io/configs/expected/defaults.config"; then
    echo "✓ test/io/configs/expected/defaults.config has db-hoisted-tx-settings"
else
    echo "✗ test/io/configs/expected/defaults.config missing db-hoisted-tx-settings - fix not applied"
    test_status=1
fi

# Check that test/spec/SpecHelper.hs HAS configDbHoistedTxSettings
echo "Checking that test/spec/SpecHelper.hs has configDbHoistedTxSettings..."
if grep -q "configDbHoistedTxSettings" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs has configDbHoistedTxSettings"
else
    echo "✗ test/spec/SpecHelper.hs missing configDbHoistedTxSettings - fix not applied"
    test_status=1
fi

# Check that test/io/test_io.py has OLD function names (rpc_work_mem, etc.)
echo "Checking that test/io/test_io.py has rpc_work_mem function call..."
if grep -q "/rpc/rpc_work_mem" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has rpc_work_mem function call"
else
    echo "✗ test/io/test_io.py missing rpc_work_mem function call - fix not applied"
    test_status=1
fi

# Check that test/io/test_io.py has rpc_with_two_hoisted function call
echo "Checking that test/io/test_io.py has rpc_with_two_hoisted function call..."
if grep -q "/rpc/rpc_with_two_hoisted" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has rpc_with_two_hoisted function call"
else
    echo "✗ test/io/test_io.py missing rpc_with_two_hoisted function call - fix not applied"
    test_status=1
fi

# Check that test/io/fixtures.sql has rpc_work_mem function
echo "Checking that test/io/fixtures.sql has rpc_work_mem function..."
if grep -q "create or replace function rpc_work_mem()" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has rpc_work_mem function"
else
    echo "✗ test/io/fixtures.sql missing rpc_work_mem function - fix not applied"
    test_status=1
fi

# Check that test/io/fixtures.sql has rpc_with_two_hoisted function
echo "Checking that test/io/fixtures.sql has rpc_with_two_hoisted function..."
if grep -q "create or replace function rpc_with_two_hoisted()" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has rpc_with_two_hoisted function"
else
    echo "✗ test/io/fixtures.sql missing rpc_with_two_hoisted function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
