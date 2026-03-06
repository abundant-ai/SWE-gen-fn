#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4056 which removes /config endpoint from admin server
# HEAD state (b932edb4c9) = fix applied, /config endpoint removed
# BASE state (with bug.patch) = /config endpoint exists
# ORACLE state (BASE + fix.patch) = /config endpoint removed

test_status=0

echo "Verifying source code matches HEAD state (/config endpoint removed)..."
echo ""

echo "Checking that Admin.hs does NOT import Config module..."
if ! grep -q 'import qualified PostgREST.Config   as Config' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs does not import Config module - fix applied!"
else
    echo "✗ Admin.hs still imports Config module - fix not applied"
    test_status=1
fi

echo "Checking that Admin.hs does NOT import Data.ByteString.Lazy as LBS..."
if ! grep -q 'import qualified Data.ByteString.Lazy as LBS' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs does not import Data.ByteString.Lazy - fix applied!"
else
    echo "✗ Admin.hs still imports Data.ByteString.Lazy - fix not applied"
    test_status=1
fi

echo "Checking that Admin.hs does NOT have /config endpoint handler..."
if ! grep -q '\["config"\] -> do' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs does not have /config endpoint handler - fix applied!"
else
    echo "✗ Admin.hs still has /config endpoint handler - fix not applied"
    test_status=1
fi

echo "Checking that documentation does NOT mention Runtime Configuration endpoint..."
if ! grep -q 'Runtime Configuration' "docs/references/admin_server.rst"; then
    echo "✓ admin_server.rst does not mention Runtime Configuration - fix applied!"
else
    echo "✗ admin_server.rst still mentions Runtime Configuration - fix not applied"
    test_status=1
fi

echo "Checking that test file does NOT include test_admin_config..."
if ! grep -q 'def test_admin_config' "test/io/test_io.py"; then
    echo "✓ test_io.py does not have test_admin_config - test from HEAD!"
else
    echo "✗ test_io.py still has test_admin_config - test not from HEAD"
    test_status=1
fi

echo "Checking that CHANGELOG mentions dropping /config endpoint..."
if grep -q 'Drop `/config` endpoint of admin server' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions dropping /config endpoint - fix applied!"
else
    echo "✗ CHANGELOG does not mention dropping /config endpoint - fix not applied"
    test_status=1
fi

echo "Checking that CHANGELOG has the 12.2.12 section about config being disabled by default..."
if grep -q '\[12.2.12\]' "CHANGELOG.md"; then
    echo "✓ CHANGELOG has 12.2.12 section - fix applied!"
else
    echo "✗ CHANGELOG does not have 12.2.12 section - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
