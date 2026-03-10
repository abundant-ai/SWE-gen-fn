#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking the files exist and have correct content
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md mentions the JWT cache fix
echo "Checking that CHANGELOG.md mentions the JWT cache fix..."
if grep -q "#3788, Fix jwt cache does not remove expired entries" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the JWT cache fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the JWT cache fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs contains purgeExpired call..."
if grep -q "C.purgeExpired jwtCache" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs contains purgeExpired call - fix applied!"
else
    echo "✗ Auth.hs does not contain purgeExpired call - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs contains the cache miss comment..."
if grep -q "cache miss" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs contains cache miss comment - fix applied!"
else
    echo "✗ Auth.hs does not contain cache miss comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs contains the time-based expiration comment..."
if grep -q "time expiration based cache" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs contains time-based expiration comment - fix applied!"
else
    echo "✗ Auth.hs does not contain time-based expiration comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py contains test_jwt_cache_purges_expired_entries..."
if grep -q "def test_jwt_cache_purges_expired_entries" "test/io/test_io.py"; then
    echo "✓ test_io.py contains test_jwt_cache_purges_expired_entries - fix applied!"
else
    echo "✗ test_io.py does not contain test_jwt_cache_purges_expired_entries - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test mentions purgeExpired function..."
if grep -q "purgeExpired function" "test/io/test_io.py"; then
    echo "✓ test_io.py mentions purgeExpired function - fix applied!"
else
    echo "✗ test_io.py does not mention purgeExpired function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
