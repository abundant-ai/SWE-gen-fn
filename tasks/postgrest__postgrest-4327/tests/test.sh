#!/bin/bash

cd /app/src

# Set CI flag for consistent test behavior
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Changes are reverted (old behavior)
# In HEAD (fix applied): Changes are present (new behavior)

test_status=0

echo "Verifying Haskell source code changes for explain query logging..."
echo ""

echo "Checking CHANGELOG.md for PR #4319 mention..."
if grep -q "#4319" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PR #4319 - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention PR #4319 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/ApiRequest/Preferences.hs for shouldExplainCount export..."
if grep -q "shouldExplainCount" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs exports shouldExplainCount - fix is applied!"
else
    echo "✗ Preferences.hs does not export shouldExplainCount - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/ApiRequest/Preferences.hs for shouldExplainCount function definition..."
if grep -q "shouldExplainCount :: Maybe PreferCount -> Bool" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has shouldExplainCount function - fix is applied!"
else
    echo "✗ Preferences.hs does not have shouldExplainCount function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for mqExplain in logging..."
if grep -q "fromMaybe mempty mqExplain" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs includes mqExplain in logging - fix is applied!"
else
    echo "✗ Logger.hs does not include mqExplain in logging - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Plan.hs for CallReadPlan as data constructor (not standalone type)..."
if grep -q "| CallReadPlan {" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has CallReadPlan as CrudPlan constructor - fix is applied!"
else
    echo "✗ Plan.hs does not have CallReadPlan as constructor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Plan.hs for IsDbExplain type alias..."
if grep -q "type IsDbExplain = Bool" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has IsDbExplain type alias - fix is applied!"
else
    echo "✗ Plan.hs does not have IsDbExplain type alias - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Plan.hs for pMedia field (not wrMedia/mrMedia/crMedia)..."
if grep -q "pMedia" "src/PostgREST/Plan.hs" && ! grep -q "wrMedia\|mrMedia\|crMedia" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses pMedia field consistently - fix is applied!"
else
    echo "✗ Plan.hs field naming incorrect - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
