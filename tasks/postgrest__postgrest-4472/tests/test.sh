#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/big_schema.sql" "test/io/fixtures/big_schema.sql"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4472 which fixes performance and high memory usage of relation hint calculation
# The fix uses SchemaCache with dbTablesFuzzyIndex instead of reconstructing fuzzy search on each request

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the relation hint fix..."
if grep -q "Fix performance and high memory usage of relation hint calculation" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions relation hint fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention relation hint fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs imports SchemaCache with dbTablesFuzzyIndex..."
if grep -q "import PostgREST.SchemaCache.*SchemaCache (SchemaCache, dbTablesFuzzyIndex)" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs imports dbTablesFuzzyIndex from SchemaCache - fix applied!"
else
    echo "✗ Error.hs does not import dbTablesFuzzyIndex - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses SchemaCache in TableNotFound..."
if grep -q "TableNotFound Text Text SchemaCache" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs TableNotFound uses SchemaCache - fix applied!"
else
    echo "✗ Error.hs TableNotFound does not use SchemaCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that tableNotFoundHint uses SchemaCache parameter..."
if grep -q "tableNotFoundHint :: Text -> Text -> SchemaCache -> Maybe Text" "src/PostgREST/Error.hs"; then
    echo "✓ tableNotFoundHint signature uses SchemaCache - fix applied!"
else
    echo "✗ tableNotFoundHint does not use SchemaCache parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that tableNotFoundHint extracts dbTablesFuzzyIndex..."
if grep -q "tableNotFoundHint schema tblName SchemaCache{dbTablesFuzzyIndex}" "src/PostgREST/Error.hs"; then
    echo "✓ tableNotFoundHint extracts dbTablesFuzzyIndex - fix applied!"
else
    echo "✗ tableNotFoundHint does not extract dbTablesFuzzyIndex - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that tableNotFoundHint uses dbTablesFuzzyIndex for lookup..."
if grep -q "perhapsTable = (\`Fuzzy.getOne\` tblName) =<< HM.lookup schema dbTablesFuzzyIndex" "src/PostgREST/Error.hs"; then
    echo "✓ tableNotFoundHint uses dbTablesFuzzyIndex lookup - fix applied!"
else
    echo "✗ tableNotFoundHint does not use dbTablesFuzzyIndex - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs passes sCache to findTable..."
if grep -q "findTable identifier sCache" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs passes sCache to findTable - fix applied!"
else
    echo "✗ Plan.hs does not pass sCache to findTable - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs does NOT use old dbTables approach..."
if ! grep -q "findTable identifier (dbTables sCache)" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs does not use old dbTables approach - fix applied!"
else
    echo "✗ Plan.hs still uses old dbTables approach - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs does NOT import Table from SchemaCache.Table..."
if ! grep -q "import PostgREST.SchemaCache.Table" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs does not import SchemaCache.Table - fix applied!"
else
    echo "✗ Error.hs still imports SchemaCache.Table - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
