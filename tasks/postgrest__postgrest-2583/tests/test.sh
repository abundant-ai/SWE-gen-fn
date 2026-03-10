#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

test_status=0

echo "Verifying fix for fuzzy suggestions in relationship errors (PR #2583)..."
echo ""
echo "NOTE: This PR adds fuzzy suggestions when relationships are not found"
echo "HEAD (fixed) should have noRelBetweenHint function and fuzzy suggestion support"
echo "BASE (buggy) removes fuzzy suggestions and shows misleading 'reload schema cache' hint"
echo ""

# Check Error.hs - HEAD should HAVE noRelBetweenHint function
echo "Checking src/PostgREST/Error.hs has noRelBetweenHint function..."
if grep -q "noRelBetweenHint ::" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has noRelBetweenHint function"
else
    echo "✗ Error.hs missing noRelBetweenHint - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE fuzzy suggestion logic
echo "Checking src/PostgREST/Error.hs has fuzzy suggestion logic..."
if grep -q "Perhaps you meant" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has fuzzy suggestion logic"
else
    echo "✗ Error.hs missing fuzzy suggestion logic - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should import Data.HashMap.Strict
echo "Checking src/PostgREST/Error.hs imports Data.HashMap.Strict..."
if grep -q "import qualified Data.HashMap.Strict" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs imports Data.HashMap.Strict"
else
    echo "✗ Error.hs missing HashMap import - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should HAVE NoRelBetween with extra parameters
echo "Checking src/PostgREST/ApiRequest/Types.hs has NoRelBetween with RelationshipsMap..."
if grep -q "NoRelBetween Text Text (Maybe Text) Text RelationshipsMap" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs has NoRelBetween with fuzzy suggestion parameters"
else
    echo "✗ ApiRequest/Types.hs missing NoRelBetween parameters - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should import RelationshipsMap
echo "Checking src/PostgREST/ApiRequest/Types.hs imports RelationshipsMap..."
if grep -q "RelationshipsMap" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs imports RelationshipsMap"
else
    echo "✗ ApiRequest/Types.hs missing RelationshipsMap import - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should pass allRels to NoRelBetween
echo "Checking src/PostgREST/Plan.hs passes allRels to NoRelBetween..."
if grep -q "NoRelBetween origin target hint schema allRels" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs passes allRels to NoRelBetween"
else
    echo "✗ Plan.hs not passing allRels - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should call noRelBetweenHint in JSON serialization
echo "Checking src/PostgREST/Error.hs calls noRelBetweenHint..."
if grep -q "noRelBetweenHint parent child schema allRels" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs calls noRelBetweenHint in toJSON"
else
    echo "✗ Error.hs not calling noRelBetweenHint - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md - HEAD should HAVE entry about fuzzy suggestions
echo "Checking CHANGELOG.md mentions fuzzy suggestions for relationships..."
if grep -q "#2569.*misleading.*relationship" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fuzzy suggestion feature entry"
else
    echo "✗ CHANGELOG.md missing feature entry - fix not complete"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should HAVE fuzzy suggestion in test expectations
echo "Checking test/spec/Feature/Query/QuerySpec.hs has fuzzy suggestion tests..."
if grep -q "Perhaps you meant 'car_model_sales' instead of 'car_model_sales_202101'" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has fuzzy suggestion test expectations"
else
    echo "✗ QuerySpec.hs missing fuzzy suggestion tests - fix not complete"
    test_status=1
fi

# Check EmbedDisambiguationSpec.hs - HEAD should NOT have misleading hint
echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs doesn't have misleading hint..."
if grep -q "try reloading the schema cache" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✗ EmbedDisambiguationSpec.hs still has misleading hint - fix not complete"
    test_status=1
else
    echo "✓ EmbedDisambiguationSpec.hs removed misleading hint"
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fuzzy suggestions feature implemented successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
