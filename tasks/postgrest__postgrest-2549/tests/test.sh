#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for hidden FKs in views with partial column references (PR #2549)..."
echo ""
echo "NOTE: This PR fixes an issue where PostgREST exposed foreign-key relationships"
echo "that are only partially visible through views, causing ambiguity errors."
echo "HEAD (fixed) should filter out partial FK relationships properly"
echo "BASE (buggy) exposes all FKs regardless of column visibility"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for hidden FK fix
echo "Checking CHANGELOG.md mentions hidden FK regression fix..."
if grep -q "#2548, Fix regression when embedding views with partial references to multi column FKs" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions hidden FK fix"
else
    echo "✗ CHANGELOG.md missing hidden FK fix entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should include ncol calculation for conkey
echo "Checking src/PostgREST/SchemaCache.hs includes array_length(conkey, 1) as ncol..."
if grep -A 3 "contype::text as contype," "src/PostgREST/SchemaCache.hs" | grep -q "array_length(conkey, 1) as ncol"; then
    echo "✓ SchemaCache.hs includes ncol calculation for conkey"
else
    echo "✗ SchemaCache.hs missing ncol calculation for conkey - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should include ncol calculation for confkey
echo "Checking src/PostgREST/SchemaCache.hs includes array_length(confkey, 1) as ncol..."
if grep -A 3 "concat(contype, '_ref') as contype," "src/PostgREST/SchemaCache.hs" | grep -q "array_length(confkey, 1) as ncol"; then
    echo "✓ SchemaCache.hs includes ncol calculation for confkey"
else
    echo "✗ SchemaCache.hs missing ncol calculation for confkey - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should include ncol in GROUP BY clause
echo "Checking src/PostgREST/SchemaCache.hs includes pks_fks.ncol in GROUP BY..."
if grep -q "group by sch.nspname, tbl.relname,  rep.view_schema, rep.view_name, pks_fks.conname, pks_fks.contype, pks_fks.ncol" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs includes ncol in GROUP BY"
else
    echo "✗ SchemaCache.hs missing ncol in GROUP BY - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should include HAVING clause to filter partial FKs
echo "Checking src/PostgREST/SchemaCache.hs includes HAVING clause..."
if grep -q "having ncol = array_length(array_agg(row(col.attname, view_columns) order by pks_fks.ord), 1)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs includes HAVING clause to filter partial FKs"
else
    echo "✗ SchemaCache.hs missing HAVING clause - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should have the comment about filtering partial PKs/FKs
echo "Checking src/PostgREST/SchemaCache.hs has comment about filtering partial PKs/FKs..."
if grep -q "make sure we only return key for which all columns are referenced in the view - no partial PKs or FKs" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has explanatory comment"
else
    echo "✗ SchemaCache.hs missing explanatory comment - fix not applied"
    test_status=1
fi

# Check EmbedDisambiguationSpec.hs - HEAD should HAVE the test case for hidden FKs
echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has hidden FK test..."
if grep -q "should not expose hidden FKs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs has hidden FK test case"
else
    echo "✗ EmbedDisambiguationSpec.hs missing hidden FK test case - fix not applied"
    test_status=1
fi

# Check that the test actually checks for /va?select=vb(*)
echo "Checking EmbedDisambiguationSpec.hs test verifies /va?select=vb(*) endpoint..."
if grep -q 'get "/va?select=vb(\*)"' "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs test checks /va?select=vb(*)"
else
    echo "✗ EmbedDisambiguationSpec.hs test doesn't check correct endpoint - fix not applied"
    test_status=1
fi

# Check that the test expects 200 status (successful embed without ambiguity)
echo "Checking EmbedDisambiguationSpec.hs test expects 200 status..."
if grep -A 1 'get "/va?select=vb(\*)"' "test/spec/Feature/Query/EmbedDisambiguationSpec.hs" | grep -q "shouldRespondWith.*200"; then
    echo "✓ EmbedDisambiguationSpec.hs test expects 200 status"
else
    echo "✗ EmbedDisambiguationSpec.hs test doesn't expect 200 status - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should HAVE the test tables/views for issue #2548
echo "Checking test/spec/fixtures/schema.sql has test tables for issue #2548..."
if grep -q "issue https://github.com/PostgREST/postgrest/issues/2548" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has test setup for issue #2548"
else
    echo "✗ schema.sql missing test setup - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should create table ta with composite unique constraint
echo "Checking test/spec/fixtures/schema.sql creates table ta..."
if grep -q "CREATE TABLE public.ta" "test/spec/fixtures/schema.sql" && \
   grep -A 3 "CREATE TABLE public.ta" "test/spec/fixtures/schema.sql" | grep -q "UNIQUE (a1, a2)"; then
    echo "✓ schema.sql creates table ta with composite unique constraint"
else
    echo "✗ schema.sql missing table ta setup - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should create table tb with composite FK
echo "Checking test/spec/fixtures/schema.sql creates table tb with composite FK..."
if grep -q "CREATE TABLE public.tb" "test/spec/fixtures/schema.sql" && \
   grep -A 4 "CREATE TABLE public.tb" "test/spec/fixtures/schema.sql" | grep -q "FOREIGN KEY (b1, b2) REFERENCES public.ta (a1, a2)"; then
    echo "✓ schema.sql creates table tb with composite FK"
else
    echo "✗ schema.sql missing table tb setup - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should create views va and vb with partial columns
echo "Checking test/spec/fixtures/schema.sql creates views va and vb..."
if grep -q "CREATE VIEW test.va AS SELECT a1 FROM public.ta" "test/spec/fixtures/schema.sql" && \
   grep -q "CREATE VIEW test.vb AS SELECT b1 FROM public.tb" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql creates views va and vb with partial columns"
else
    echo "✗ schema.sql missing views va/vb - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - hidden FK fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
