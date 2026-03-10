#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4274 which fixes metrics endpoint not responding with Content-Type header
# The fix adds [toContentType MTTextPlain] to the Wai.responseLBS call for /metrics

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the metrics Content-Type header fix..."
if grep -q "Fix \`/metrics\` endpoint not responding with \`Content-Type\` header" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions metrics Content-Type header fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Admin.hs includes Content-Type header for metrics endpoint..."
if grep -q 'respond \$ Wai.responseLBS HTTP.status200 \[toContentType MTTextPlain\] mets' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs includes Content-Type header for metrics endpoint - fix applied!"
else
    echo "✗ Admin.hs does not include Content-Type header for metrics endpoint - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Admin.hs does NOT use old metrics implementation without Content-Type..."
if ! grep -q 'respond \$ Wai.responseLBS HTTP.status200 \[\] mets$' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs does not use old metrics implementation - fix applied!"
else
    echo "✗ Admin.hs still uses old metrics implementation (without Content-Type) - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py includes assertion for Content-Type header..."
if grep -q 'assert response.headers\["Content-Type"\] == "text/plain; charset=utf-8"' "test/io/test_io.py"; then
    echo "✓ test_io.py includes Content-Type assertion - fix applied!"
else
    echo "✗ test_io.py does not include Content-Type assertion - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
