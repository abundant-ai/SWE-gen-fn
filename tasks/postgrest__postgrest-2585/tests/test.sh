#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for plan media type response (PR #2585)..."
echo ""
echo "NOTE: This PR refactors PlanSpec to use planCost helper function for cleaner code"
echo "HEAD (fixed) should use planCost helper function and Float values"
echo "BASE (buggy) uses inline lens expressions with aesonQQ values"
echo ""

# Check PlanSpec.hs - HEAD should use planCost function
echo "Checking test/spec/Feature/Query/PlanSpec.hs uses planCost function..."
if grep -q "planCost r" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs uses planCost function"
else
    echo "✗ PlanSpec.hs missing planCost usage - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should NOT use inline lens expression
echo "Checking test/spec/Feature/Query/PlanSpec.hs does not use inline lens expressions..."
if ! grep -q 'simpleBody r \^\? nth 0 \. key "Plan" \. key "Total Cost"' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs does not use inline lens expressions"
else
    echo "✗ PlanSpec.hs still has inline lens expressions - fix not complete"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should use plain Float values for totalCost, not aesonQQ wrapped
echo "Checking test/spec/Feature/Query/PlanSpec.hs uses plain Float values for totalCost..."
if grep -q 'then 15.63' "test/spec/Feature/Query/PlanSpec.hs" && \
   ! grep -q 'Just \[aesonQQ|15.63|\]' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs uses plain Float values for totalCost"
else
    echo "✗ PlanSpec.hs missing plain Float values for totalCost - fix not complete"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should HAVE planCost function
echo "Checking test/spec/SpecHelper.hs defines planCost function..."
if grep -q "planCost ::" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs defines planCost function"
else
    echo "✗ SpecHelper.hs missing planCost function - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should HAVE planHdr
echo "Checking test/spec/SpecHelper.hs defines planHdr..."
if grep -q "planHdr ::" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs defines planHdr"
else
    echo "✗ SpecHelper.hs missing planHdr - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should import Data.Scientific for planCost
echo "Checking test/spec/SpecHelper.hs imports Data.Scientific..."
if grep -q "Data.Scientific" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs imports Data.Scientific"
else
    echo "✗ SpecHelper.hs missing Data.Scientific import - fix not complete"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should import Control.Lens for planCost
echo "Checking test/spec/SpecHelper.hs imports lens libraries..."
if grep -q "Control.Lens" "test/spec/SpecHelper.hs" && \
   grep -q "Data.Aeson.Lens" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs imports lens libraries"
else
    echo "✗ SpecHelper.hs missing lens imports - fix not complete"
    test_status=1
fi

# Check postgrest.cabal - HEAD should NOT have test-suite querycost (it was deleted)
echo "Checking postgrest.cabal does not have querycost test suite..."
if ! grep -q "test-suite querycost" "postgrest.cabal"; then
    echo "✓ postgrest.cabal does not have querycost test suite"
else
    echo "✗ postgrest.cabal still has querycost test suite - fix not complete"
    test_status=1
fi

# Check postgrest.cabal - HEAD should have scientific dependency in spec suite
echo "Checking postgrest.cabal has scientific dependency in spec suite..."
if grep -q ", scientific" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has scientific dependency"
else
    echo "✗ postgrest.cabal missing scientific dependency - fix not complete"
    test_status=1
fi

# Check postgrest.cabal - HEAD should NOT list TestTypes in spec suite (was removed)
echo "Checking postgrest.cabal does not list TestTypes in spec suite..."
if ! awk '/^test-suite spec/,/^test-suite [^s]|^executable|^library/{print}' "postgrest.cabal" | grep -q "TestTypes"; then
    echo "✓ postgrest.cabal does not list TestTypes in spec suite"
else
    echo "✗ postgrest.cabal still lists TestTypes - fix not complete"
    test_status=1
fi

# Check that TestTypes file does NOT exist (was deleted in PR)
echo "Checking test/spec/TestTypes.hs does not exist..."
if [ ! -f "test/spec/TestTypes.hs" ]; then
    echo "✓ TestTypes.hs does not exist"
else
    echo "✗ TestTypes.hs still exists - fix not complete"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - Plan response refactored successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
