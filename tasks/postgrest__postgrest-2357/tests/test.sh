#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for OpenAPI regression with follow-privileges mode (PR #2357)..."
echo ""
echo "NOTE: This PR fixes a regression where tables were incorrectly filtered in OpenAPI output."
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking source code has the tablesSqlQuery function without Bool parameter (FIXED)..."
if [ -f "src/PostgREST/SchemaCache.hs" ] && grep -q "tablesSqlQuery :: PgVersion -> SqlQuery" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has FIXED tablesSqlQuery signature (without Bool parameter)"
else
    echo "✗ SchemaCache.hs missing FIXED tablesSqlQuery signature - fix not applied!"
    test_status=1
fi

echo "Checking accessibleTables returns AccessSet (FIXED) not TablesMap (BASE)..."
if [ -f "src/PostgREST/SchemaCache.hs" ] && grep -q "accessibleTables :: PgVersion -> Bool -> SQL.Statement \[Schema\] AccessSet" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has FIXED accessibleTables returning AccessSet"
else
    echo "✗ SchemaCache.hs missing FIXED accessibleTables signature!"
    test_status=1
fi

echo "Checking Query.hs imports Data.Set (FIXED) - BASE doesn't import it..."
if [ -f "src/PostgREST/Query.hs" ] && grep -q "^import qualified Data.Set" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs imports Data.Set (FIXED version)"
else
    echo "✗ Query.hs doesn't import Data.Set - fix not applied!"
    test_status=1
fi

echo "Checking Identifiers.hs has AccessSet type (FIXED) - BASE doesn't have it..."
if [ -f "src/PostgREST/SchemaCache/Identifiers.hs" ] && grep -q "type AccessSet" "src/PostgREST/SchemaCache/Identifiers.hs"; then
    echo "✓ Identifiers.hs defines AccessSet (FIXED version)"
else
    echo "✗ Identifiers.hs doesn't have AccessSet type - fix not applied!"
    test_status=1
fi

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#2356" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2356"
else
    echo "✗ CHANGELOG.md missing #2356 entry"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs has child_entities_view test..."
if [ -f "test/spec/Feature/OpenApi/OpenApiSpec.hs" ] && [ -s "test/spec/Feature/OpenApi/OpenApiSpec.hs" ]; then
    if grep -q "includes definitions to views" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
        echo "✓ OpenApiSpec.hs has 'includes definitions to views' test from HEAD"
    else
        echo "✗ OpenApiSpec.hs missing the test - HEAD file not copied!"
        test_status=1
    fi
else
    echo "✗ OpenApiSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs has HEAD enum format..."
if [ -f "test/spec/Feature/OpenApi/OpenApiSpec.hs" ] && grep -q '"format": "test.enum_menagerie_type"' "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs has HEAD enum format (with test. prefix)"
else
    echo "✗ OpenApiSpec.hs missing HEAD enum format"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has child_entities_view..."
if [ -f "test/spec/fixtures/schema.sql" ] && [ -s "test/spec/fixtures/schema.sql" ]; then
    if grep -q "create view child_entities_view" "test/spec/fixtures/schema.sql"; then
        echo "✓ schema.sql creates child_entities_view from HEAD"
    else
        echo "✗ schema.sql missing child_entities_view - HEAD file not copied!"
        test_status=1
    fi
else
    echo "✗ schema.sql missing or empty"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has child_entities_view comments..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q "comment on view child_entities_view" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has child_entities_view comments from HEAD"
else
    echo "✗ schema.sql missing child_entities_view comments - HEAD file not copied!"
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
