#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #3925 which adds logging for connection pool borrows at debug level
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the connection pool logging fix..."
if grep -q "Log connection pool borrows on \`log-level=debug\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions connection pool logging fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Observation.hs includes message for PoolRequest..."
if grep -q 'PoolRequest ->' "src/PostgREST/Observation.hs" && grep -q '"Trying to borrow a connection from pool"' "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs includes message for PoolRequest - fix applied!"
else
    echo "✗ Observation.hs does not include PoolRequest message - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Observation.hs includes message for PoolRequestFullfilled..."
if grep -q 'PoolRequestFullfilled ->' "src/PostgREST/Observation.hs" && grep -q '"Borrowed a connection from the pool"' "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs includes message for PoolRequestFullfilled - fix applied!"
else
    echo "✗ Observation.hs does not include PoolRequestFullfilled message - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs logs PoolRequest at debug level..."
if grep -q 'o@PoolRequest ->' "src/PostgREST/Logger.hs" && grep -q 'when (logLevel >= LogDebug)' "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs logs PoolRequest at debug level - fix applied!"
else
    echo "✗ Logger.hs does not log PoolRequest at debug level - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs logs PoolRequestFullfilled at debug level..."
if grep -q 'o@PoolRequestFullfilled ->' "src/PostgREST/Logger.hs" && grep -A1 'o@PoolRequestFullfilled ->' "src/PostgREST/Logger.hs" | grep -q 'when (logLevel >= LogDebug)'; then
    echo "✓ Logger.hs logs PoolRequestFullfilled at debug level - fix applied!"
else
    echo "✗ Logger.hs does not log PoolRequestFullfilled at debug level - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
