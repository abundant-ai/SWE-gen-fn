#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (revert applied)
# This is PR #4266 which REVERTS the PostGIS fix from PR #4245
# HEAD state (638d20de) = revert applied, no postgisFunc code
# BASE state (with bug.patch) = has postgisFunc code (fix re-applied)
# ORACLE state (BASE + fix.patch) = no postgisFunc code (matches HEAD/revert)

test_status=0

echo "Verifying source code matches HEAD state (revert applied)..."
echo ""

echo "Checking that PostgREST/SchemaCache.hs does NOT have postgisFunc..."
if grep -q "postgisFunc :: Bool -> SQL.Statement AppConfig Bool" "src/PostgREST/SchemaCache.hs"; then
    echo "✗ SchemaCache.hs still has postgisFunc - revert not applied"
    test_status=1
else
    echo "✓ SchemaCache.hs does not have postgisFunc - revert applied!"
fi

if grep -q "hasPgis <- SQL.statement conf" "src/PostgREST/SchemaCache.hs"; then
    echo "✗ SchemaCache.hs still calls postgisFunc - revert not applied"
    test_status=1
else
    echo "✓ SchemaCache.hs does not call postgisFunc - revert applied!"
fi

if grep -q "initialMediaHandlers :: Bool -> MediaHandlerMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✗ initialMediaHandlers still takes Bool parameter - revert not applied"
    test_status=1
else
    echo "✓ initialMediaHandlers does not take Bool parameter - revert applied!"
fi

echo ""
echo "Checking test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml..."
if grep -q "MTGeoJSON" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml"; then
    echo "✓ Snapshot includes GeoJSON handler (test file from HEAD)!"
else
    echo "✗ Snapshot does not include GeoJSON handler - test file not from HEAD"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_io.py does NOT have the test (HEAD has revert applied)..."
if grep -q "def test_no_pool_connection_required_on_unavailable_postgis" "test/io/test_io.py"; then
    echo "✗ test_io.py includes test - revert not applied to test file"
    test_status=1
else
    echo "✓ test_io.py does not include test (test file from HEAD)!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
