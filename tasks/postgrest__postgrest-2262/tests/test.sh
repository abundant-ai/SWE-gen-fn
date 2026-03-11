#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/big_schema.sql" "test/io/big_schema.sql"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for many-to-many relationship restriction (PR #2262)..."
echo ""
echo "NOTE: This PR restricts m2m relationships to only be generated when FK columns are part of PK"
echo "We verify that the source code has the fix."
echo ""

echo "Checking DbStructure.hs imports Data.Set..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "import qualified Data.Set" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs imports Data.Set"
else
    echo "✗ DbStructure.hs missing Data.Set import"
    test_status=1
fi

echo "Checking addM2MRels function signature takes TablesMap parameter..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "addM2MRels :: TablesMap -> \[Relationship\] -> \[Relationship\]" "src/PostgREST/DbStructure.hs"; then
    echo "✓ addM2MRels has correct signature with TablesMap parameter"
else
    echo "✗ addM2MRels signature not updated to take TablesMap"
    test_status=1
fi

echo "Checking addM2MRels uses S.fromList for junction columns..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "jtCols = S.fromList" "src/PostgREST/DbStructure.hs"; then
    echo "✓ addM2MRels creates set from junction columns"
else
    echo "✗ addM2MRels not using S.fromList for junction columns"
    test_status=1
fi

echo "Checking addM2MRels uses S.fromList for primary key columns..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "pkCols = S.fromList" "src/PostgREST/DbStructure.hs"; then
    echo "✓ addM2MRels creates set from primary key columns"
else
    echo "✗ addM2MRels not using S.fromList for primary key columns"
    test_status=1
fi

echo "Checking addM2MRels uses S.isSubsetOf to validate FK columns in PK..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "S.isSubsetOf jtCols pkCols" "src/PostgREST/DbStructure.hs"; then
    echo "✓ addM2MRels checks if FK columns are subset of PK columns"
else
    echo "✗ addM2MRels not checking subset relationship"
    test_status=1
fi

echo "Checking addM2MRels call site passes TablesMap..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "addM2MRels tabsWViewsPks" "src/PostgREST/DbStructure.hs"; then
    echo "✓ addM2MRels called with TablesMap argument"
else
    echo "✗ addM2MRels not called with TablesMap argument"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking big_schema.sql was copied..."
if [ -f "test/io/big_schema.sql" ]; then
    echo "✓ big_schema.sql exists (HEAD version)"
else
    echo "✗ big_schema.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking QuerySpec.hs was copied..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ]; then
    echo "✓ QuerySpec.hs exists (HEAD version)"
else
    echo "✗ QuerySpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking privileges.sql was copied..."
if [ -f "test/spec/fixtures/privileges.sql" ]; then
    echo "✓ privileges.sql exists (HEAD version)"
else
    echo "✗ privileges.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking schema.sql was copied..."
if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
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
