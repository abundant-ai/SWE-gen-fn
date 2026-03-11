#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for unnecessary count() on RPC returning single row (PR #3015)..."
echo ""
echo "NOTE: This PR fixes unnecessary COUNT queries for single-row RPC functions"
echo "BASE (buggy) performs pg_catalog.count(_postgrest_t) for all RPCs"
echo "HEAD (fixed) uses conditional: if funcReturnsSingle then '1' else count"
echo ""

# Check that Statements.hs uses the conditional count logic
echo "Checking src/PostgREST/Query/Statements.hs uses conditional count..."
if grep -q "if funcReturnsSingle rout" "src/PostgREST/Query/Statements.hs" && \
   grep -q 'then "1"' "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs uses conditional count with funcReturnsSingle"
else
    echo "✗ Statements.hs does not use conditional count - fix not applied"
    test_status=1
fi

# Check that Routine.hs exports funcReturnsSingle
echo "Checking src/PostgREST/SchemaCache/Routine.hs exports funcReturnsSingle..."
if grep -q "funcReturnsSingle" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs contains funcReturnsSingle function"
else
    echo "✗ Routine.hs missing funcReturnsSingle - fix not applied"
    test_status=1
fi

# Check that funcReturnsSingle is defined
echo "Checking funcReturnsSingle function is defined..."
if grep -q "funcReturnsSingle :: Routine -> Bool" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ funcReturnsSingle function is defined"
else
    echo "✗ funcReturnsSingle function not defined - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md mentions the fix
echo "Checking CHANGELOG.md mentions the fix..."
if grep -q "#3015" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions fix #3015"
else
    echo "✗ CHANGELOG.md does not mention fix - fix not fully applied"
    test_status=1
fi

# Verify the test file PlanSpec.hs has updated plan cost threshold
echo "Checking test/spec/Feature/Query/PlanSpec.hs has lower plan cost threshold..."
if grep -q "< 0.11" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has lower plan cost threshold (< 0.11)"
else
    echo "✗ PlanSpec.hs missing updated plan cost - test not updated correctly"
    test_status=1
fi

# Verify RpcSpec.hs has the test cases for single-row count behavior
echo "Checking test/spec/Feature/Query/RpcSpec.hs has test cases for single-row count..."
if grep -q "includes exact count of 1 for functions that return a single scalar" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has test cases for single-row count behavior"
else
    echo "✗ RpcSpec.hs missing test cases - test not updated correctly"
    test_status=1
fi

echo ""

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
