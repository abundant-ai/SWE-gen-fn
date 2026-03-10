#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for embedding the same table multiple times (PR #2519, issues #2428 and #2455)..."
echo ""
echo "NOTE: This PR fixes SQL alias collisions when embedding the same table multiple times,"
echo "especially with computed relationships and deep nesting."
echo "HEAD (fixed) should use unique aliases and proper parent-row references for computed relationships"
echo "BASE (buggy) reuses aliases causing 'table name specified more than once' errors"
echo ""

# Check CHANGELOG.md - HEAD should mention #2428 and #2455
echo "Checking CHANGELOG.md mentions #2428 fix..."
if grep -q "#2428, Fix opening an empty transaction on failed resource embedding" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2428"
else
    echo "✗ CHANGELOG.md missing #2428 entry - fix not applied"
    test_status=1
fi

echo "Checking CHANGELOG.md mentions #2455 fix..."
if grep -q "#2455, Fix embedding the same table multiple times" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2455"
else
    echo "✗ CHANGELOG.md missing #2455 entry - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should NOT have JoinCondition (it was removed)
echo "Checking src/PostgREST/ApiRequest/Types.hs does NOT export JoinCondition..."
if grep -q "JoinCondition(..)" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✗ ApiRequest/Types.hs still exports JoinCondition - fix not applied"
    test_status=1
else
    echo "✓ ApiRequest/Types.hs correctly removed JoinCondition export"
fi

echo "Checking src/PostgREST/ApiRequest/Types.hs does NOT define JoinCondition data type..."
if grep -q "^data JoinCondition" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✗ ApiRequest/Types.hs still has JoinCondition data type - fix not applied"
    test_status=1
else
    echo "✓ ApiRequest/Types.hs correctly removed JoinCondition data type"
fi

echo "Checking src/PostgREST/ApiRequest/Types.hs does NOT import QualifiedIdentifier..."
if grep -q "FieldName," "src/PostgREST/ApiRequest/Types.hs" && grep -q "QualifiedIdentifier)" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✗ ApiRequest/Types.hs still has extra QualifiedIdentifier import - fix not applied"
    test_status=1
else
    echo "✓ ApiRequest/Types.hs correctly cleaned up imports"
fi

# Check Plan.hs - HEAD should use addRels (not augmentRequestWithJoin which was in BASE)
echo "Checking src/PostgREST/Plan.hs uses addRels..."
if grep -q "addRels qiSchema (iAction apiRequest) dbRelationships Nothing" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses addRels"
else
    echo "✗ Plan.hs doesn't use addRels - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs does NOT use augmentRequestWithJoin..."
if grep -q "augmentRequestWithJoin qiSchema dbRelationships" "src/PostgREST/Plan.hs"; then
    echo "✗ Plan.hs still uses augmentRequestWithJoin - fix not applied"
    test_status=1
else
    echo "✓ Plan.hs correctly removed augmentRequestWithJoin"
fi

# Check initReadRequest - HEAD should be simple (just QualifiedIdentifier)
echo "Checking src/PostgREST/Plan.hs has simple initReadRequest call..."
if grep -q "initReadRequest qi" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has simple initReadRequest call"
else
    echo "✗ Plan.hs doesn't have simple initReadRequest call - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs does NOT have rootName/rootAlias pattern..."
if grep -q "initReadRequest rootName rootAlias" "src/PostgREST/Plan.hs"; then
    echo "✗ Plan.hs still has rootName/rootAlias pattern - fix not applied"
    test_status=1
else
    echo "✓ Plan.hs correctly removed rootName/rootAlias pattern"
fi

# Check Plan.hs has Action parameter in addRels (internal function, not exported)
echo "Checking src/PostgREST/Plan.hs has Action parameter in addRels signature..."
if grep -q "addRels :: Schema -> Action ->" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has updated addRels signature with Action"
else
    echo "✗ Plan.hs doesn't have Action in addRels signature - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs has getJoinConditions function..."
if grep -q "getJoinConditions :: Maybe Alias -> Maybe Alias -> Relationship" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has getJoinConditions function"
else
    echo "✗ Plan.hs missing getJoinConditions - fix not applied"
    test_status=1
fi

# Check Plan/ReadPlan.hs has JoinCondition type (in exports and data definition)
echo "Checking src/PostgREST/Plan/ReadPlan.hs exports JoinCondition..."
if grep -q "JoinCondition(..)" "src/PostgREST/Plan/ReadPlan.hs"; then
    echo "✓ ReadPlan.hs exports JoinCondition"
else
    echo "✗ ReadPlan.hs doesn't export JoinCondition - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - verify it uses relJoinConds (part of the fixed structure)
echo "Checking src/PostgREST/Query/QueryBuilder.hs uses relJoinConds..."
if grep -q "relJoinConds" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses relJoinConds"
else
    echo "✗ QueryBuilder.hs doesn't use relJoinConds - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs changes
echo "Checking src/PostgREST/Query/SqlFragment.hs has updates..."
if grep -q "sourceCTEName ::" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has sourceCTEName"
else
    echo "✗ SqlFragment.hs missing sourceCTEName - fix not applied"
    test_status=1
fi

# Verify test files exist and have proper content
echo "Checking test/spec/Feature/Query/ComputedRelsSpec.hs exists..."
if [ -f "test/spec/Feature/Query/ComputedRelsSpec.hs" ]; then
    echo "✓ ComputedRelsSpec.hs exists"
else
    echo "✗ ComputedRelsSpec.hs missing"
    test_status=1
fi

echo "Checking test/spec/fixtures/schema.sql has necessary tables/functions..."
if grep -q "CREATE TABLE" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has table definitions"
else
    echo "✗ schema.sql missing table definitions"
    test_status=1
fi

echo "Checking test/spec/fixtures/privileges.sql exists..."
if [ -f "test/spec/fixtures/privileges.sql" ]; then
    echo "✓ privileges.sql exists"
else
    echo "✗ privileges.sql missing"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - embedding same table multiple times fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
