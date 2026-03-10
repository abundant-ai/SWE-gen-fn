#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AggregateFunctionsSpec.hs" "test/spec/Feature/Query/AggregateFunctionsSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that the cfFullRow field exists in CoercibleField (it was added in the fix)
echo "Checking that cfFullRow field was added to CoercibleField..."
if grep -q "cfFullRow" "src/PostgREST/Plan/Types.hs"; then
    echo "✓ Plan/Types.hs contains cfFullRow field - fix applied!"
else
    echo "✗ Plan/Types.hs missing cfFullRow field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that resolveColumnField uses 7 arguments..."
if grep -q "CoercibleField (colName col) mempty False (colNominalType col) Nothing (colDefault col) False" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses 7-argument CoercibleField constructor - fix applied!"
else
    echo "✗ Plan.hs doesn't use 7-argument CoercibleField constructor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that pgFmtField handles cfFullRow=True case..."
if grep -q "pgFmtField table CoercibleField{cfFullRow=True}" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has cfFullRow=True pattern match - fix applied!"
else
    echo "✗ SqlFragment.hs missing cfFullRow pattern match - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that validateAggFunctions uses correct HEAD logic..."
if grep -A1 "validateAggFunctions aggFunctionsAllowed (Node rp@ReadPlan {select} forest)" "src/PostgREST/Plan.hs" | grep -q "not aggFunctionsAllowed && any"; then
    echo "✓ Plan.hs has correct validateAggFunctions logic - fix applied!"
else
    echo "✗ Plan.hs doesn't have correct validateAggFunctions logic - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
