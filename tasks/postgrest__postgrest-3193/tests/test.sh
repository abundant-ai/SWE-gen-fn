#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3171, Add an ability to dump config via admin API" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that Admin.hs imports Data.ByteString.Lazy
echo "Checking that Admin.hs imports Data.ByteString.Lazy..."
if grep -q "import qualified Data.ByteString.Lazy as LBS" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs imports Data.ByteString.Lazy"
else
    echo "✗ Admin.hs missing Data.ByteString.Lazy import - fix not applied"
    test_status=1
fi

# Check that Admin.hs imports PostgREST.Config
echo "Checking that Admin.hs imports PostgREST.Config..."
if grep -q "import qualified PostgREST.Config   as Config" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs imports PostgREST.Config"
else
    echo "✗ Admin.hs missing PostgREST.Config import - fix not applied"
    test_status=1
fi

# Check that Admin.hs has the /config endpoint handler
echo "Checking that Admin.hs has the /config endpoint handler..."
if grep -q '\["config"\]' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs has the /config endpoint handler"
else
    echo "✗ Admin.hs missing /config endpoint handler - fix not applied"
    test_status=1
fi

# Check that the /config endpoint calls AppState.getConfig
echo "Checking that /config endpoint calls AppState.getConfig..."
if grep -A 2 '\["config"\]' "src/PostgREST/Admin.hs" | grep -q "config <- AppState.getConfig appState"; then
    echo "✓ /config endpoint calls AppState.getConfig"
else
    echo "✗ /config endpoint not calling AppState.getConfig - fix not applied"
    test_status=1
fi

# Check that the /config endpoint uses Config.toText
echo "Checking that /config endpoint uses Config.toText..."
if grep -A 3 '\["config"\]' "src/PostgREST/Admin.hs" | grep -q "Config.toText config"; then
    echo "✓ /config endpoint uses Config.toText"
else
    echo "✗ /config endpoint not using Config.toText - fix not applied"
    test_status=1
fi

# Check that the /config endpoint returns HTTP 200
echo "Checking that /config endpoint returns HTTP 200..."
if grep -A 3 '\["config"\]' "src/PostgREST/Admin.hs" | grep -q "HTTP.status200"; then
    echo "✓ /config endpoint returns HTTP 200"
else
    echo "✗ /config endpoint not returning HTTP 200 - fix not applied"
    test_status=1
fi

# Check that test_io.py includes test_admin_config
echo "Checking that test_io.py includes test_admin_config..."
if grep -q "def test_admin_config(defaultenv):" "test/io/test_io.py"; then
    echo "✓ test_io.py includes test_admin_config"
else
    echo "✗ test_io.py missing test_admin_config - fix not applied"
    test_status=1
fi

# Check that test_admin_config tests /config endpoint
echo "Checking that test_admin_config tests /config endpoint..."
if grep -A 10 "def test_admin_config" "test/io/test_io.py" | grep -q 'postgrest.admin.get("/config")'; then
    echo "✓ test_admin_config tests /config endpoint"
else
    echo "✗ test_admin_config not testing /config endpoint - fix not applied"
    test_status=1
fi

# Check that test_admin_config checks for status 200
echo "Checking that test_admin_config checks for status 200..."
if grep -A 10 "def test_admin_config" "test/io/test_io.py" | grep -q "response.status_code == 200"; then
    echo "✓ test_admin_config checks for status 200"
else
    echo "✗ test_admin_config not checking for status 200 - fix not applied"
    test_status=1
fi

# Check that test_admin_config checks for "admin-server-port" in response
echo "Checking that test_admin_config checks for admin-server-port in response..."
if grep -A 10 "def test_admin_config" "test/io/test_io.py" | grep -q '"admin-server-port"'; then
    echo "✓ test_admin_config checks for admin-server-port in response"
else
    echo "✗ test_admin_config not checking for admin-server-port - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
