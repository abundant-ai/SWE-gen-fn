#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

# Verify source code matches HEAD state (ORDER BY with nulls-order fix applied)
# This is PR #4114 which ADDS the fix for ORDER BY with nulls-order not working alongside limits
# HEAD state (aa2e179d66) = fix applied, adds spaces before GROUP BY and ORDER BY clauses
# BASE state (with bug.patch) = broken (missing spaces in SQL generation)
# ORACLE state (BASE + fix.patch) = proper spacing (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (ORDER BY with nulls-order fix applied)..."
echo ""

echo "Checking that QueryBuilder.hs has proper spacing before groupF..."
if grep -q 'groupF qi select relSelect <> " " <>' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has proper spacing before groupF - fix applied!"
else
    echo "✗ QueryBuilder.hs missing spacing before groupF - fix not applied"
    test_status=1
fi

echo "Checking that QueryBuilder.hs has proper spacing before orderF..."
if grep -q 'orderF qi order <> " " <>' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has proper spacing before orderF - fix applied!"
else
    echo "✗ QueryBuilder.hs missing spacing before orderF - fix not applied"
    test_status=1
fi

echo "Checking that test file includes nulls-order test case..."
if grep -q "works alongside order by with nulls order" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec includes nulls-order test - test from HEAD!"
else
    echo "✗ RangeSpec does not include nulls-order test - test not from HEAD"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the fix..."
if grep -q "Fix regression that makes \`ORDER BY\` with nulls-order not work alongside limits" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG does not mention the fix - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
