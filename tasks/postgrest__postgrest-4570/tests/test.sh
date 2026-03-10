#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4570 which fixes Server-Timing durations being inaccurate

test_status=0

echo "Verifying source code matches HEAD state (accurate Server-Timing durations)..."
echo ""

echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "Fix inaccurate Server-Timing header durations" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST.TimeIt module exists..."
if [ -f "src/PostgREST/TimeIt.hs" ]; then
    echo "✓ src/PostgREST/TimeIt.hs exists - fix applied!"
else
    echo "✗ src/PostgREST/TimeIt.hs does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST.TimeIt module has timeItT function..."
if grep -q "timeItT :: MonadIO m => m a -> m (Double, a)" "src/PostgREST/TimeIt.hs"; then
    echo "✓ src/PostgREST/TimeIt.hs has timeItT function - fix applied!"
else
    echo "✗ src/PostgREST/TimeIt.hs missing timeItT function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST.TimeIt uses milliseconds..."
if grep -q "let time = (e - s) \* 1000" "src/PostgREST/TimeIt.hs"; then
    echo "✓ src/PostgREST/TimeIt.hs uses milliseconds - fix applied!"
else
    echo "✗ src/PostgREST/TimeIt.hs not using milliseconds - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/App.hs imports PostgREST.TimeIt..."
if grep -q "import PostgREST.TimeIt" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs imports PostgREST.TimeIt - fix applied!"
else
    echo "✗ src/PostgREST/App.hs missing PostgREST.TimeIt import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/App.hs no longer imports System.TimeIt..."
if ! grep -q "import.*System.TimeIt" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs does not import System.TimeIt - fix applied!"
else
    echo "✗ src/PostgREST/App.hs still imports System.TimeIt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Response/Performance.hs no longer multiplies by 1000..."
if ! grep -q "dur \* 1_000" "src/PostgREST/Response/Performance.hs" && \
   ! grep -q "dur \* 1000" "src/PostgREST/Response/Performance.hs"; then
    echo "✓ src/PostgREST/Response/Performance.hs does not multiply duration - fix applied!"
else
    echo "✗ src/PostgREST/Response/Performance.hs still multiplies duration - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs no longer multiplies by 1000..."
if ! grep -q "showFFloat (Just 1) (x \* 1000)" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs does not multiply duration - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs still multiplies duration - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that postgrest.cabal exports PostgREST.TimeIt..."
if grep -q "PostgREST.TimeIt" "postgrest.cabal"; then
    echo "✓ postgrest.cabal exports PostgREST.TimeIt - fix applied!"
else
    echo "✗ postgrest.cabal does not export PostgREST.TimeIt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that postgrest.cabal no longer depends on timeit..."
if ! grep -q "timeit" "postgrest.cabal"; then
    echo "✓ postgrest.cabal does not depend on timeit - fix applied!"
else
    echo "✗ postgrest.cabal still depends on timeit - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_io.py has server_timing test..."
if grep -q "test_server_timing" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has server_timing test - fix applied!"
else
    echo "✗ test/io/test_io.py missing server_timing test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
