#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/IgnoreAclOpenApiSpec.hs" "test/Feature/IgnoreAclOpenApiSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/IgnorePrivOpenApiSpec.hs" "test/Feature/IgnorePrivOpenApiSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test"
cp "/tests/SpecHelper.hs" "test/SpecHelper.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/roles.sql" "test/fixtures/roles.sql"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/aliases.config" "test/io-tests/configs/expected/aliases.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-numeric.config" "test/io-tests/configs/expected/boolean-numeric.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-string.config" "test/io-tests/configs/expected/boolean-string.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/defaults.config" "test/io-tests/configs/expected/defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db.config" "test/io-tests/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults.config" "test/io-tests/configs/expected/no-defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/types.config" "test/io-tests/configs/expected/types.config"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults-env.yaml" "test/io-tests/configs/no-defaults-env.yaml"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults.config" "test/io-tests/configs/no-defaults.config"
mkdir -p "test/io-tests"
cp "/tests/io-tests/fixtures.yaml" "test/io-tests/fixtures.yaml"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #1882 which renames openapi-mode config values and fixes schema filtering
# HEAD state (49501f08552539b4de6db3be84c34482662f556c) = follow-privileges/ignore-privileges naming - FIXED
# BASE state (with bug.patch) = follow-acl/ignore-acl naming - BUGGY
# ORACLE state (BASE + fix.patch) = follow-privileges/ignore-privileges naming - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for openapi-mode config renaming)..."
echo ""

echo "Checking that Config.hs uses OAFollowPriv instead of OAFollowACL..."
if grep -q 'data OpenAPIMode = OAFollowPriv | OAIgnorePriv | OADisabled' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has OAFollowPriv data constructor - fix applied!"
else
    echo "✗ Config.hs missing OAFollowPriv data constructor - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs show instance uses 'follow-privileges'..."
if grep -q 'show OAFollowPriv = "follow-privileges"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs shows 'follow-privileges' - fix applied!"
else
    echo "✗ Config.hs missing 'follow-privileges' - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs parser accepts 'follow-privileges'..."
if grep -q 'Just "follow-privileges" -> pure OAFollowPriv' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs parser accepts 'follow-privileges' - fix applied!"
else
    echo "✗ Config.hs parser doesn't accept 'follow-privileges' - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses OAFollowPriv instead of OAFollowACL..."
if grep -q 'OAFollowPriv ->' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses OAFollowPriv - fix applied!"
else
    echo "✗ App.hs doesn't use OAFollowPriv - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses OAIgnorePriv with schema filtering..."
if grep -q 'OAIgnorePriv ->' "src/PostgREST/App.hs" && grep -q 'filter.*tableSchema x == tSchema.*DbStructure.dbTables' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses OAIgnorePriv with schema filtering - fix applied!"
else
    echo "✗ App.hs missing proper schema filtering in OAIgnorePriv - fix not applied"
    test_status=1
fi

echo "Checking that App.hs imports Data.HashMap.Strict..."
if grep -q 'import qualified Data.HashMap.Strict.*as Map' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports Data.HashMap.Strict - fix applied!"
else
    echo "✗ App.hs missing Data.HashMap.Strict import - fix not applied"
    test_status=1
fi

echo "Checking that CLI.hs example config uses 'follow-privileges'..."
if grep -q 'openapi-mode = "follow-privileges"' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs example config has 'follow-privileges' - fix applied!"
else
    echo "✗ CLI.hs example config missing 'follow-privileges' - fix not applied"
    test_status=1
fi

echo "Checking that postgrest.cabal references IgnorePrivOpenApiSpec..."
if grep -q 'Feature.IgnorePrivOpenApiSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has IgnorePrivOpenApiSpec - fix applied!"
else
    echo "✗ postgrest.cabal missing IgnorePrivOpenApiSpec - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
