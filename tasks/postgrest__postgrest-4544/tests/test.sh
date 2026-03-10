#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4544 which fixes inaccurate Server-Timing header durations

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the Server-Timing fix..."
if grep -q "Fix inaccurate Server-Timing header durations" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions Server-Timing fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention Server-Timing fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions the schema cache logging fix..."
if grep -q "Fix inaccurate \"Schema cache queried\" logs" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions schema cache logging fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention schema cache logging fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that new PostgREST.TimeIt module exists..."
if [ -f "src/PostgREST/TimeIt.hs" ]; then
    echo "✓ src/PostgREST/TimeIt.hs exists - fix applied!"
else
    echo "✗ src/PostgREST/TimeIt.hs does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST.TimeIt uses getMonotonicTime..."
if grep -q "getMonotonicTime" "src/PostgREST/TimeIt.hs"; then
    echo "✓ PostgREST.TimeIt uses getMonotonicTime - fix applied!"
else
    echo "✗ PostgREST.TimeIt does not use getMonotonicTime - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST.TimeIt returns time in milliseconds..."
if grep -q "let time = (e - s) \* 1000" "src/PostgREST/TimeIt.hs"; then
    echo "✓ PostgREST.TimeIt returns milliseconds - fix applied!"
else
    echo "✗ PostgREST.TimeIt does not return milliseconds - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that postgrest.cabal includes PostgREST.TimeIt module..."
if grep -q "PostgREST.TimeIt" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PostgREST.TimeIt - fix applied!"
else
    echo "✗ postgrest.cabal does not include PostgREST.TimeIt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that postgrest.cabal removes timeit dependency..."
if ! grep -q "timeit" "postgrest.cabal"; then
    echo "✓ postgrest.cabal removes timeit dependency - fix applied!"
else
    echo "✗ postgrest.cabal still has timeit dependency - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that App.hs imports PostgREST.TimeIt..."
if grep -q "import PostgREST.TimeIt" "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports PostgREST.TimeIt - fix applied!"
else
    echo "✗ App.hs does not import PostgREST.TimeIt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that App.hs no longer imports System.TimeIt..."
if ! grep -q "import.*System.TimeIt" "src/PostgREST/App.hs"; then
    echo "✓ App.hs no longer imports System.TimeIt - fix applied!"
else
    echo "✗ App.hs still imports System.TimeIt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response/Performance.hs no longer multiplies by 1000..."
if ! grep -q "dur \* 1_000\|dur \* 1000" "src/PostgREST/Response/Performance.hs"; then
    echo "✓ Response/Performance.hs no longer multiplies by 1000 - fix applied!"
else
    echo "✗ Response/Performance.hs still multiplies by 1000 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Observation.hs no longer multiplies by 1000..."
if ! grep -q "x \* 1000" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs no longer multiplies by 1000 - fix applied!"
else
    echo "✗ Observation.hs still multiplies by 1000 - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
