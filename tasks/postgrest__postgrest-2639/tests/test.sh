#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for NOTIFY not reloading catalog cache (PR #2639)..."
echo ""
echo "NOTE: This PR fixes the issue where NOTIFY pgrst doesn't reload db connections catalog cache"
echo "HEAD (fixed) should have cacheReloader that calls connectionWorker (restarts connections)"
echo "BASE (buggy) has scLoader that only calls loadSchemaCache (doesn't restart connections)"
echo ""

# Check Workers.hs - HEAD should use cacheReloader instead of scLoader
echo "Checking src/PostgREST/Workers.hs uses cacheReloader instead of scLoader..."
if grep -q "cacheReloader" "src/PostgREST/Workers.hs" && ! grep -q "scLoader" "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs uses cacheReloader (not scLoader)"
else
    echo "✗ Workers.hs still uses scLoader or missing cacheReloader - fix not applied"
    test_status=1
fi

# Check Workers.hs - HEAD should call connectionWorker in cacheReloader
echo "Checking src/PostgREST/Workers.hs cacheReloader calls connectionWorker..."
if grep -A5 "cacheReloader =" "src/PostgREST/Workers.hs" | grep -q "connectionWorker appState"; then
    echo "✓ Workers.hs cacheReloader calls connectionWorker"
else
    echo "✗ Workers.hs cacheReloader does not call connectionWorker - fix not applied"
    test_status=1
fi

# Check Workers.hs - HEAD should NOT have scLoader function
echo "Checking src/PostgREST/Workers.hs does NOT have scLoader function..."
if ! grep -q "scLoader" "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs does not have scLoader function"
else
    echo "✗ Workers.hs still has scLoader function - fix not applied"
    test_status=1
fi

# Check Workers.hs - HEAD notification handler should call cacheReloader
echo "Checking src/PostgREST/Workers.hs handleNotification calls cacheReloader for schema reload..."
if grep -A5 "msg == \"reload schema\"" "src/PostgREST/Workers.hs" | grep -q "cacheReloader"; then
    echo "✓ Workers.hs handleNotification calls cacheReloader for schema reload"
else
    echo "✗ Workers.hs handleNotification does not call cacheReloader - fix not applied"
    test_status=1
fi

# Check test file - HEAD should have test_notify_reloading_catalog_cache test
echo "Checking test/io/test_io.py has test_notify_reloading_catalog_cache test..."
if grep -q "def test_notify_reloading_catalog_cache" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_notify_reloading_catalog_cache test"
else
    echo "✗ test_io.py missing test_notify_reloading_catalog_cache - fix not applied"
    test_status=1
fi

# Check fixtures.sql - HEAD should have cats table and drop_change_cats function
echo "Checking test/io/fixtures.sql has cats table and drop_change_cats function..."
if grep -q "create table cats" "test/io/fixtures.sql" && grep -q "create function drop_change_cats" "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql has cats table and drop_change_cats function"
else
    echo "✗ fixtures.sql missing cats table or drop_change_cats - fix not applied"
    test_status=1
fi

# Check CHANGELOG - HEAD should mention the fix for #2620
echo "Checking CHANGELOG.md mentions fix for catalog cache reload..."
if grep -q "#2620" "CHANGELOG.md" || grep -q "NOTIFY pgrst.*catalog cache" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - catalog cache reload properly fixed"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
