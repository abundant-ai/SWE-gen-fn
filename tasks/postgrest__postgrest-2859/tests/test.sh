#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/JsonOperatorSpec.hs" "test/spec/Feature/Query/JsonOperatorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for jsonb/jsonb arrow filter and order using indexes..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2594, Fix unused index on jsonb/jsonb arrow filter and order' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that Plan.hs has the correct resolveColumnField signature (with cfToJson parameter)
echo "Checking src/PostgREST/Plan.hs for correct resolveColumnField..."
if grep -q 'resolveColumnField col = CoercibleField (colName col) mempty False (colNominalType col) Nothing (colDefault col)' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has correct resolveColumnField with cfToJson parameter"
else
    echo "✗ src/PostgREST/Plan.hs resolveColumnField signature changed - fix not applied"
    test_status=1
fi

# Check that resolveTableField properly handles json/jsonb types without wrapping in to_jsonb
echo "Checking src/PostgREST/Plan.hs for jsonb type handling..."
if grep -q 'cf@CoercibleField{cfIRType="json"}  -> cf{cfJsonPath=jp}' "src/PostgREST/Plan.hs" && \
   grep -q 'cf@CoercibleField{cfIRType="jsonb"} -> cf{cfJsonPath=jp}' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs properly handles json/jsonb types without to_jsonb conversion"
else
    echo "✗ src/PostgREST/Plan.hs json/jsonb handling changed - fix not applied"
    test_status=1
fi

# Check that the resolveOrder function exists with correct signature
echo "Checking src/PostgREST/Plan.hs for resolveOrder function..."
if grep -q 'resolveOrder :: ResolverContext -> OrderTerm -> CoercibleOrderTerm' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has resolveOrder function"
else
    echo "✗ src/PostgREST/Plan.hs missing resolveOrder function - fix not applied"
    test_status=1
fi

# Check that addOrders uses ResolverContext
echo "Checking src/PostgREST/Plan.hs for addOrders with ResolverContext..."
if grep -q 'addOrders :: ResolverContext -> ApiRequest -> ReadPlanTree -> Either ApiRequestError ReadPlanTree' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs addOrders has ResolverContext parameter"
else
    echo "✗ src/PostgREST/Plan.hs addOrders signature changed - fix not applied"
    test_status=1
fi

# Check that Types.hs has CoercibleField with cfToJson field
echo "Checking src/PostgREST/Plan/Types.hs for CoercibleField definition..."
if grep -q 'cfToJson' "src/PostgREST/Plan/Types.hs"; then
    echo "✓ src/PostgREST/Plan/Types.hs has cfToJson field in CoercibleField"
else
    echo "✗ src/PostgREST/Plan/Types.hs CoercibleField changed - fix not applied"
    test_status=1
fi

# Check that QueryBuilder.hs uses pgFmtColumn which handles to_jsonb conditionally
echo "Checking src/PostgREST/Query/QueryBuilder.hs for conditional to_jsonb..."
if grep -q 'pgFmtColumn' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs has pgFmtColumn usage"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs changed - fix not applied"
    test_status=1
fi

# Check that JsonOperatorSpec has the composite type filter test
echo "Checking test/spec/Feature/Query/JsonOperatorSpec.hs for composite type test..."
if grep -q 'can filter composite type field' "test/spec/Feature/Query/JsonOperatorSpec.hs"; then
    echo "✓ JsonOperatorSpec.hs has composite type filter test"
else
    echo "✗ JsonOperatorSpec.hs missing composite type test - fix not applied"
    test_status=1
fi

# Check schema.sql has the bets table with indexes
echo "Checking test/spec/fixtures/schema.sql for bets table..."
if grep -q 'create table bets' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bets table"
else
    echo "✗ schema.sql missing bets table - fix not applied"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql for bets indexes..."
if grep -q 'create index bets_data_json' "test/spec/fixtures/schema.sql" && \
   grep -q 'create index bets_data_jsonb' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bets table indexes"
else
    echo "✗ schema.sql missing bets table indexes - fix not applied"
    test_status=1
fi

# Check PlanSpec has index usage tests
echo "Checking test/spec/Feature/Query/PlanSpec.hs for index usage tests..."
if grep -q 'index usage' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has index usage context"
else
    echo "✗ PlanSpec.hs missing index usage tests - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/PlanSpec.hs for json arrow index test..."
if grep -q 'should use an index for a json arrow operator filter' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has json arrow filter index test"
else
    echo "✗ PlanSpec.hs missing json arrow filter test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/PlanSpec.hs for jsonb arrow index test..."
if grep -q 'should use an index for a jsonb arrow operator filter' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has jsonb arrow filter index test"
else
    echo "✗ PlanSpec.hs missing jsonb arrow filter test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/PlanSpec.hs for json order index test..."
if grep -q 'should use an index for ordering on a json arrow operator' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has json arrow order index test"
else
    echo "✗ PlanSpec.hs missing json arrow order test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/PlanSpec.hs for jsonb order index test..."
if grep -q 'should use an index for ordering on a jsonb arrow operator' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has jsonb arrow order index test"
else
    echo "✗ PlanSpec.hs missing jsonb arrow order test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
