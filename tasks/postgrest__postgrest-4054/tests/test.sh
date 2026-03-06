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

# Verify source code matches HEAD state (fix applied)
# This is PR #4054 which adds admin-server-config-enabled flag to protect /config endpoint
# HEAD state (44e9f6e3) = fix applied, admin-server-config-enabled added
# BASE state (with bug.patch) = admin-server-config-enabled removed (buggy, no protection)
# ORACLE state (BASE + fix.patch) = admin-server-config-enabled added (fixed, protected)

test_status=0

echo "Verifying source code matches HEAD state (admin-server-config-enabled protection added)..."
echo ""

echo "Checking that config files HAVE admin-server-config-enabled line..."
for config_file in \
    "test/io/configs/expected/aliases.config" \
    "test/io/configs/expected/boolean-numeric.config" \
    "test/io/configs/expected/boolean-string.config" \
    "test/io/configs/expected/defaults.config" \
    "test/io/configs/expected/no-defaults-with-db-other-authenticator.config" \
    "test/io/configs/expected/no-defaults-with-db.config" \
    "test/io/configs/expected/no-defaults.config" \
    "test/io/configs/expected/types.config"; do
    if grep -q "admin-server-config-enabled" "$config_file"; then
        echo "✓ $config_file has admin-server-config-enabled - fix applied!"
    else
        echo "✗ $config_file does not have admin-server-config-enabled - fix not applied"
        test_status=1
    fi
done

echo ""
echo "Checking that no-defaults.config HAS admin-server-config-enabled..."
if grep -q "admin-server-config-enabled" "test/io/configs/no-defaults.config"; then
    echo "✓ no-defaults.config has admin-server-config-enabled - fix applied!"
else
    echo "✗ no-defaults.config does not have admin-server-config-enabled - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that no-defaults-env.yaml HAS PGRST_ADMIN_SERVER_CONFIG_ENABLED..."
if grep -q "PGRST_ADMIN_SERVER_CONFIG_ENABLED" "test/io/configs/no-defaults-env.yaml"; then
    echo "✓ no-defaults-env.yaml has PGRST_ADMIN_SERVER_CONFIG_ENABLED - fix applied!"
else
    echo "✗ no-defaults-env.yaml does not have PGRST_ADMIN_SERVER_CONFIG_ENABLED - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py test_admin_config test checks for 404 response..."
if grep -q "assert response.status_code == 404" "test/io/test_io.py"; then
    echo "✓ test_io.py checks for 404 response - fix applied!"
else
    echo "✗ test_io.py does not check for 404 response - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py test_admin_config test checks PGRST_ADMIN_SERVER_CONFIG_ENABLED..."
if grep -q "PGRST_ADMIN_SERVER_CONFIG_ENABLED" "test/io/test_io.py"; then
    echo "✓ test_io.py checks PGRST_ADMIN_SERVER_CONFIG_ENABLED - fix applied!"
else
    echo "✗ test_io.py does not check PGRST_ADMIN_SERVER_CONFIG_ENABLED - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SpecHelper.hs sets configAdminServerConfigEnabled..."
if grep -q "configAdminServerConfigEnabled" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs sets configAdminServerConfigEnabled - fix applied!"
else
    echo "✗ SpecHelper.hs does not set configAdminServerConfigEnabled - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions the fix..."
if grep -q "Fix exposing admin server" "CHANGELOG.md" && grep -q "admin-server-config-enabled" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG does not mention the fix - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
