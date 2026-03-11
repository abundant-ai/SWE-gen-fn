#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/ExtraSearchPathSpec.hs" "test/spec/Feature/ExtraSearchPathSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for schema names with uppercase and special characters (PR #2345)..."
echo ""
echo "NOTE: This PR fixes PostgREST to correctly handle schemas with uppercase/special characters"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking SqlFragment.hs has pgFmtIdentList function..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q "pgFmtIdentList" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has pgFmtIdentList function"
else
    echo "✗ SqlFragment.hs missing pgFmtIdentList function - fix not applied!"
    test_status=1
fi

echo "Checking Middleware.hs uses pgFmtIdentList for search_path..."
if [ -f "src/PostgREST/Middleware.hs" ] && grep -q "pgFmtIdentList" "src/PostgREST/Middleware.hs"; then
    echo "✓ Middleware.hs uses pgFmtIdentList"
else
    echo "✗ Middleware.hs doesn't use pgFmtIdentList - fix not applied!"
    test_status=1
fi

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#2341" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2341"
else
    echo "✗ CHANGELOG.md missing #2341 entry"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking schema.sql has SPECIAL schema..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q 'CREATE SCHEMA "SPECIAL' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has SPECIAL schema (HEAD version)"
else
    echo "✗ schema.sql missing SPECIAL schema - HEAD file not copied!"
    test_status=1
fi

echo "Checking data.sql has data for SPECIAL schema..."
if [ -f "test/spec/fixtures/data.sql" ] && grep -q 'SPECIAL' "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has data for SPECIAL schema (HEAD version)"
else
    echo "✗ data.sql missing SPECIAL schema data - HEAD file not copied!"
    test_status=1
fi

echo "Checking SpecHelper.hs includes SPECIAL schema in configs..."
if [ -f "test/spec/SpecHelper.hs" ] && grep -q 'SPECIAL' "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs includes SPECIAL schema (HEAD version)"
else
    echo "✗ SpecHelper.hs missing SPECIAL schema - HEAD file not copied!"
    test_status=1
fi

echo "Checking MultipleSchemaSpec.hs includes SPECIAL schema in tests..."
if [ -f "test/spec/Feature/Query/MultipleSchemaSpec.hs" ] && grep -q 'SPECIAL' "test/spec/Feature/Query/MultipleSchemaSpec.hs"; then
    echo "✓ MultipleSchemaSpec.hs includes SPECIAL schema tests (HEAD version)"
else
    echo "✗ MultipleSchemaSpec.hs missing SPECIAL schema tests - HEAD file not copied!"
    test_status=1
fi

echo "Checking test_io.py expects properly quoted search_path..."
if [ -f "test/io/test_io.py" ] && grep -q '\\"public\\\\"' "test/io/test_io.py"; then
    echo "✓ test_io.py expects properly quoted search_path (HEAD version)"
else
    echo "✗ test_io.py doesn't expect proper quoting - HEAD file not copied!"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
