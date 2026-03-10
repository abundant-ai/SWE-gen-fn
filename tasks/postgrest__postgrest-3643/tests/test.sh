#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entry for PR #2858
echo "Checking that CHANGELOG.md has the fix entry for PR #2858..."
if grep -q "#2858, Performance improvements when calling RPCs via GET using indexes in more cases" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2858 fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md missing PR #2858 fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has the fix (uses DirectArgs and toRpcParams)..."
if grep -q "DirectArgs \$ toRpcParams proc qsParams'" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses DirectArgs pattern - fix applied!"
else
    echo "✗ Plan.hs doesn't use DirectArgs pattern - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CallPlan.hs exports toRpcParams and CallArgs..."
if grep -q ", toRpcParams" "src/PostgREST/Plan/CallPlan.hs" && grep -q "CallArgs" "src/PostgREST/Plan/CallPlan.hs"; then
    echo "✓ CallPlan.hs exports toRpcParams and defines CallArgs - fix applied!"
else
    echo "✗ CallPlan.hs missing toRpcParams or CallArgs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QueryBuilder.hs has RecordWildCards..."
if grep -q "RecordWildCards" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has RecordWildCards - fix applied!"
else
    echo "✗ QueryBuilder.hs missing RecordWildCards - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that PlanSpec.hs has the updated cost thresholds..."
if grep -q "liftIO \$ planCost r \`shouldSatisfy\` (< 35.4)" "test/spec/Feature/Query/PlanSpec.hs" && \
   grep -q "liftIO \$ planCost r \`shouldSatisfy\` (< 0.08)" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has updated cost thresholds - fix applied!"
else
    echo "✗ PlanSpec.hs doesn't have updated cost thresholds - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
