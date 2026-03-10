#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AndOrParamsSpec.hs" "test/spec/Feature/Query/AndOrParamsSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4621 which fixes mutation response filtering with or/and params
# HEAD state (67a9b8e5fca69393a9b7652c9e802f3c702026c7) = fix applied, mutations filtered correctly
# BASE state (with bug.patch) = old state where mutations incorrectly filter or/and logic

test_status=0

echo "Verifying source code matches HEAD state (mutation or/and filter fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the fix for or/and filters on PATCH requests..."
if grep -q "Fix incorrectly filtering the returned representation for PATCH requests when using \`or/and\` filters" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have the fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Plan.hs has the fixed addLogicTrees logic (with case statement)..."
# In the fixed version, it has a case statement that properly handles mutations
if grep -q "foldr addLogicTreeToNode (Right rReq) logic" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses logic variable - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs does not use logic variable - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Plan.hs has the case statement for handling different actions..."
if grep -q "ActDb (ActRelationRead _  _) -> qsLogic" "src/PostgREST/Plan.hs" && \
   grep -q "ActDb (ActRoutine _ _)       -> qsLogic" "src/PostgREST/Plan.hs" && \
   grep -q "filter (not \. null \. fst) qsLogic" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has the case statement - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs missing the case statement - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/AndOrParamsSpec.hs has additional PATCH test cases..."
if grep -q "succeeds when the filtered column is modified" "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ AndOrParamsSpec.hs has test for filtering modified columns - fix applied!"
else
    echo "✗ AndOrParamsSpec.hs missing test for filtering modified columns - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/AndOrParamsSpec.hs has test for non-selected columns..."
if grep -q "succeeds when the filtered column is not selected in the returned representation" "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ AndOrParamsSpec.hs has test for non-selected filter columns - fix applied!"
else
    echo "✗ AndOrParamsSpec.hs missing test for non-selected filter columns - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/AndOrParamsSpec.hs has the PATCH context with do block..."
if grep -q 'context "used with PATCH" \$ do' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ AndOrParamsSpec.hs has PATCH context with do block - fix applied!"
else
    echo "✗ AndOrParamsSpec.hs missing PATCH context do block - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/AndOrParamsSpec.hs has the DELETE context with do block..."
if grep -q 'context "used with DELETE" \$ do' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ AndOrParamsSpec.hs has DELETE context with do block - fix applied!"
else
    echo "✗ AndOrParamsSpec.hs missing DELETE context do block - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
