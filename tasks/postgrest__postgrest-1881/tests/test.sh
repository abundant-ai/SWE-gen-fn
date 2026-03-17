#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/DisabledOpenApiSpec.hs" "test/Feature/DisabledOpenApiSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/IgnoreAclOpenApiSpec.hs" "test/Feature/IgnoreAclOpenApiSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test"
cp "/tests/SpecHelper.hs" "test/SpecHelper.hs"
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

# Verify source code matches HEAD state (fix applied)
# This is PR #1881 which adds openapi-mode configuration option
# HEAD state (b0b5544bfa4cebd3226f0b30272e997b16d1c7b4) = has openapi-mode config - FIXED
# BASE state (with bug.patch) = no openapi-mode config - BUGGY
# ORACLE state (BASE + fix.patch) = has openapi-mode config - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for openapi-mode config)..."
echo ""

echo "Checking that Config.hs defines OpenAPIMode data type..."
if grep -q 'data OpenAPIMode = OAFollowACL | OAIgnoreACL | OADisabled' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has OpenAPIMode data type - fix applied!"
else
    echo "✗ Config.hs missing OpenAPIMode data type - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs show instance for OpenAPIMode exists..."
if grep -q 'instance Show OpenAPIMode' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has complete show instance - fix applied!"
else
    echo "✗ Config.hs missing complete show instance - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs exports OpenAPIMode..."
if grep -q 'OpenAPIMode(..)' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs exports OpenAPIMode - fix applied!"
else
    echo "✗ Config.hs doesn't export OpenAPIMode - fix not applied"
    test_status=1
fi

echo "Checking that AppConfig has configOpenApiMode field..."
if grep -q 'configOpenApiMode.*::.*OpenAPIMode' "src/PostgREST/Config.hs"; then
    echo "✓ AppConfig has configOpenApiMode field - fix applied!"
else
    echo "✗ AppConfig missing configOpenApiMode field - fix not applied"
    test_status=1
fi

echo "Checking that App.hs imports OpenAPIMode..."
if grep -q 'OpenAPIMode (..)' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports OpenAPIMode - fix applied!"
else
    echo "✗ App.hs doesn't import OpenAPIMode - fix not applied"
    test_status=1
fi

echo "Checking that App.hs handleOpenApi uses configOpenApiMode..."
if grep -q 'configOpenApiMode' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses configOpenApiMode - fix applied!"
else
    echo "✗ App.hs doesn't use configOpenApiMode - fix not applied"
    test_status=1
fi

echo "Checking that App.hs has OAFollowACL case..."
if grep -q 'OAFollowACL ->' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has OAFollowACL case - fix applied!"
else
    echo "✗ App.hs missing OAFollowACL case - fix not applied"
    test_status=1
fi

echo "Checking that App.hs has OAIgnoreACL case..."
if grep -q 'OAIgnoreACL ->' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has OAIgnoreACL case - fix applied!"
else
    echo "✗ App.hs missing OAIgnoreACL case - fix not applied"
    test_status=1
fi

echo "Checking that App.hs has OADisabled case..."
if grep -q 'OADisabled ->' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has OADisabled case - fix applied!"
else
    echo "✗ App.hs missing OADisabled case - fix not applied"
    test_status=1
fi

echo "Checking that CLI.hs example config includes openapi-mode..."
if grep -q 'openapi-mode = "follow-acl"' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs example config has openapi-mode - fix applied!"
else
    echo "✗ CLI.hs example config missing openapi-mode - fix not applied"
    test_status=1
fi

echo "Checking that postgrest.cabal includes DisabledOpenApiSpec..."
if grep -q 'Feature.DisabledOpenApiSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has DisabledOpenApiSpec - fix applied!"
else
    echo "✗ postgrest.cabal missing DisabledOpenApiSpec - fix not applied"
    test_status=1
fi

echo "Checking that postgrest.cabal includes IgnoreAclOpenApiSpec..."
if grep -q 'Feature.IgnoreAclOpenApiSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has IgnoreAclOpenApiSpec - fix applied!"
else
    echo "✗ postgrest.cabal missing IgnoreAclOpenApiSpec - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
