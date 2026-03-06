#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SpreadQueriesSpec.hs" "test/spec/Feature/Query/SpreadQueriesSpec.hs"

# Verify source code matches HEAD state (empty spread embeddings fix applied)
# This is PR #4192 which ADDS the fix for empty spread embeddings
# HEAD state (db6c9be4c6) = fix applied, has proper handling
# BASE state (with bug.patch) = broken handling (bug state)
# ORACLE state (BASE + fix.patch) = proper handling (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (empty spread embeddings fix applied)..."
echo ""

echo "Checking that QueryBuilder.hs uses 'join \$ map' pattern..."
if grep -q "join \$ map relSelectToSnippet relSelect" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses 'join \$ map' - fix applied!"
else
    echo "✗ QueryBuilder.hs does not use 'join \$ map' - fix not applied"
    test_status=1
fi

echo "Checking that relSelectToSnippet returns [SQL.Snippet]..."
if grep -q "relSelectToSnippet :: RelSelectField -> \[SQL.Snippet\]" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ relSelectToSnippet has correct return type [SQL.Snippet] - fix applied!"
else
    echo "✗ relSelectToSnippet does not have correct return type - fix not applied"
    test_status=1
fi

echo "Checking that JsonEmbed empty case returns []..."
if grep -q "JsonEmbed{rsEmptyEmbed = True} ->" "src/PostgREST/Query/QueryBuilder.hs" && \
   grep -A1 "JsonEmbed{rsEmptyEmbed = True} ->" "src/PostgREST/Query/QueryBuilder.hs" | grep -q "^\s*\[\]"; then
    echo "✓ JsonEmbed empty case returns [] - fix applied!"
else
    echo "✗ JsonEmbed empty case does not return [] - fix not applied"
    test_status=1
fi

echo "Checking that Spread case returns list..."
if grep -q "pgFmtSpreadSelectItem rsAggAlias <\$> rsSpreadSel" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ Spread case returns list properly - fix applied!"
else
    echo "✗ Spread case does not return list properly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test file includes empty spread embeddings tests..."
if grep -q "context \"empty spreads embeds\"" "test/spec/Feature/Query/SpreadQueriesSpec.hs"; then
    echo "✓ Test file includes empty spread embeddings context - test from HEAD!"
else
    echo "✗ Test file does not include empty spread embeddings context - test not from HEAD"
    test_status=1
fi

if grep -q "get \"/actors?select=\*,...films()\"" "test/spec/Feature/Query/SpreadQueriesSpec.hs"; then
    echo "✓ Test file includes actors/films test case - test from HEAD!"
else
    echo "✗ Test file does not include actors/films test case - test not from HEAD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
