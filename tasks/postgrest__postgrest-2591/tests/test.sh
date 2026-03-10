#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for OpenAPI array items object (PR #2591)..."
echo ""
echo "NOTE: This PR adds proper items object for array parameters in OpenAPI spec"
echo "HEAD (fixed) should have makeSwaggerItemType function and items object for arrays"
echo "BASE (buggy) has no items object for arrays, uses ARRAY type instead"
echo ""

# Check OpenAPI.hs - HEAD should have makeSwaggerItemType function
echo "Checking src/PostgREST/Response/OpenAPI.hs has makeSwaggerItemType function..."
if grep -q "makeSwaggerItemType" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs defines makeSwaggerItemType function"
else
    echo "✗ OpenAPI.hs missing makeSwaggerItemType function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should detect arrays by [] suffix
echo "Checking src/PostgREST/Response/OpenAPI.hs detects arrays by [] suffix..."
if grep -q 'T.takeEnd 2 colType' "src/PostgREST/Response/OpenAPI.hs" && \
   grep -q '"\[\]"' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs detects arrays by [] suffix"
else
    echo "✗ OpenAPI.hs missing array detection logic - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should use items field with makeSwaggerItemType
echo "Checking src/PostgREST/Response/OpenAPI.hs uses items field..."
if grep -q 'items .~ (SwaggerItemsObject <\$> makeSwaggerItemType' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs uses items field with makeSwaggerItemType"
else
    echo "✗ OpenAPI.hs missing items field usage - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should not have ARRAY type
echo "Checking src/PostgREST/Response/OpenAPI.hs does not use ARRAY type..."
if ! grep -q 'toSwaggerType "ARRAY"' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs does not use ARRAY type"
else
    echo "✗ OpenAPI.hs still has ARRAY type - fix not complete"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should not have ARRAY detection logic
echo "Checking src/PostgREST/SchemaCache.hs does not detect ARRAY type..."
if ! grep -q "THEN 'ARRAY'::text" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs does not detect ARRAY type"
else
    echo "✗ SchemaCache.hs still has ARRAY detection - fix not complete"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - OpenAPI array items properly fixed"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
