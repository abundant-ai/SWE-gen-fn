#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for M2M embedding on RPC (PR #2568)..."
echo ""
echo "NOTE: This PR fixes bad M2M embedding on RPC by properly handling junction table columns"
echo "HEAD (fixed) should use junColsSource/junColsTarget and handle both column sets for M2M"
echo "BASE (buggy) uses junColumns1/junColumns2 incorrectly, causing embed failures"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for M2M embedding fix
echo "Checking CHANGELOG.md mentions M2M embedding fix..."
if grep -q "#2565, Fix bad M2M embedding on RPC" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions M2M embedding fix"
else
    echo "✗ CHANGELOG.md missing M2M embedding fix entry - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should use junColsSource and junColsTarget (not junColumns1/junColumns2)
echo "Checking src/PostgREST/Error.hs uses junColsSource and junColsTarget..."
if grep -q "junColsSource" "src/PostgREST/Error.hs" && grep -q "junColsTarget" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses junColsSource and junColsTarget"
else
    echo "✗ Error.hs not using correct junction column names - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use inferColsEmbedNeeds (not returningCols)
echo "Checking src/PostgREST/Plan.hs uses inferColsEmbedNeeds..."
if grep -q "inferColsEmbedNeeds readReq pkCols" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses inferColsEmbedNeeds"
else
    echo "✗ Plan.hs not using inferColsEmbedNeeds - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have inferColsEmbedNeeds function (not returningCols)
echo "Checking src/PostgREST/Plan.hs defines inferColsEmbedNeeds function..."
if grep -q "inferColsEmbedNeeds :: ReadPlanTree" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs defines inferColsEmbedNeeds function"
else
    echo "✗ Plan.hs missing inferColsEmbedNeeds function - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use pattern matching on select parameter with lambda (not fstFieldNames)
echo "Checking src/PostgREST/Plan.hs inferColsEmbedNeeds uses direct pattern matching..."
if grep -A10 "inferColsEmbedNeeds (Node ReadPlan{select} forest)" "src/PostgREST/Plan.hs" | grep -q 'fldNames = .*fld.*select'; then
    echo "✓ Plan.hs inferColsEmbedNeeds uses direct pattern matching"
else
    echo "✗ Plan.hs inferColsEmbedNeeds not using correct pattern - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use junColsSource (not junColumns1/junColumns2)
echo "Checking src/PostgREST/Plan.hs uses junColsSource for M2M..."
if grep -q "junColsSource=cols" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses junColsSource"
else
    echo "✗ Plan.hs not using junColsSource - fix not applied"
    test_status=1
fi

# Check ReadPlan.hs - HEAD should NOT export fstFieldNames
echo "Checking src/PostgREST/Plan/ReadPlan.hs does not export fstFieldNames..."
if ! grep -q "fstFieldNames" "src/PostgREST/Plan/ReadPlan.hs"; then
    echo "✓ ReadPlan.hs does not export fstFieldNames"
else
    echo "✗ ReadPlan.hs still has fstFieldNames - fix not applied"
    test_status=1
fi

# Check ReadPlan.hs - HEAD should NOT have NamedFieldPuns extension
echo "Checking src/PostgREST/Plan/ReadPlan.hs does not use NamedFieldPuns..."
if ! grep -q "NamedFieldPuns" "src/PostgREST/Plan/ReadPlan.hs"; then
    echo "✓ ReadPlan.hs does not use NamedFieldPuns"
else
    echo "✗ ReadPlan.hs still has NamedFieldPuns - fix not applied"
    test_status=1
fi

# Check Relationship.hs - HEAD should use junColsSource and junColsTarget (not junColumns1/junColumns2)
echo "Checking src/PostgREST/SchemaCache/Relationship.hs uses junColsSource and junColsTarget..."
if grep -q "junColsSource.*::" "src/PostgREST/SchemaCache/Relationship.hs" && grep -q "junColsTarget.*::" "src/PostgREST/SchemaCache/Relationship.hs"; then
    echo "✓ Relationship.hs uses junColsSource and junColsTarget"
else
    echo "✗ Relationship.hs not using correct junction column names - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should HAVE the test case for get_yards with groups (issue #2565)
echo "Checking test/spec/Feature/Query/RpcSpec.hs has get_yards test..."
if grep -q "get_yards" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has get_yards test"
else
    echo "✗ RpcSpec.hs missing get_yards test - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should have M2M embedding test
echo "Checking test/spec/Feature/Query/RpcSpec.hs has M2M embedding test..."
if grep -q "can embed an M2M relationship table" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has M2M embedding test"
else
    echo "✗ RpcSpec.hs missing M2M embedding test - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should HAVE groups, yards, group_yard tables and get_yards function (test fixtures for issue #2565)
echo "Checking test/spec/fixtures/schema.sql has groups/yards tables..."
if grep -q "CREATE TABLE test.groups" "test/spec/fixtures/schema.sql" && \
   grep -q "CREATE TABLE test.yards" "test/spec/fixtures/schema.sql" && \
   grep -q "CREATE TABLE test.group_yard" "test/spec/fixtures/schema.sql" && \
   grep -q "CREATE FUNCTION test.get_yards" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has test groups/yards/group_yard/get_yards"
else
    echo "✗ schema.sql missing test tables/functions - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - M2M embedding fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
