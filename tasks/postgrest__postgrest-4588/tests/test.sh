#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/big_schema.sql" "test/io/fixtures/big_schema.sql"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4588 which fixes performance and high memory usage of relation hint calculation

test_status=0

echo "Verifying source code matches HEAD state (optimized fuzzy table index)..."
echo ""

echo "Checking that CHANGELOG.md mentions PR #4588..."
if grep -q "Fix performance and high memory usage of relation hint calculation by @mkleczek in #4462 #4463" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs imports NamedFieldPuns..."
if grep -q "{-# LANGUAGE NamedFieldPuns  #-}" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has NamedFieldPuns - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs missing NamedFieldPuns - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs imports SchemaCache with dbTablesFuzzyIndex..."
if grep -q "SchemaCache (SchemaCache, dbTablesFuzzyIndex)" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs imports dbTablesFuzzyIndex - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs missing dbTablesFuzzyIndex import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs uses SchemaCache in TableNotFound..."
if grep -q "TableNotFound Text Text SchemaCache" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses SchemaCache in TableNotFound - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not use SchemaCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs uses dbTablesFuzzyIndex in tableNotFoundHint..."
if grep -q "tableNotFoundHint schema tblName SchemaCache{dbTablesFuzzyIndex}" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses dbTablesFuzzyIndex - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs missing dbTablesFuzzyIndex usage - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Plan.hs uses SchemaCache in findTable..."
if grep -q "findTable :: QualifiedIdentifier -> SchemaCache -> Either Error QualifiedIdentifier" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses SchemaCache in findTable - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs does not use SchemaCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Plan.hs passes SchemaCache to TableNotFound..."
if grep -q "TableNotFound qiSchema qiName sc" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs passes SchemaCache to TableNotFound - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs does not pass SchemaCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Response.hs passes SchemaCache to TableNotFound..."
if grep -q "TableNotFound qiSchema qiName sc" "src/PostgREST/Response.hs"; then
    echo "✓ src/PostgREST/Response.hs passes SchemaCache to TableNotFound - fix applied!"
else
    echo "✗ src/PostgREST/Response.hs does not pass SchemaCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/SchemaCache.hs exports TablesFuzzyIndex..."
if grep -q ", TablesFuzzyIndex" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs exports TablesFuzzyIndex - fix applied!"
else
    echo "✗ src/PostgREST/SchemaCache.hs does not export TablesFuzzyIndex - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/SchemaCache.hs imports Data.FuzzySet..."
if grep -q "import qualified Data.FuzzySet" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs imports Data.FuzzySet - fix applied!"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing Data.FuzzySet import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/SchemaCache.hs defines maxDbTablesForFuzzySearch..."
if grep -q "maxDbTablesForFuzzySearch :: Int" "src/PostgREST/SchemaCache.hs" && \
   grep -q "maxDbTablesForFuzzySearch = 500" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs defines maxDbTablesForFuzzySearch = 500 - fix applied!"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing maxDbTablesForFuzzySearch - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/SchemaCache.hs has dbTablesFuzzyIndex field..."
if grep -q "dbTablesFuzzyIndex :: TablesFuzzyIndex" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has dbTablesFuzzyIndex field - fix applied!"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing dbTablesFuzzyIndex field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/SchemaCache.hs builds fuzzy index with size limit..."
if grep -q "HM.filter ((< maxDbTablesForFuzzySearch) . length)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs builds fuzzy index with size limit - fix applied!"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing size limit - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/fixtures/big_schema.sql creates fuzzysearch schema for testing..."
if grep -q "CREATE SCHEMA fuzzysearch" "test/io/fixtures/big_schema.sql"; then
    echo "✓ test/io/fixtures/big_schema.sql has fuzzysearch schema test - fix applied!"
else
    echo "✗ test/io/fixtures/big_schema.sql missing fuzzysearch schema - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_big_schema.py has fuzzy search performance test..."
if grep -q "test_second_request_for_non_existent_table_should_be_quick" "test/io/test_big_schema.py"; then
    echo "✓ test/io/test_big_schema.py has fuzzy search test - fix applied!"
else
    echo "✗ test/io/test_big_schema.py missing fuzzy search test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
