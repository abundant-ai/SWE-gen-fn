#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

# Check that RangeQuery.hs HAS the && lower /= 0 condition (this is the fix!)
echo "Checking RangeQuery.hs for the fix..."
if grep -q 'lower >= total && lower /= upper && lower /= 0 = status416' "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs has the && lower /= 0 condition"
else
    echo "✗ RangeQuery.hs missing && lower /= 0 condition - fix not applied"
    test_status=1
fi

# Check that the test case exists in RangeSpec.hs
echo "Checking RangeSpec.hs for test case..."
if grep -q 'does not throw error when offset is 0 and and total is 0' "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has the test case"
else
    echo "✗ RangeSpec.hs missing test case - fix not applied"
    test_status=1
fi

# Check that the test case includes the expected status and content-range
echo "Checking RangeSpec.hs for correct test expectations..."
if grep -A 8 'does not throw error when offset is 0 and and total is 0' "test/spec/Feature/Query/RangeSpec.hs" | grep -q 'matchStatus  = 200' && \
   grep -A 8 'does not throw error when offset is 0 and and total is 0' "test/spec/Feature/Query/RangeSpec.hs" | grep -q 'Content-Range.*\*/0'; then
    echo "✓ RangeSpec.hs test has correct expectations"
else
    echo "✗ RangeSpec.hs test expectations not correct - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2824, Fix range request with 0 rows and 0 offset return status 416' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
