#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml"
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/schema.sql" "test/io/fixtures/schema.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for Vary header support (PR #4609)..."
echo ""
echo "This PR adds a Vary header to PostgREST responses to assist caching proxies and CDNs."
echo "The header includes 'Accept, Prefer, Range' and can be overridden via response.headers GUC."
echo ""

echo "Checking App.hs imports HTTP.hVary..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'import qualified Network.HTTP.Types.Header as HTTP (hVary)' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports HTTP.hVary (fix applied)"
else
    echo "✗ App.hs does not import HTTP.hVary (not fixed)"
    test_status=1
fi

echo "Checking App.hs has varyHeader definition..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'varyHeader :: HTTP.Header' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has varyHeader definition (fix applied)"
else
    echo "✗ App.hs does not have varyHeader definition (not fixed)"
    test_status=1
fi

echo "Checking App.hs has varyHeader value set to Accept, Prefer, Range..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'varyHeader = (HTTP.hVary, "Accept, Prefer, Range")' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has correct varyHeader value (fix applied)"
else
    echo "✗ App.hs does not have correct varyHeader value (not fixed)"
    test_status=1
fi

echo "Checking App.hs has varyHeaderPresent function..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'varyHeaderPresent :: \[HTTP.Header\] -> Bool' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has varyHeaderPresent function (fix applied)"
else
    echo "✗ App.hs does not have varyHeaderPresent function (not fixed)"
    test_status=1
fi

echo "Checking App.hs toWaiResponse includes varyHeader conditionally..."
if [ -f "src/PostgREST/App.hs" ] && grep -q '\[varyHeader | not \$ varyHeaderPresent hdrs\]' "src/PostgREST/App.hs"; then
    echo "✓ App.hs toWaiResponse includes conditional varyHeader (fix applied)"
else
    echo "✗ App.hs toWaiResponse does not include conditional varyHeader (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test snapshot file exists..."
if [ -f "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" ]; then
    echo "✓ test_schema_cache_snapshot[dbRoutines].yaml exists (HEAD version)"
else
    echo "✗ test_schema_cache_snapshot[dbRoutines].yaml not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking test fixture file exists..."
if [ -f "test/io/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking test file exists..."
if [ -f "test/io/test_io.py" ]; then
    echo "✓ test_io.py exists (HEAD version)"
else
    echo "✗ test_io.py not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
