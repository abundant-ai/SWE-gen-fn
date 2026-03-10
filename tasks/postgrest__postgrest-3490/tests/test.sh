#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that Admin.hs has the correct status code logic for /live endpoint
echo "Checking that Admin.hs returns status 500 (not 503) for /live when unreachable..."
if grep -q 'respond $ Wai.responseLBS (if isMainAppReachable then HTTP.status200 else HTTP.status500)' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs /live endpoint returns 500 on failure - fix applied!"
else
    echo "✗ Admin.hs /live endpoint doesn't return 500 on failure - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Admin.hs has isPending check for /ready endpoint..."
if grep -q "isPending <- AppState.isPending appState" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs checks isPending state - fix applied!"
else
    echo "✗ Admin.hs doesn't check isPending state - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Admin.hs /ready returns 503 when isPending..."
if grep -q "| isPending.*= HTTP.status503" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs /ready endpoint returns 503 when pending - fix applied!"
else
    echo "✗ Admin.hs /ready endpoint doesn't return 503 when pending - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Admin.hs /ready returns 500 on other failures..."
if grep -q "| not isMainAppReachable = HTTP.status500" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs /ready endpoint returns 500 when main app unreachable - fix applied!"
else
    echo "✗ Admin.hs /ready endpoint doesn't return 500 when main app unreachable - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention 500 for /live endpoint..."
if grep -q "return \`\`200 OK\`\` if PostgREST is alive or \`\`500\`\` otherwise" "docs/references/admin_server.rst"; then
    echo "✓ Documentation updated for /live endpoint - fix applied!"
else
    echo "✗ Documentation not updated for /live endpoint - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention 503 for /ready pending state..."
if grep -q "return \`\`200 OK\`\` if both are good or \`\`503\`\` if not" "docs/references/admin_server.rst"; then
    echo "✓ Documentation mentions 503 for /ready - fix applied!"
else
    echo "✗ Documentation doesn't mention 503 for /ready - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions the fix..."
if grep -q "#3424" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions PR #3424 - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention PR #3424 - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
