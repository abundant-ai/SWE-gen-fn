#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs"

test_status=0

echo "Verifying fix for limit=0 with db-max-rows (PR #2560)..."
echo ""
echo "NOTE: This PR fixes a crash when limit=0 is requested with db-max-rows set"
echo "HEAD (fixed) should have convertToLimitZeroRange helper function and test case"
echo "BASE (buggy) uses broken inline if-then-else logic and lacks the test"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for limit=0 fix
echo "Checking CHANGELOG.md mentions limit=0 regression fix..."
if grep -q "#2558, Fix regression when requesting limit=0 and \`db-max-row\` is set" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions limit=0 fix"
else
    echo "✗ CHANGELOG.md missing limit=0 fix entry - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should use convertToLimitZeroRange (the fix)
echo "Checking src/PostgREST/ApiRequest.hs uses convertToLimitZeroRange..."
if grep -q 'ranges = HM.insert "limit" (convertToLimitZeroRange limitRange headerAndLimitRange) qsRanges' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs uses convertToLimitZeroRange"
else
    echo "✗ ApiRequest.hs doesn't use convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should import convertToLimitZeroRange
echo "Checking src/PostgREST/ApiRequest.hs imports convertToLimitZeroRange..."
if grep "import PostgREST.RangeQuery" "src/PostgREST/ApiRequest.hs" -A 3 | grep -q "convertToLimitZeroRange"; then
    echo "✓ ApiRequest.hs imports convertToLimitZeroRange"
else
    echo "✗ ApiRequest.hs doesn't import convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should import convertToLimitZeroRange
echo "Checking src/PostgREST/Plan.hs imports convertToLimitZeroRange..."
if grep "import PostgREST.RangeQuery" "src/PostgREST/Plan.hs" -A 2 | grep -q "convertToLimitZeroRange"; then
    echo "✓ Plan.hs imports convertToLimitZeroRange"
else
    echo "✗ Plan.hs doesn't import convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use convertToLimitZeroRange in nodeRestrictRange
echo "Checking src/PostgREST/Plan.hs uses convertToLimitZeroRange..."
if grep -q "nodeRestrictRange m q@ReadPlan{range_=r} = q{range_= convertToLimitZeroRange r (restrictRange m r) }" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses convertToLimitZeroRange"
else
    echo "✗ Plan.hs doesn't use convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check RangeQuery.hs - HEAD should export convertToLimitZeroRange
echo "Checking src/PostgREST/RangeQuery.hs exports convertToLimitZeroRange..."
if grep "module PostgREST.RangeQuery" "src/PostgREST/RangeQuery.hs" -A 10 | grep -q ", convertToLimitZeroRange"; then
    echo "✓ RangeQuery.hs exports convertToLimitZeroRange"
else
    echo "✗ RangeQuery.hs doesn't export convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check RangeQuery.hs - HEAD should define convertToLimitZeroRange function
echo "Checking src/PostgREST/RangeQuery.hs defines convertToLimitZeroRange..."
if grep -q "convertToLimitZeroRange :: Range Integer -> Range Integer -> Range Integer" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs defines convertToLimitZeroRange"
else
    echo "✗ RangeQuery.hs doesn't define convertToLimitZeroRange - fix not applied"
    test_status=1
fi

# Check QueryLimitedSpec.hs - HEAD should HAVE the test case for limit=0 with max-rows
echo "Checking test/spec/Feature/Query/QueryLimitedSpec.hs has limit=0 test..."
if grep -q "max-rows is set and limits are requested" "test/spec/Feature/Query/QueryLimitedSpec.hs" && \
   grep -q "should work with limit 0" "test/spec/Feature/Query/QueryLimitedSpec.hs"; then
    echo "✓ QueryLimitedSpec.hs has limit=0 test case"
else
    echo "✗ QueryLimitedSpec.hs missing limit=0 test case - fix not applied"
    test_status=1
fi

# Check that the test actually checks for limit=0
echo "Checking QueryLimitedSpec.hs test verifies limit=0 endpoint..."
if grep -q 'get "/items?limit=0"' "test/spec/Feature/Query/QueryLimitedSpec.hs"; then
    echo "✓ QueryLimitedSpec.hs test checks /items?limit=0"
else
    echo "✗ QueryLimitedSpec.hs test doesn't check limit=0 - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - limit=0 fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
