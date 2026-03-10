#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/QueryCost.hs" "test/spec/QueryCost.hs"

test_status=0

echo "Verifying fix for refactoring Plan/Query modules (PR #2497)..."
echo ""
echo "NOTE: This PR refactors logic from Request to Plan modules"
echo "HEAD (fixed) uses PostgREST.Plan.CallPlan and callPlanToQuery"
echo "BASE (buggy) uses PostgREST.Request.Types and requestToCallProcQuery"
echo ""

# Check QueryCost.hs - HEAD should import PostgREST.Plan.CallPlan
echo "Checking test/spec/QueryCost.hs imports PostgREST.Plan.CallPlan..."
if grep -q "import PostgREST.Plan.CallPlan" "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs imports PostgREST.Plan.CallPlan"
else
    echo "✗ QueryCost.hs does not import PostgREST.Plan.CallPlan - fix not applied"
    test_status=1
fi

# Check QueryCost.hs - HEAD should import callPlanToQuery from QueryBuilder
echo "Checking test/spec/QueryCost.hs imports callPlanToQuery..."
if grep -q "import PostgREST.Query.QueryBuilder (callPlanToQuery)" "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs imports callPlanToQuery"
else
    echo "✗ QueryCost.hs does not import callPlanToQuery - fix not applied"
    test_status=1
fi

# Check QueryCost.hs - HEAD should NOT import requestToCallProcQuery
echo "Checking test/spec/QueryCost.hs does NOT import requestToCallProcQuery..."
if ! grep -q "requestToCallProcQuery" "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs does not use requestToCallProcQuery (removed)"
else
    echo "✗ QueryCost.hs still uses requestToCallProcQuery - fix not applied"
    test_status=1
fi

# Check QueryCost.hs - HEAD should NOT import PostgREST.Request.Types
echo "Checking test/spec/QueryCost.hs does NOT import PostgREST.Request.Types..."
if ! grep -q "import PostgREST.Request.Types" "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs does not import PostgREST.Request.Types (removed)"
else
    echo "✗ QueryCost.hs still imports PostgREST.Request.Types - fix not applied"
    test_status=1
fi

# Check QueryCost.hs - HEAD should use callPlanToQuery
echo "Checking test/spec/QueryCost.hs uses callPlanToQuery..."
if grep -q "callPlanToQuery" "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs uses callPlanToQuery"
else
    echo "✗ QueryCost.hs does not use callPlanToQuery - fix not applied"
    test_status=1
fi

# Check Plan.hs exists in HEAD
echo "Checking src/PostgREST/Plan.hs exists..."
if [ -f "src/PostgREST/Plan.hs" ]; then
    echo "✓ Plan.hs exists"
else
    echo "✗ Plan.hs missing - fix not applied"
    test_status=1
fi

# Check Plan/CallPlan.hs exists in HEAD
echo "Checking src/PostgREST/Plan/CallPlan.hs exists..."
if [ -f "src/PostgREST/Plan/CallPlan.hs" ]; then
    echo "✓ Plan/CallPlan.hs exists"
else
    echo "✗ Plan/CallPlan.hs missing - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - refactoring to Plan modules applied"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
