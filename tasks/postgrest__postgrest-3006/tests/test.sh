#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

test_status=0

echo "Verifying fix for range request regression (PR #3006)..."
echo ""
echo "NOTE: This PR fixes a regression where offset equal to total rows returned 416 instead of 206/200"
echo "BASE (buggy) uses complex condition: lower >= total && lower /= upper && lower /= 0"
echo "HEAD (fixed) uses simple condition: lower > total"
echo ""

# Check that RangeQuery.hs uses the simpler condition
echo "Checking src/PostgREST/RangeQuery.hs uses simple condition 'lower > total'..."
if grep -q "lower > total" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs uses simple condition 'lower > total'"
else
    echo "✗ RangeQuery.hs does not use simple condition - fix not applied"
    test_status=1
fi

# Check that the complex buggy condition is NOT present
echo "Checking RangeQuery.hs does NOT use buggy complex condition..."
if grep -q "lower >= total && lower /= upper && lower /= 0" "src/PostgREST/RangeQuery.hs"; then
    echo "✗ RangeQuery.hs still has buggy complex condition - fix not applied"
    test_status=1
else
    echo "✓ RangeQuery.hs does not have buggy complex condition"
fi

# Check that CHANGELOG.md mentions the fix
echo "Checking CHANGELOG.md mentions the regression fix..."
if grep -q "Fix regression by reverting fix that returned 206 when first position = length" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions regression fix"
else
    echo "✗ CHANGELOG.md does not mention regression fix - fix not fully applied"
    test_status=1
fi

# Verify the test file does NOT have the buggy test case about refusing range at first position
echo "Checking test/spec/Feature/Query/RangeSpec.hs does NOT have buggy test case..."
if grep -q "refuses a range with first position the same as number of items" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✗ RangeSpec.hs still has buggy test case - fix not applied"
    test_status=1
else
    echo "✓ RangeSpec.hs does not have buggy test case"
fi

# Verify test file does NOT have the test for offset=0 and total=0 that was added with the bug
echo "Checking test/spec/Feature/Query/RangeSpec.hs does NOT have offset=0 total=0 test..."
if grep -q "does not throw error when offset is 0 and and total is 0" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✗ RangeSpec.hs still has offset=0 total=0 test - fix not applied"
    test_status=1
else
    echo "✓ RangeSpec.hs does not have offset=0 total=0 test"
fi

echo ""

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
