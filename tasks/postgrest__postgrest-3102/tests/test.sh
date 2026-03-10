#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io"
cp "/tests/io/db_config.sql" "test/io/db_config.sql"

# Verify that the fix has been applied by checking test file changes
test_status=0

echo "Verifying fix has been applied to test files..."
echo ""

# Check that jwt-cache-max-lifetime is set to 3600 in no-defaults-with-db.config (from db config)
echo "Checking jwt-cache-max-lifetime in no-defaults-with-db.config..."
if grep -q "^jwt-cache-max-lifetime = 3600$" "test/io/configs/expected/no-defaults-with-db.config"; then
    echo "✓ jwt-cache-max-lifetime correctly set to 3600 (from database config)"
else
    echo "✗ jwt-cache-max-lifetime not set to 3600 - fix not applied"
    echo "  Expected: jwt-cache-max-lifetime = 3600"
    echo "  Actual:"
    grep "jwt-cache-max-lifetime" "test/io/configs/expected/no-defaults-with-db.config" || echo "  (not found)"
    test_status=1
fi

# Check that jwt-cache-max-lifetime is set correctly in other-authenticator config
echo "Checking jwt-cache-max-lifetime in no-defaults-with-db-other-authenticator.config..."
if grep -q "^jwt-cache-max-lifetime = 7200$" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"; then
    echo "✓ jwt-cache-max-lifetime correctly set to 7200 (from other_authenticator db config)"
else
    echo "✗ jwt-cache-max-lifetime not set to 7200 in other-authenticator config"
    test_status=1
fi

# Check that db_config.sql includes the jwt_cache_max_lifetime setting
echo "Checking db_config.sql for jwt_cache_max_lifetime setting..."
if grep -q "pgrst.jwt_cache_max_lifetime = '3600'" "test/io/db_config.sql"; then
    echo "✓ db_config.sql includes jwt_cache_max_lifetime setting"
else
    echo "✗ db_config.sql missing jwt_cache_max_lifetime setting - fix not applied"
    test_status=1
fi

# Check that Config/Database.hs was updated to include the setting
echo "Checking src/PostgREST/Config/Database.hs for jwt_cache_max_lifetime..."
if grep -q "jwt_cache_max_lifetime" "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs includes jwt_cache_max_lifetime"
else
    echo "✗ Config/Database.hs missing jwt_cache_max_lifetime - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
