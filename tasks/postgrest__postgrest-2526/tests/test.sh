#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for embedding views with multiple references to the same base column (PR #2526, issue #2459)..."
echo ""
echo "NOTE: This PR fixes embedding views where multiple view columns reference the same base table column."
echo "HEAD (fixed) should support keyDepCols as [(FieldName, [FieldName])] with array of view columns"
echo "BASE (buggy) only supports keyDepCols as [(FieldName, FieldName)] with single view column"
echo ""

# Check CHANGELOG.md - HEAD should mention #2459
echo "Checking CHANGELOG.md mentions #2459 fix..."
if grep -q "#2459, Fix embedding views with multiple references to the same base column" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2459"
else
    echo "✗ CHANGELOG.md missing #2459 entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should have detailed comment about ViewKeyDependency
echo "Checking src/PostgREST/SchemaCache.hs has detailed ViewKeyDependency comment..."
if grep -q "Each column of the key could be referenced multiple times in the view" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has detailed ViewKeyDependency comment"
else
    echo "✗ SchemaCache.hs doesn't have detailed comment - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has example with id_1, id_2, id_3..."
if grep -q "id as id_1" "src/PostgREST/SchemaCache.hs" && grep -q "id as id_2" "src/PostgREST/SchemaCache.hs" && grep -q "id as id_3" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has detailed example"
else
    echo "✗ SchemaCache.hs doesn't have detailed example - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has keyDepCols with array of FieldNames..."
if grep -q "keyDepCols  :: \[(FieldName, \[FieldName\])\]" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has keyDepCols :: [(FieldName, [FieldName])]"
else
    echo "✗ SchemaCache.hs doesn't have array type for keyDepCols - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs decodeViewKeyDeps uses compositeFieldArray..."
if grep -q "compositeFieldArray HD.text" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs decodeViewKeyDeps uses compositeFieldArray"
else
    echo "✗ SchemaCache.hs doesn't use compositeFieldArray - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs viewKeyDepFromRow has array type..."
if grep -q "viewKeyDepFromRow :: (Text,Text,Text,Text,Text,Text,\[(Text, \[Text\])\]) -> ViewKeyDependency" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs viewKeyDepFromRow has correct type signature"
else
    echo "✗ SchemaCache.hs viewKeyDepFromRow has wrong type signature - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has expandKeyDepCols function..."
if grep -q "expandKeyDepCols kdc = zip (fst <\$> kdc) <\$> sequenceA (snd <\$> kdc)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has expandKeyDepCols function"
else
    echo "✗ SchemaCache.hs doesn't have expandKeyDepCols function - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs addViewM2OAndO2ORels uses expandKeyDepCols..."
if grep -q "keyDepColsVwTbl <- expandKeyDepCols \$ keyDepCols vwTbl" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs addViewM2OAndO2ORels uses expandKeyDepCols for vwTbl"
else
    echo "✗ SchemaCache.hs doesn't use expandKeyDepCols - fix not applied"
    test_status=1
fi

if grep -q "keyDepColsTblVw <- expandKeyDepCols \$ keyDepCols tblVw" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs addViewM2OAndO2ORels uses expandKeyDepCols for tblVw"
else
    echo "✗ SchemaCache.hs doesn't use expandKeyDepCols for tblVw - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs addViewPrimaryKeys has takeFirstPK..."
if grep -q "takeFirstPK pkCols = catMaybes \$ head . snd <\$> pkCols" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs addViewPrimaryKeys has takeFirstPK function"
else
    echo "✗ SchemaCache.hs doesn't have takeFirstPK - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs allViewsKeyDependencies has repeated_references CTE..."
if grep -q "repeated_references as(" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs allViewsKeyDependencies has repeated_references CTE"
else
    echo "✗ SchemaCache.hs doesn't have repeated_references CTE - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs allViewsKeyDependencies uses array_agg(attname)..."
if grep -q "array_agg(attname) as view_columns" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses array_agg to collect view columns"
else
    echo "✗ SchemaCache.hs doesn't use array_agg - fix not applied"
    test_status=1
fi

# Check EmbedDisambiguationSpec.hs - HEAD should have test for composite key with multiple references
echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has test for composite key multiple references..."
if grep -q "errs with multiple references to the same composite key columns in a view" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs has composite key test"
else
    echo "✗ EmbedDisambiguationSpec.hs doesn't have composite key test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs references i2459_composite_v2..."
if grep -q "i2459_composite_v2" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs references i2459_composite_v2"
else
    echo "✗ EmbedDisambiguationSpec.hs doesn't reference i2459_composite_v2 - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has test for simple view column names..."
if grep -q "can specify all view column names that reference the same base column" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs has simple view column test"
else
    echo "✗ EmbedDisambiguationSpec.hs doesn't have column name test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs references i2459_simple_v1..."
if grep -q "i2459_simple_v1" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs references i2459_simple_v1"
else
    echo "✗ EmbedDisambiguationSpec.hs doesn't reference i2459_simple_v1 - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has test for self-referencing views..."
if grep -q "i2459_self_v1?select=\*,parent(\*),grandparent(\*)" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs has self-referencing view test"
else
    echo "✗ EmbedDisambiguationSpec.hs doesn't have self-referencing test - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should have i2459 test tables and views
echo "Checking test/spec/fixtures/schema.sql has issue #2459 reference..."
if grep -q "issue https://github.com/PostgREST/postgrest/issues/2459" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has issue #2459 reference"
else
    echo "✗ schema.sql doesn't have issue reference - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_simple_t1 and i2459_simple_t2 tables..."
if grep -q "create table public.i2459_simple_t1" "test/spec/fixtures/schema.sql" && grep -q "create table public.i2459_simple_t2" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_simple tables"
else
    echo "✗ schema.sql doesn't have i2459_simple tables - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_simple_v2 with t1_id1 and t1_id2..."
if grep -q "select t1_id as t1_id1, t1_id as t1_id2 from public.i2459_simple_t2" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_simple_v2 with multiple references"
else
    echo "✗ schema.sql doesn't have i2459_simple_v2 - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_composite tables..."
if grep -q "create table public.i2459_composite_t1" "test/spec/fixtures/schema.sql" && grep -q "create table public.i2459_composite_t2" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_composite tables"
else
    echo "✗ schema.sql doesn't have i2459_composite tables - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_composite_v2 with multiple column references..."
if grep -q "t1_a as t1_a1" "test/spec/fixtures/schema.sql" && grep -q "t1_a as t1_a2" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_composite_v2 with multiple references"
else
    echo "✗ schema.sql doesn't have i2459_composite_v2 - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_self_t table..."
if grep -q "create table public.i2459_self_t" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_self_t table"
else
    echo "✗ schema.sql doesn't have i2459_self_t - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has i2459_self_v1 and i2459_self_v2 views..."
if grep -q "create view i2459_self_v1 as" "test/spec/fixtures/schema.sql" && grep -q "create view i2459_self_v2 as" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has i2459_self views"
else
    echo "✗ schema.sql doesn't have i2459_self views - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - multiple references to same base column fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
