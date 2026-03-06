#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (domain type base_type fix applied)
# This is PR #4136 which ADDS the fix for proper base type handling of recursive domains
# HEAD state (e3627f74a5) = fix applied, uses cfBaseType for tsvector domain detection
# BASE state (with bug.patch) = broken (uses cfIRType or missing cfBaseType field)
# ORACLE state (BASE + fix.patch) = proper handling (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (domain base_type fix applied)..."
echo ""

echo "Checking that CoercibleField includes cfBaseType field..."
if grep -q "cfBaseType.*::.*Text" "src/PostgREST/Plan/Types.hs"; then
    echo "✓ CoercibleField includes cfBaseType field - fix applied!"
else
    echo "✗ CoercibleField does not include cfBaseType field - fix not applied"
    test_status=1
fi

echo "Checking that unknownField initializes cfBaseType..."
if grep -q 'unknownField name path = CoercibleField name path False Nothing "" "" Nothing Nothing False' "src/PostgREST/Plan/Types.hs"; then
    echo "✓ unknownField initializes cfBaseType - fix applied!"
else
    echo "✗ unknownField does not initialize cfBaseType - fix not applied"
    test_status=1
fi

echo "Checking that resolveColumnField passes colType as cfBaseType..."
if grep -q "CoercibleField (colName col) mempty False toTsV (colNominalType col) (colType col) Nothing (colDefault col) False" "src/PostgREST/Plan.hs"; then
    echo "✓ resolveColumnField passes colType as cfBaseType - fix applied!"
else
    echo "✗ resolveColumnField does not pass colType as cfBaseType - fix not applied"
    test_status=1
fi

echo "Checking that tsvector check uses cfBaseType instead of cfIRType..."
if grep -q 'cf@CoercibleField{cfBaseType="tsvector"}' "src/PostgREST/Plan.hs"; then
    echo "✓ tsvector check uses cfBaseType - fix applied!"
else
    echo "✗ tsvector check does not use cfBaseType - fix not applied"
    test_status=1
fi

echo "Checking that baseTypesCte function exists in SchemaCache..."
if grep -q "baseTypesCte :: Text" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ baseTypesCte function exists - fix applied!"
else
    echo "✗ baseTypesCte function does not exist - fix not applied"
    test_status=1
fi

echo "Checking that base_types CTE includes base_namespace and base_type columns..."
if grep -q "typnamespace AS base_namespace" "src/PostgREST/SchemaCache.hs" && grep -q "COALESCE(NULLIF(typbasetype, 0), oid) AS base_type" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ base_types CTE includes proper columns - fix applied!"
else
    echo "✗ base_types CTE does not include proper columns - fix not applied"
    test_status=1
fi

echo "Checking that tablesSqlQuery uses baseTypesCte..."
if grep -q '\$baseTypesCte,' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ tablesSqlQuery uses baseTypesCte - fix applied!"
else
    echo "✗ tablesSqlQuery does not use baseTypesCte - fix not applied"
    test_status=1
fi

echo "Checking that base_namespace is used in domain type handling..."
if grep -q 'WHEN bt.base_namespace = .pg_catalog.::regnamespace THEN format_type(bt.base_type' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ Domain type handling uses base_namespace - fix applied!"
else
    echo "✗ Domain type handling does not use base_namespace - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test files include tsvector domain tests..."
if grep -q "works when the column type is a tsvector domain" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec includes tsvector domain test - test from HEAD!"
else
    echo "✗ QuerySpec does not include tsvector domain test - test not from HEAD"
    test_status=1
fi

if grep -q "works when the column type is a recursive tsvector domain" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec includes recursive tsvector domain test - test from HEAD!"
else
    echo "✗ QuerySpec does not include recursive tsvector domain test - test not from HEAD"
    test_status=1
fi

echo "Checking that schema includes tsvector domain definitions..."
if grep -q "create domain tsvector_not_null as tsvector" "test/spec/fixtures/schema.sql"; then
    echo "✓ Schema includes tsvector_not_null domain - test from HEAD!"
else
    echo "✗ Schema does not include tsvector_not_null domain - test not from HEAD"
    test_status=1
fi

if grep -q "create domain tsvector_not_empty as tsvector_not_null" "test/spec/fixtures/schema.sql"; then
    echo "✓ Schema includes recursive tsvector_not_empty domain - test from HEAD!"
else
    echo "✗ Schema does not include recursive tsvector_not_empty domain - test not from HEAD"
    test_status=1
fi

echo "Checking that table includes tsvector domain columns..."
if grep -q "text_search_domain tsvector_not_null" "test/spec/fixtures/schema.sql"; then
    echo "✓ Table includes text_search_domain column - test from HEAD!"
else
    echo "✗ Table does not include text_search_domain column - test not from HEAD"
    test_status=1
fi

if grep -q "text_search_rec_domain tsvector_not_empty" "test/spec/fixtures/schema.sql"; then
    echo "✓ Table includes text_search_rec_domain column - test from HEAD!"
else
    echo "✗ Table does not include text_search_rec_domain column - test not from HEAD"
    test_status=1
fi

echo "Checking that data.sql populates tsvector domain columns..."
if grep -q "UPDATE tsearch_to_tsvector SET text_search_domain = to_tsvector" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql populates text_search_domain - test from HEAD!"
else
    echo "✗ data.sql does not populate text_search_domain - test not from HEAD"
    test_status=1
fi

if grep -q "UPDATE tsearch_to_tsvector SET text_search_rec_domain = to_tsvector" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql populates text_search_rec_domain - test from HEAD!"
else
    echo "✗ data.sql does not populate text_search_rec_domain - test not from HEAD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
