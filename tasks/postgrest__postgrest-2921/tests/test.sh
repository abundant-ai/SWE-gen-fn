#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

test_status=0

echo "Verifying range request fix implementation..."
echo ""

# Check that CHANGELOG has the fix documented
echo "Checking CHANGELOG.md has range request fix entry..."
if grep -q '#2824, Fix range request with first position same as length return status 206' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has range request fix entry"
else
    echo "✗ CHANGELOG.md missing range request fix entry - fix not applied"
    test_status=1
fi

# Check that RangeQuery.hs has the updated rangeStatus logic
echo "Checking RangeQuery.hs has updated rangeStatus logic..."
if grep -q 'lower >= total && lower /= upper = status416' "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs has updated status416 condition"
else
    echo "✗ RangeQuery.hs missing updated status416 condition - fix not applied"
    test_status=1
fi

# Verify the old incorrect condition is removed
echo "Checking old incorrect condition is removed..."
if grep -q 'lower > total.*= status416' "src/PostgREST/RangeQuery.hs"; then
    echo "✗ RangeQuery.hs still has old incorrect condition (lower > total) - fix not applied"
    test_status=1
else
    echo "✓ Old incorrect condition removed"
fi

# Check that the status206 condition is updated
echo "Checking status206 condition formatting..."
if grep -q '(1 + upper - lower) < total.*= status206' "src/PostgREST/RangeQuery.hs"; then
    echo "✓ status206 condition present"
else
    echo "✗ status206 condition not found - fix may be incomplete"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
