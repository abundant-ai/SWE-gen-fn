#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

test_status=0

echo "Verifying range query fix for offset=0 with empty results (PR #3025)..."
echo ""
echo "NOTE: This PR fixes a bug where offset=0 with count=exact returned 416 for empty results"
echo "BASE (buggy) uses 'lower >= total && lower /= upper' which incorrectly rejects offset=0"
echo "HEAD (fixed) uses 'lower > total' which correctly accepts offset=0 for empty results"
echo ""

# Check that RangeQuery.hs uses the fixed condition (lower > total)
echo "Checking src/PostgREST/RangeQuery.hs uses 'lower > total'..."
if grep -q "lower > total" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs uses 'lower > total' condition"
else
    echo "✗ RangeQuery.hs does not use 'lower > total' - fix not applied"
    test_status=1
fi

# Check that RangeQuery.hs does NOT have the buggy condition
echo "Checking src/PostgREST/RangeQuery.hs does not have buggy 'lower >= total && lower /= upper'..."
if ! grep -q "lower >= total && lower /= upper" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs does not have buggy condition"
else
    echo "✗ RangeQuery.hs still has buggy condition - fix not applied"
    test_status=1
fi

# Check that the version is updated to 11.2.2
echo "Checking postgrest.cabal version is 11.2.2..."
if grep -q "version:.*11.2.2" "postgrest.cabal"; then
    echo "✓ postgrest.cabal version is 11.2.2"
else
    echo "✗ postgrest.cabal version is not 11.2.2 - fix not fully applied"
    test_status=1
fi

# Check that CHANGELOG.md mentions the fix
echo "Checking CHANGELOG.md mentions the fix..."
if grep -q "#2824" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions fix #2824"
else
    echo "✗ CHANGELOG.md does not mention fix - fix not fully applied"
    test_status=1
fi

# Verify the test file has the new test cases for offset=0 with empty results
echo "Checking test/spec/Feature/Query/RangeSpec.hs has test for offset=0 with count=exact..."
if grep -q "count with an empty body" "test/spec/Feature/Query/RangeSpec.hs" || \
   grep -q "succeeds if offset equals 0 as a no-op" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has test cases for offset=0 behavior"
else
    echo "✗ RangeSpec.hs missing test cases - test file not updated correctly"
    test_status=1
fi

echo ""

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
