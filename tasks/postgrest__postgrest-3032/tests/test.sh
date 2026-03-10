#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

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
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Check CHANGELOG for the fix mention (removing db-use-legacy-gucs)
echo "Checking CHANGELOG for db-use-legacy-gucs removal..."
if grep -q 'Removed \[db-use-legacy-gucs\]' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions db-use-legacy-gucs removal"
else
    echo "✗ CHANGELOG missing db-use-legacy-gucs removal entry - fix not applied"
    test_status=1
fi

# Check that db-use-legacy-gucs is removed from CLI.hs
echo "Checking CLI.hs for db-use-legacy-gucs removal..."
if ! grep -q 'db-use-legacy-gucs' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs removed db-use-legacy-gucs"
else
    echo "✗ CLI.hs still has db-use-legacy-gucs - fix not applied"
    test_status=1
fi

# Check that configDbUseLegacyGucs is removed from Config.hs
echo "Checking Config.hs for configDbUseLegacyGucs removal..."
if ! grep -q 'configDbUseLegacyGucs' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs removed configDbUseLegacyGucs"
else
    echo "✗ Config.hs still has configDbUseLegacyGucs - fix not applied"
    test_status=1
fi

# Check that db_use_legacy_gucs is removed from Config/Database.hs
echo "Checking Config/Database.hs for db_use_legacy_gucs removal..."
if ! grep -q 'db_use_legacy_gucs' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs removed db_use_legacy_gucs"
else
    echo "✗ Config/Database.hs still has db_use_legacy_gucs - fix not applied"
    test_status=1
fi

# Check that expected config files don't have db-use-legacy-gucs
echo "Checking config files for db-use-legacy-gucs removal..."
if ! grep -r 'db-use-legacy-gucs' test/io/configs/expected/; then
    echo "✓ Config files removed db-use-legacy-gucs"
else
    echo "✗ Config files still have db-use-legacy-gucs - fix not applied"
    test_status=1
fi

# Check that Query.hs setPgLocals signature has been updated (no longer passes pgVer)
echo "Checking Query.hs for setPgLocals signature..."
if ! grep -q 'setPgLocals.*pgVer' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs setPgLocals signature updated"
else
    echo "✗ Query.hs setPgLocals still has pgVer parameter - fix not applied"
    test_status=1
fi

# Check that App.hs no longer passes pgVer to setPgLocals
echo "Checking App.hs for setPgLocals call..."
if ! grep -q 'Query.setPgLocals.*pgVer' "src/PostgREST/App.hs"; then
    echo "✓ App.hs no longer passes pgVer to setPgLocals"
else
    echo "✗ App.hs still passes pgVer to setPgLocals - fix not applied"
    test_status=1
fi

# Check that LegacyGucsSpec test is removed from postgrest.cabal
echo "Checking postgrest.cabal for LegacyGucsSpec removal..."
if ! grep -q 'Feature.LegacyGucsSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal removed Feature.LegacyGucsSpec"
else
    echo "✗ postgrest.cabal still has Feature.LegacyGucsSpec - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
