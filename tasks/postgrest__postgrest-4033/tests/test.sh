#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4033 which fixes filter on unselected columns in table-valued functions
# HEAD state (0b9aa1e1) = fix applied, has funCFilterFields and getFilterFieldNames
# BASE state (with bug.patch) = no funCFilterFields, no getFilterFieldNames function
# ORACLE state (BASE + fix.patch) = has funCFilterFields and getFilterFieldNames

test_status=0

echo "Verifying source code matches HEAD state (RPC filter fix)..."
echo ""

echo "Checking that CHANGELOG.md has the fix entry..."
if grep -q "#3965, Fix filter on unselected columns in a table-valued function" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CallPlan.hs has funCFilterFields field..."
if grep -q "funCFilterFields" "src/PostgREST/Plan/CallPlan.hs"; then
    echo "✓ CallPlan.hs has funCFilterFields - fix applied!"
else
    echo "✗ CallPlan.hs does not have funCFilterFields - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has funCFilterFields assignment..."
if grep -q "funCFilterFields = getFilterFieldNames readReq" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has funCFilterFields assignment - fix applied!"
else
    echo "✗ Plan.hs does not have funCFilterFields assignment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has getFilterFieldNames function..."
if grep -q "getFilterFieldNames :: ReadPlanTree -> Set FieldName" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has getFilterFieldNames function - fix applied!"
else
    echo "✗ Plan.hs does not have getFilterFieldNames function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has rpToFieldNames helper..."
if grep -q "rpToFieldNames :: ReadPlan -> \[FieldName\]" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has rpToFieldNames helper - fix applied!"
else
    echo "✗ Plan.hs does not have rpToFieldNames helper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has logicTreesToFieldName helper..."
if grep -q "logicTreesToFieldName :: \[CoercibleLogicTree\] -> \[FieldName\]" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has logicTreesToFieldName helper - fix applied!"
else
    echo "✗ Plan.hs does not have logicTreesToFieldName helper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has coLogicTreeToFieldNames helper..."
if grep -q "coLogicTreeToFieldNames :: CoercibleLogicTree -> \[FieldName\]" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has coLogicTreeToFieldNames helper - fix applied!"
else
    echo "✗ Plan.hs does not have coLogicTreeToFieldNames helper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QueryBuilder.hs uses filterFields parameter..."
if grep -q "callPlanToQuery (FunctionCall qi params arguments returnsScalar returnsSetOfScalar returnsCompositeAlias filterFields returnings) pgVer =" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses filterFields parameter - fix applied!"
else
    echo "✗ QueryBuilder.hs does not use filterFields parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QueryBuilder.hs has returnedColumns' helper..."
if grep -q "returnedColumns' = S.toList \$ returnings <> filterFields" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has returnedColumns' helper - fix applied!"
else
    echo "✗ QueryBuilder.hs does not have returnedColumns' helper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that RpcSpec.hs has test for filter on unselected columns..."
if grep -q "works with filter on unselected columns" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has test for filter on unselected columns - fix applied!"
else
    echo "✗ RpcSpec.hs does not have test for filter on unselected columns - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that RpcSpec.hs has test for null embed filter..."
if grep -q "works with filter on unselected columns with null embed" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has test for null embed filter - fix applied!"
else
    echo "✗ RpcSpec.hs does not have test for null embed filter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that RpcSpec.hs has test for logical filter..."
if grep -q "works with logical filter on unselected columns" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has test for logical filter - fix applied!"
else
    echo "✗ RpcSpec.hs does not have test for logical filter - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
