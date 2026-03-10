#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

test_status=0

echo "Verifying fix for PATCH requests with zero rows updated (PR #2538)..."
echo ""
echo "NOTE: This PR fixes an issue where PATCH requests incorrectly returned 404"
echo "when a valid endpoint was targeted but zero rows were affected by the update."
echo "HEAD (fixed) should return 200 with [] (with return=rep) or 204 (without)"
echo "BASE (buggy) returns 404 when zero rows are updated"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for PATCH fix
echo "Checking CHANGELOG.md mentions PATCH zero-rows fix..."
if grep -q "#2343, Return status code 200 for PATCH requests which don't affect any rows" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PATCH fix"
else
    echo "✗ CHANGELOG.md missing PATCH fix entry - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md for the changed section
echo "Checking CHANGELOG.md has Changed section entry..."
if grep -q "#2343, PATCH requests that don't affect any rows no longer return 404" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has Changed section entry"
else
    echo "✗ CHANGELOG.md missing Changed section entry - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should NOT have status404 for rsQueryTotal == 0
echo "Checking src/PostgREST/Response.hs doesn't return 404 for zero rows..."
if grep "rsQueryTotal == 0" "src/PostgREST/Response.hs" | grep -q "status404"; then
    echo "✗ Response.hs still returns 404 for zero rows - fix not applied"
    test_status=1
else
    echo "✓ Response.hs doesn't return 404 for zero rows"
fi

# Check Response.hs - HEAD should NOT have fullRepr variable (it's removed in fix)
echo "Checking src/PostgREST/Response.hs doesn't have fullRepr logic..."
if grep -q "fullRepr = iPreferRepresentation == Full" "src/PostgREST/Response.hs"; then
    echo "✗ Response.hs still has fullRepr logic - should be removed in fix"
    test_status=1
else
    echo "✓ Response.hs doesn't have fullRepr logic (removed in fix)"
fi

# Check Response.hs - HEAD should NOT have updateIsNoOp variable (it's removed in fix)
echo "Checking src/PostgREST/Response.hs doesn't have updateIsNoOp logic..."
if grep -q "updateIsNoOp = S.null iColumns" "src/PostgREST/Response.hs"; then
    echo "✗ Response.hs still has updateIsNoOp logic - should be removed in fix"
    test_status=1
else
    echo "✓ Response.hs doesn't have updateIsNoOp logic (removed in fix)"
fi

# Check Response.hs - HEAD should NOT have Data.Set import (it's removed in fix)
echo "Checking src/PostgREST/Response.hs doesn't import Data.Set..."
if grep "import qualified Data.Set" "src/PostgREST/Response.hs"; then
    echo "✗ Response.hs still imports Data.Set - should be removed in fix"
    test_status=1
else
    echo "✓ Response.hs doesn't import Data.Set (removed in fix)"
fi

# Check Response.hs - HEAD should use direct HTTP.status200 (not status variable)
echo "Checking src/PostgREST/Response.hs uses direct HTTP.status200..."
if grep -A 3 "if iPreferRepresentation == Full then" "src/PostgREST/Response.hs" | grep -q "response HTTP.status200"; then
    echo "✓ Response.hs uses direct HTTP.status200"
else
    echo "✗ Response.hs doesn't use direct HTTP.status200 - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should use direct HTTP.status204 (not status variable)
echo "Checking src/PostgREST/Response.hs uses direct HTTP.status204..."
if grep "response HTTP.status204 headers mempty" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses direct HTTP.status204"
else
    echo "✗ Response.hs doesn't use direct HTTP.status204 - fix not applied"
    test_status=1
fi

# Check UpdateSpec.hs - HEAD test should expect 200 for zero rows with return=rep
echo "Checking UpdateSpec.hs test expects 200 status for zero rows with return=rep..."
if grep -A 5 "returns empty array when no rows updated and return=rep" "test/spec/Feature/Query/UpdateSpec.hs" | grep -q "matchStatus  = 200"; then
    echo "✓ UpdateSpec.hs test expects 200 status (not 404)"
else
    echo "✗ UpdateSpec.hs test doesn't expect 200 status - fix not applied"
    test_status=1
fi

# Check UpdateSpec.hs - HEAD test should expect 204 for zero rows without return=rep
echo "Checking UpdateSpec.hs test expects 204 status for zero rows without return=rep..."
if grep -A 3 "returns status code 200 when no rows updated" "test/spec/Feature/Query/UpdateSpec.hs" | grep -q "shouldRespondWith.*204"; then
    echo "✓ UpdateSpec.hs test expects 204 status (not 404)"
else
    echo "✗ UpdateSpec.hs test doesn't expect 204 status - fix not applied"
    test_status=1
fi

# Check UpdateSpec.hs - HEAD test for empty table should expect 204
echo "Checking UpdateSpec.hs empty table test expects 204..."
if grep -A 5 "succeeds with status code 204" "test/spec/Feature/Query/UpdateSpec.hs" | grep -q "matchStatus  = 204"; then
    echo "✓ UpdateSpec.hs empty table test expects 204"
else
    echo "✗ UpdateSpec.hs empty table test doesn't expect 204 - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - PATCH zero-rows-updated fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
