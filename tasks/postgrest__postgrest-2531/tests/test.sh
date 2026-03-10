#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for infinite recursion with self-referencing views (PR #2531)..."
echo ""
echo "NOTE: This PR fixes infinite recursion when loading schema cache with self-referencing views."
echo "HEAD (fixed) should have CYCLE detection logic with is_cycle and path tracking"
echo "BASE (buggy) lacks CYCLE detection and can recurse infinitely"
echo ""

# Check CHANGELOG.md - HEAD should have both #2356 and #2283 entries
echo "Checking CHANGELOG.md mentions #2356 fix..."
if grep -q "#2356, Fix a regression in openapi output with mode follow-privileges" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2356"
else
    echo "✗ CHANGELOG.md missing #2356 entry - fix not applied"
    test_status=1
fi

echo "Checking CHANGELOG.md mentions #2283 fix..."
if grep -q "#2283, Fix infinite recursion when loading schema cache with self-referencing view" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2283"
else
    echo "✗ CHANGELOG.md missing #2283 entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should have CYCLE detection with is_cycle and path
echo "Checking src/PostgREST/SchemaCache.hs has CYCLE detection comment..."
if grep -q "CYCLE detection according to PG docs" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has CYCLE detection comment"
else
    echo "✗ SchemaCache.hs doesn't have CYCLE detection comment - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has is_cycle field in recursion CTE..."
if grep -q "recursion(view_id, view_schema, view_name, view_column, resorigtbl, resorigcol, is_cycle, path)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has is_cycle field in recursion CTE"
else
    echo "✗ SchemaCache.hs doesn't have is_cycle field - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has path tracking with ARRAY[resorigtbl]..."
if grep -q "ARRAY\[resorigtbl\]" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has path tracking initialization"
else
    echo "✗ SchemaCache.hs doesn't have path tracking - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has is_cycle calculation..."
if grep -q "tab.resorigtbl = ANY(path)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has is_cycle calculation"
else
    echo "✗ SchemaCache.hs doesn't have is_cycle calculation - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has path concatenation..."
if grep -q "path || tab.resorigtbl" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has path concatenation"
else
    echo "✗ SchemaCache.hs doesn't have path concatenation - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has 'where not is_cycle' clause..."
if grep -q "where not is_cycle" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has 'where not is_cycle' clause"
else
    echo "✗ SchemaCache.hs doesn't have 'where not is_cycle' clause - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should have AccessSet import and decodeAccessibleIdentifiers
echo "Checking src/PostgREST/SchemaCache.hs imports AccessSet..."
if grep -q "AccessSet, FieldName" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs imports AccessSet"
else
    echo "✗ SchemaCache.hs doesn't import AccessSet - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has decodeAccessibleIdentifiers function..."
if grep -q "decodeAccessibleIdentifiers :: HD.Result AccessSet" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has decodeAccessibleIdentifiers function"
else
    echo "✗ SchemaCache.hs doesn't have decodeAccessibleIdentifiers function - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs accessibleTables returns AccessSet..."
if grep -q "accessibleTables :: PgVersion -> Bool -> SQL.Statement \[Schema\] AccessSet" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs accessibleTables returns AccessSet"
else
    echo "✗ SchemaCache.hs accessibleTables doesn't return AccessSet - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs accessibleTables uses decodeAccessibleIdentifiers..."
if grep -q "SQL.Statement sql (arrayParam HE.text) decodeAccessibleIdentifiers" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs accessibleTables uses decodeAccessibleIdentifiers"
else
    echo "✗ SchemaCache.hs accessibleTables doesn't use decodeAccessibleIdentifiers - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - tablesSqlQuery should NOT have getAll parameter
echo "Checking src/PostgREST/SchemaCache.hs tablesSqlQuery doesn't have getAll parameter..."
if grep -q "tablesSqlQuery :: PgVersion -> SqlQuery" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs tablesSqlQuery has correct signature"
else
    echo "✗ SchemaCache.hs tablesSqlQuery has wrong signature - fix not applied"
    test_status=1
fi

# Check Identifiers.hs - HEAD should have AccessSet type
echo "Checking src/PostgREST/SchemaCache/Identifiers.hs exports AccessSet..."
if grep -q ", AccessSet" "src/PostgREST/SchemaCache/Identifiers.hs"; then
    echo "✓ Identifiers.hs exports AccessSet"
else
    echo "✗ Identifiers.hs doesn't export AccessSet - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Identifiers.hs imports Data.Set..."
if grep -q "import qualified Data.Set   as S" "src/PostgREST/SchemaCache/Identifiers.hs"; then
    echo "✓ Identifiers.hs imports Data.Set"
else
    echo "✗ Identifiers.hs doesn't import Data.Set - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Identifiers.hs defines AccessSet type..."
if grep -q "type AccessSet = S.Set QualifiedIdentifier" "src/PostgREST/SchemaCache/Identifiers.hs"; then
    echo "✓ Identifiers.hs defines AccessSet type"
else
    echo "✗ Identifiers.hs doesn't define AccessSet type - fix not applied"
    test_status=1
fi

# Check Query.hs - HEAD should import Data.Set and use it in openApiQuery
echo "Checking src/PostgREST/Query.hs imports Data.Set..."
if grep -q "import qualified Data.Set                          as S" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs imports Data.Set"
else
    echo "✗ Query.hs doesn't import Data.Set - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Query.hs uses tableAccess variable in openApiQuery..."
if grep -q "tableAccess <- SQL.statement \[tSchema\] (SchemaCache.accessibleTables pgVer configDbPreparedStatements)" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has tableAccess variable"
else
    echo "✗ Query.hs doesn't have tableAccess variable - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Query.hs filters tables with S.member..."
if grep -q "HM.filterWithKey (\\\\qi _ -> S.member qi tableAccess)" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs filters tables with S.member"
else
    echo "✗ Query.hs doesn't filter with S.member - fix not applied"
    test_status=1
fi

# Check OpenApiSpec.hs - HEAD should have the "includes definitions to views" test
echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs has 'includes definitions to views' test..."
if grep -q "includes definitions to views" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs has 'includes definitions to views' test"
else
    echo "✗ OpenApiSpec.hs doesn't have 'includes definitions to views' test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs references child_entities_view..."
if grep -q "child_entities_view" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs references child_entities_view"
else
    echo "✗ OpenApiSpec.hs doesn't reference child_entities_view - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should have child_entities_view and self_recursive_view
echo "Checking test/spec/fixtures/schema.sql has child_entities_view..."
if grep -q "create view child_entities_view as table child_entities" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has child_entities_view"
else
    echo "✗ schema.sql doesn't have child_entities_view - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has comments on child_entities_view..."
if grep -q "comment on view child_entities_view is 'child_entities_view comment'" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has comments on child_entities_view"
else
    echo "✗ schema.sql doesn't have comments on child_entities_view - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has self_recursive_view (issue #2283)..."
if grep -q "issue https://github.com/PostgREST/postgrest/issues/2283" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has issue reference for #2283"
else
    echo "✗ schema.sql doesn't have issue reference - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql creates self_recursive_view from projects..."
if grep -q "create view self_recursive_view as table projects" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql creates self_recursive_view from projects"
else
    echo "✗ schema.sql doesn't create self_recursive_view from projects - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql replaces self_recursive_view to reference itself..."
if grep -q "create or replace view self_recursive_view as table self_recursive_view" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql replaces self_recursive_view to reference itself"
else
    echo "✗ schema.sql doesn't replace self_recursive_view - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - infinite recursion fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
