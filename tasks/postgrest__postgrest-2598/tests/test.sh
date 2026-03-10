#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

test_status=0

echo "Verifying fix for OpenAPI upsert headers on POST requests (PR #2598)..."
echo ""
echo "NOTE: This PR adds preferPost parameter and val function for better OpenAPI spec"
echo "HEAD (fixed) should have preferPost with val function that expands enum values"
echo "BASE (buggy) has no preferPost, uses preferReturn for POST, no val function"
echo ""

# Check OpenAPI.hs - HEAD should have preferPost in makeParamDefs
echo "Checking src/PostgREST/Response/OpenAPI.hs defines preferPost..."
if grep -q '"preferPost"' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs defines preferPost parameter"
else
    echo "✗ OpenAPI.hs missing preferPost definition - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should use preferPost for POST operation
echo "Checking src/PostgREST/Response/OpenAPI.hs uses preferPost for POST..."
if grep -q 'postOp.*parameters.*preferPost' "src/PostgREST/Response/OpenAPI.hs" || \
   (grep -A 1 'postOp = tOp' "src/PostgREST/Response/OpenAPI.hs" | grep -q 'preferPost'); then
    echo "✓ OpenAPI.hs uses preferPost for POST operation"
else
    echo "✗ OpenAPI.hs missing preferPost for POST - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have val function for pattern matching
echo "Checking src/PostgREST/Response/OpenAPI.hs has val function..."
if grep -A 10 'makePreferParam' "src/PostgREST/Response/OpenAPI.hs" | grep -q 'val :: Text'; then
    echo "✓ OpenAPI.hs has val function for enum expansion"
else
    echo "✗ OpenAPI.hs missing val function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should pass short keys to makePreferParam that get expanded
echo "Checking src/PostgREST/Response/OpenAPI.hs passes short keys to makePreferParam..."
if grep -q 'makePreferParam \["return", "resolution"\]' "src/PostgREST/Response/OpenAPI.hs" || \
   grep -q 'makePreferParam \["params"\]' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs passes short keys to makePreferParam"
else
    echo "✗ OpenAPI.hs missing short key usage - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - OpenAPI upsert headers properly fixed"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
