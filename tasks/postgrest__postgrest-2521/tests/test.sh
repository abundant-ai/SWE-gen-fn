#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for view PK/FK detection (PR #2521, issues #2518 and #2458)..."
echo ""
echo "NOTE: This PR fixes primary key and foreign key detection for views with multiple base tables."
echo "HEAD (fixed) should use concatMap/filter to collect all PKs, and order by attnum consistently"
echo "BASE (buggy) only uses maybe/find which returns only first PK, and has inconsistent ordering"
echo ""

# Check CHANGELOG.md - HEAD should mention #2518 and #2458
echo "Checking CHANGELOG.md mentions #2518 fix..."
if grep -q "#2518, Fix a regression when embedding views where base tables have a different column order for FK columns" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2518"
else
    echo "✗ CHANGELOG.md missing #2518 entry - fix not applied"
    test_status=1
fi

echo "Checking CHANGELOG.md mentions #2458 fix..."
if grep -q "#2458, Fix a regression with the location header when inserting into views with PKs from multiple tables" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2458"
else
    echo "✗ CHANGELOG.md missing #2458 entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should use concatMap/filter (not maybe/find)
echo "Checking src/PostgREST/SchemaCache.hs uses concatMap for finding view PK cols..."
if grep -q "concatMap (\\\\(ViewKeyDependency _ _ _ _ pkCols) -> snd <\$> pkCols)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses concatMap to collect all PK columns"
else
    echo "✗ SchemaCache.hs doesn't use concatMap - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs uses filter (not find)..."
if grep -q "filter (\\\\(ViewKeyDependency _ viewQi _ dep _) -> dep == PKDep && viewQi == QualifiedIdentifier sch vw) keyDeps" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses filter to find all matching key dependencies"
else
    echo "✗ SchemaCache.hs doesn't use filter - fix not applied"
    test_status=1
fi

# Check that BASE (buggy) version uses maybe/find (should NOT be in HEAD)
echo "Checking src/PostgREST/SchemaCache.hs does NOT use 'maybe []' pattern..."
if grep -q "maybe \\[\\] (\\\\(ViewKeyDependency _ _ _ _ pkCols) -> snd <\$> pkCols)" "src/PostgREST/SchemaCache.hs"; then
    echo "✗ SchemaCache.hs still uses maybe [] - fix not applied"
    test_status=1
else
    echo "✓ SchemaCache.hs correctly removed maybe [] pattern"
fi

# Check ordering changes - HEAD should order by ord (WITH ORDINALITY)
echo "Checking src/PostgREST/SchemaCache.hs allM2OandO2ORels uses 'order by ord'..."
if grep -q "array_agg(row(cols.attname, refs.attname) order by ord) AS cols_and_fcols" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses 'order by ord' in cols_and_fcols"
else
    echo "✗ SchemaCache.hs doesn't use 'order by ord' - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs uses 'WITH ORDINALITY'..."
if grep -q "FROM unnest(traint.conkey, traint.confkey) WITH ORDINALITY AS _(col, ref, ord)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses WITH ORDINALITY"
else
    echo "✗ SchemaCache.hs doesn't use WITH ORDINALITY - fix not applied"
    test_status=1
fi

# Check allViewsKeyDependencies uses ord column with WITH ORDINALITY
echo "Checking src/PostgREST/SchemaCache.hs allViewsKeyDependencies has 'ord' column..."
if grep -q "col as resorigcol," "src/PostgREST/SchemaCache.hs" && grep -q "ord" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs allViewsKeyDependencies includes ord column"
else
    echo "✗ SchemaCache.hs doesn't include ord column - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs uses 'with ordinality' in pks_fks CTE..."
if grep -q "left join lateral unnest(conkey) with ordinality as _(col, ord) on true" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses 'with ordinality' for conkey"
else
    echo "✗ SchemaCache.hs doesn't use 'with ordinality' - fix not applied"
    test_status=1
fi

if grep -q "left join lateral unnest(confkey) with ordinality as _(col, ord) on true" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses 'with ordinality' for confkey"
else
    echo "✗ SchemaCache.hs doesn't use 'with ordinality' for confkey - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs orders column_dependencies by pks_fks.ord..."
if grep -q "array_agg(row(col.attname, vcol.attname) order by pks_fks.ord) as column_dependencies" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs orders column_dependencies by pks_fks.ord"
else
    echo "✗ SchemaCache.hs doesn't order by pks_fks.ord - fix not applied"
    test_status=1
fi

# Check InsertSpec.hs - HEAD should have test for multiple PKs
echo "Checking test/spec/Feature/Query/InsertSpec.hs has test for multiple PKs location header..."
if grep -q 'it "returns a location header with pks from both tables"' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has multiple PKs test"
else
    echo "✗ InsertSpec.hs doesn't have multiple PKs test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/InsertSpec.hs references /with_multiple_pks endpoint..."
if grep -q "request methodPost \"/with_multiple_pks\"" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs references with_multiple_pks endpoint"
else
    echo "✗ InsertSpec.hs doesn't reference with_multiple_pks - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/InsertSpec.hs expects both pk1 and pk2 in Location header..."
if grep -q "\"Location\" <:> \"/with_multiple_pks?pk1=eq.1&pk2=eq.2\"" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs expects both pk1 and pk2 in Location header"
else
    echo "✗ InsertSpec.hs doesn't expect both PKs in Location - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/InsertSpec.hs test for null PK includes sponsor_id..."
if grep -q '"Location" <:> "/test_null_pk_competitors_sponsors?id=eq.1&sponsor_id=is.null"' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs includes sponsor_id in null PK test"
else
    echo "✗ InsertSpec.hs doesn't include sponsor_id - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/InsertSpec.hs has correct test description for null PK..."
if grep -q 'it "should not throw and return location header when a PK is null"' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has correct null PK test description"
else
    echo "✗ InsertSpec.hs doesn't have correct test description - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should have test for different column ordering
echo "Checking test/spec/Feature/Query/QuerySpec.hs has test for different column ordering..."
if grep -q 'it "works when embedding two views that refer to tables with different column ordering"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has different column ordering test"
else
    echo "✗ QuerySpec.hs doesn't have column ordering test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/QuerySpec.hs references v1 and v2 views..."
if grep -q 'get "/v1?select=v2(\*)"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs references v1 and v2 views"
else
    echo "✗ QuerySpec.hs doesn't reference v1/v2 views - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - view PK/FK detection fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
