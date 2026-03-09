#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4651 which adds logging for async exceptions including stack overflow
# HEAD state (f4464890ef92a57133bb0bbeae062a0233871b23) = fix applied, logs Warp errors
# BASE state (with bug.patch) = old state that hides async exceptions

test_status=0

echo "Verifying source code matches HEAD state (async exception logging added)..."
echo ""

echo "Checking that src/PostgREST/App.hs has onWarpException handler..."
if grep -q "onWarpException" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has onWarpException handler - fix applied!"
else
    echo "✗ src/PostgREST/App.hs does not have onWarpException handler - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/App.hs has shouldDisplayException function..."
if grep -q "shouldDisplayException" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has shouldDisplayException function - fix applied!"
else
    echo "✗ src/PostgREST/App.hs does not have shouldDisplayException function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/App.hs sets Warp's setOnException..."
if grep -q "setOnException" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs uses setOnException - fix applied!"
else
    echo "✗ src/PostgREST/App.hs does not use setOnException - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs has WarpErrorObs observation..."
if grep -q "WarpErrorObs" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has WarpErrorObs observation - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs does not have WarpErrorObs observation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_big_schema.py has test_stackoverflow_is_logged test..."
if grep -q "test_stackoverflow_is_logged" "test/io/test_big_schema.py"; then
    echo "✓ test/io/test_big_schema.py has test_stackoverflow_is_logged test - fix applied!"
else
    echo "✗ test/io/test_big_schema.py does not have test_stackoverflow_is_logged test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_big_schema.py imports requests..."
if grep -q "import requests" "test/io/test_big_schema.py"; then
    echo "✓ test/io/test_big_schema.py imports requests - fix applied!"
else
    echo "✗ test/io/test_big_schema.py does not import requests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
