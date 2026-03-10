#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #4341 which fixes not logging transaction variables and db-pre-request function when log-query=main-query is enabled
# The fix adds mqTxVars and mqPreReq to the logged snippets in Logger.hs

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the transaction variables and db-pre-request logging fix..."
if grep -q "Fix not logging transaction variables and db-pre-request function when \`log-query=main-query\` is enabled" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions transaction variables and db-pre-request logging fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs logs mqTxVars in logMainQ..."
if grep -q "let snipts  = renderSnippet <\$> \[mqTxVars," "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs includes mqTxVars in logged snippets - fix applied!"
else
    echo "✗ Logger.hs does not include mqTxVars in logged snippets - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs logs mqPreReq in logMainQ..."
if grep -q "fromMaybe mempty mqPreReq" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs includes mqPreReq in logged snippets - fix applied!"
else
    echo "✗ Logger.hs does not include mqPreReq in logged snippets - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs logs snippets in correct order (mqTxVars, mqPreReq, mqMain, x, y, z, mqExplain)..."
if grep -q "let snipts  = renderSnippet <\$> \[mqTxVars, fromMaybe mempty mqPreReq, mqMain, x, y, z, fromMaybe mempty mqExplain\]" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs logs snippets in correct order - fix applied!"
else
    echo "✗ Logger.hs does not log snippets in correct order - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs does NOT use the old logging order (without mqTxVars and mqPreReq first)..."
if ! grep -q "let snipts  = renderSnippet <\$> \[mqMain, x, y, z, fromMaybe mempty mqExplain\]" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs does not use old logging order - fix applied!"
else
    echo "✗ Logger.hs still uses old logging order (mqMain first) - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
