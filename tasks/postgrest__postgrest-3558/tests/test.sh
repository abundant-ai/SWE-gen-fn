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
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that Config.hs has the configAdminServerHost field
echo "Checking that Config.hs has configAdminServerHost field..."
if grep -q "configAdminServerHost" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configAdminServerHost field - fix applied!"
else
    echo "✗ Config.hs missing configAdminServerHost field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that admin-server-host is documented..."
if grep -q "admin-server-host" "docs/references/configuration.rst"; then
    echo "✓ Documentation mentions admin-server-host - fix applied!"
else
    echo "✗ Documentation doesn't mention admin-server-host - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs uses configAdminServerHost..."
if grep -q "configAdminServerHost" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses configAdminServerHost - fix applied!"
else
    echo "✗ AppState.hs doesn't use configAdminServerHost - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions the feature..."
if grep -q "admin-server-host" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions admin-server-host - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention admin-server-host - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
