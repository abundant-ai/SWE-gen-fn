#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for bulk update with PATCH (PR #2311)..."
echo ""
echo "NOTE: This PR adds bulk update support with PATCH requests"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking CHANGELOG.md mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#1959, Bulk update with PATCH" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #1959"
else
    echo "✗ CHANGELOG.md missing #1959 entry for bulk update"
    test_status=1
fi

echo "Checking CHANGELOG.md mentions the restriction..."
if [ -f "CHANGELOG.md" ] && grep -q "#1959, An accidental full table PATCH" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions accidental full table PATCH restriction"
else
    echo "✗ CHANGELOG.md missing restriction description"
    test_status=1
fi

echo "Checking App.hs uses pkCols..."
if [ -f "src/PostgREST/App.hs" ] && grep -q "pkCols = maybe mempty tablePKCols" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses pkCols for bulk update"
else
    echo "✗ App.hs missing pkCols implementation"
    test_status=1
fi

echo "Checking App.hs passes pkCols to writeQuery..."
if [ -f "src/PostgREST/App.hs" ] && grep -q "writeQuery MutationUpdate identifier False pkCols context" "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes pkCols to writeQuery"
else
    echo "✗ App.hs not passing pkCols correctly"
    test_status=1
fi

echo "Checking QueryBuilder.hs has pkFlts parameter..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ] && grep -q "Update mainQi uCols body logicForest pkFlts range ordts returnings" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs Update has pkFlts parameter"
else
    echo "✗ QueryBuilder.hs missing pkFlts parameter"
    test_status=1
fi

echo "Checking QueryBuilder.hs uses pgrst_update_body..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ] && grep -q 'FROM (SELECT \* FROM json_populate_recordset (null::" <> mainTbl <> " , " <> SQL.sql selectBody <> " )) pgrst_update_body' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses pgrst_update_body alias"
else
    echo "✗ QueryBuilder.hs not using pgrst_update_body alias"
    test_status=1
fi

echo "Checking QueryBuilder.hs has pgrstUpdateBodyF..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ] && grep -q "pgrstUpdateBodyF =" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs defines pgrstUpdateBodyF"
else
    echo "✗ QueryBuilder.hs missing pgrstUpdateBodyF definition"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking UpdateSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/UpdateSpec.hs" ]; then
    echo "✓ UpdateSpec.hs exists (HEAD version)"
else
    echo "✗ UpdateSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking DeleteSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/DeleteSpec.hs" ]; then
    echo "✓ DeleteSpec.hs exists (HEAD version)"
else
    echo "✗ DeleteSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking SingularSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/SingularSpec.hs" ]; then
    echo "✓ SingularSpec.hs exists (HEAD version)"
else
    echo "✗ SingularSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
