#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (PostGIS fix applied)
# This is PR #4246 which ADDS the PostGIS detection fix
# HEAD state (5f86ab397b) = fix applied, has postgisFunc code
# BASE state (with bug.patch) = no postgisFunc code (bug state)
# ORACLE state (BASE + fix.patch) = has postgisFunc code (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (PostGIS fix applied)..."
echo ""

echo "Checking that PostgREST/SchemaCache.hs has postgisFunc..."
if grep -q "postgisFunc :: Bool -> SQL.Statement AppConfig Bool" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has postgisFunc - fix applied!"
else
    echo "✗ SchemaCache.hs does not have postgisFunc - fix not applied"
    test_status=1
fi

if grep -q "hasPgis <- SQL.statement conf" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs calls postgisFunc - fix applied!"
else
    echo "✗ SchemaCache.hs does not call postgisFunc - fix not applied"
    test_status=1
fi

if grep -q "initialMediaHandlers :: Bool -> MediaHandlerMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ initialMediaHandlers takes Bool parameter - fix applied!"
else
    echo "✗ initialMediaHandlers does not take Bool parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml..."
if grep -q "MTGeoJSON" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbMediaHandlers].yaml"; then
    echo "✗ Snapshot includes GeoJSON handler - fix not applied (PostGIS detection not working)"
    test_status=1
else
    echo "✓ Snapshot does not include GeoJSON handler (test file from HEAD)!"
fi

echo ""
echo "Checking that test/io/test_io.py has the test (HEAD has fix applied)..."
if grep -q "def test_no_pool_connection_required_on_unavailable_postgis" "test/io/test_io.py"; then
    echo "✓ test_io.py includes test (test file from HEAD)!"
else
    echo "✗ test_io.py does not include test - test file not from HEAD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
