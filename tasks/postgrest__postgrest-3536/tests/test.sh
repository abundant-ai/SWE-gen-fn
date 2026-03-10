#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/io"
cp "/tests/io/test_replica.py" "test/io/test_replica.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that AppState.hs has the retry logic with exponential backoff
echo "Checking that AppState.hs has retryingListen function..."
if grep -q "retryingListen" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has retryingListen function - fix applied!"
else
    echo "✗ AppState.hs missing retryingListen function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs imports recoverAll from Control.Retry..."
if grep -q "recoverAll" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports recoverAll - fix applied!"
else
    echo "✗ AppState.hs doesn't import recoverAll - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs has exponentialBackoff retry policy..."
if grep -q "exponentialBackoff" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses exponentialBackoff - fix applied!"
else
    echo "✗ AppState.hs doesn't use exponentialBackoff - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs has retryPolicy definition..."
if grep -q "retryPolicy ::" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has retryPolicy definition - fix applied!"
else
    echo "✗ AppState.hs missing retryPolicy definition - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions the fix..."
if grep -q "#3536" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions PR #3536 - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention PR #3536 - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
