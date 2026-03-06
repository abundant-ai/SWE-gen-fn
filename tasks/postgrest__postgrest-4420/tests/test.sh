#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify the code changes for the fix to db-pre-config with reserved words
# In BASE state: uses dumpQi (doesn't quote identifiers)
# After fix: uses quoteQi (properly quotes identifiers)

test_status=0

echo "Checking src/PostgREST/AppState.hs for quoteQi usage..."
if grep -q "quoteQi <\$> configDbPreConfig" src/PostgREST/AppState.hs; then
    echo "✓ AppState.hs uses quoteQi - fix is applied!"
else
    echo "✗ AppState.hs does not use quoteQi - fix not applied"
    echo "Current queryDbSettings line:"
    grep "queryDbSettings" src/PostgREST/AppState.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/AppState.hs imports quoteQi..."
if grep -q "import PostgREST.SchemaCache.Identifiers (quoteQi)" src/PostgREST/AppState.hs; then
    echo "✓ AppState.hs imports quoteQi - fix is applied!"
else
    echo "✗ AppState.hs does not import quoteQi - fix not applied"
    echo "Current Identifiers import:"
    grep "PostgREST.SchemaCache.Identifiers" src/PostgREST/AppState.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Identifiers.hs exports quoteQi..."
if head -20 src/PostgREST/SchemaCache/Identifiers.hs | grep -q "quoteQi"; then
    echo "✓ Identifiers.hs exports quoteQi - fix is applied!"
else
    echo "✗ Identifiers.hs does not export quoteQi - fix not applied"
    echo "Current module exports:"
    head -20 src/PostgREST/SchemaCache/Identifiers.hs | grep -A10 "module PostgREST.SchemaCache.Identifiers" || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Identifiers.hs defines quoteQi function..."
if grep -q "^quoteQi :: QualifiedIdentifier -> Text" src/PostgREST/SchemaCache/Identifiers.hs; then
    echo "✓ Identifiers.hs defines quoteQi function - fix is applied!"
else
    echo "✗ Identifiers.hs does not define quoteQi function - fix not applied"
    test_status=1
fi

echo "Checking CHANGELOG.md for fix entry..."
if grep -q "Fix \`db-pre-config\` function failing when function names are pg reserved words" CHANGELOG.md; then
    echo "✓ CHANGELOG.md has fix entry - fix is applied!"
else
    echo "✗ CHANGELOG.md does not have fix entry - fix not applied"
    test_status=1
fi

echo "Checking test/io/fixtures.sql for 'true' function..."
if grep -q 'create or replace function "true"()' test/io/fixtures.sql; then
    echo "✓ fixtures.sql has 'true' function - fix is applied!"
else
    echo "✗ fixtures.sql does not have 'true' function - fix not applied"
    test_status=1
fi

echo "Checking test/io/test_io.py for test_db_pre_config_with_pg_reserved_words..."
if grep -q "def test_db_pre_config_with_pg_reserved_words" test/io/test_io.py; then
    echo "✓ test_io.py has test_db_pre_config_with_pg_reserved_words - fix is applied!"
else
    echo "✗ test_io.py does not have test_db_pre_config_with_pg_reserved_words - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "All code change checks passed - fix is applied!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
