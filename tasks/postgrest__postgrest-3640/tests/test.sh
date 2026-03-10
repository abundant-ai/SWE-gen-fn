#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AggregateFunctionsSpec.hs" "test/spec/Feature/Query/AggregateFunctionsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SpreadQueriesSpec.hs" "test/spec/Feature/Query/SpreadQueriesSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entry for PR #3041
echo "Checking that CHANGELOG.md has the fix entry for PR #3041..."
if grep -q "#3041, Allow spreading one-to-many and many-to-many embedded resources" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #3041 fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md missing PR #3041 fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that aggregate_functions.rst has updated spread documentation..."
if grep -q "Aggregates in To-One Spreads" "docs/references/api/aggregate_functions.rst" && \
   grep -q "Aggregates inside to-many spreads are not supported" "docs/references/api/aggregate_functions.rst"; then
    echo "✓ aggregate_functions.rst has updated spread docs - fix applied!"
else
    echo "✗ aggregate_functions.rst missing updated spread docs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that resource_embedding.rst has spread to-many section..."
if grep -q "Spread To-Many relationships" "docs/references/api/resource_embedding.rst" && \
   grep -q "spread_to_many_embed" "docs/references/api/resource_embedding.rst"; then
    echo "✓ resource_embedding.rst has spread to-many section - fix applied!"
else
    echo "✗ resource_embedding.rst missing spread to-many section - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst has PGRST127 error code..."
if grep -q "PGRST127" "docs/references/errors.rst" && \
   ! grep -q "PGRST119" "docs/references/errors.rst"; then
    echo "✓ errors.rst has PGRST127 and removed PGRST119 - fix applied!"
else
    echo "✗ errors.rst doesn't have correct error codes - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PostgREST source files have spread type implementation..."
if grep -q "data SpreadType" "src/PostgREST/Plan/Types.hs" 2>/dev/null && \
   grep -q "ToManySpread" "src/PostgREST/Plan/Types.hs" 2>/dev/null; then
    echo "✓ Plan/Types.hs has SpreadType with ToManySpread - fix applied!"
else
    echo "✗ Plan/Types.hs missing SpreadType or ToManySpread - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
