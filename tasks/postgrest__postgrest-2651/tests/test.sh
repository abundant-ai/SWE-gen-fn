#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

test_status=0

echo "Verifying fix for missing GET path item for RPCs in OpenAPI output..."
echo ""
echo "NOTE: This PR adds GET operations to OpenAPI spec for RPC functions"
echo "HEAD (fixed) should have makeProcGetParam functions and GET operations in path items."
echo "BASE (buggy) lacks GET support in OpenAPI spec."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2651 entry
echo "Checking CHANGELOG.md has PR #2651 entry..."
if grep -q "#2651, Add the missing \`get\` path item for RPCs to the OpenAPI output" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2651 entry"
else
    echo "✗ CHANGELOG.md missing PR #2651 entry - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have makeProcGetParam function
echo "Checking src/PostgREST/Response/OpenAPI.hs has makeProcGetParam function..."
if grep -q "makeProcGetParam" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has makeProcGetParam function"
else
    echo "✗ OpenAPI.hs missing makeProcGetParam function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have makeProcGetParams function
echo "Checking src/PostgREST/Response/OpenAPI.hs has makeProcGetParams function..."
if grep -q "makeProcGetParams" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has makeProcGetParams function"
else
    echo "✗ OpenAPI.hs missing makeProcGetParams function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have typeFromArray function
echo "Checking src/PostgREST/Response/OpenAPI.hs has typeFromArray function..."
if grep -q "typeFromArray :: Text -> Text" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has typeFromArray function"
else
    echo "✗ OpenAPI.hs missing typeFromArray function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have toSwaggerTypeFromArray function
echo "Checking src/PostgREST/Response/OpenAPI.hs has toSwaggerTypeFromArray function..."
if grep -q "toSwaggerTypeFromArray" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has toSwaggerTypeFromArray function"
else
    echo "✗ OpenAPI.hs missing toSwaggerTypeFromArray function - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should use makePropertyItems (not makeSwaggerItemType)
echo "Checking src/PostgREST/Response/OpenAPI.hs uses makePropertyItems..."
if grep -q "makePropertyItems" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs uses makePropertyItems function"
else
    echo "✗ OpenAPI.hs missing makePropertyItems - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should have getOp definition in makeProcPathItem
echo "Checking src/PostgREST/Response/OpenAPI.hs has getOp definition..."
if grep -q "getOp = " "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has getOp definition"
else
    echo "✗ OpenAPI.hs missing getOp definition - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should set both get and post in PathItem
echo "Checking src/PostgREST/Response/OpenAPI.hs sets both get and post operations..."
if grep -q "& get ?~ getOp" "src/PostgREST/Response/OpenAPI.hs" && \
   grep -q "& post ?~ postOp" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs sets both get and post operations in PathItem"
else
    echo "✗ OpenAPI.hs missing get operation in PathItem - fix not applied"
    test_status=1
fi

# Check OpenAPI.hs - HEAD should use makeProcPostParams (not just makeProcParam)
echo "Checking src/PostgREST/Response/OpenAPI.hs has makeProcPostParams..."
if grep -q "makeProcPostParams" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has makeProcPostParams function"
else
    echo "✗ OpenAPI.hs missing makeProcPostParams - fix not applied"
    test_status=1
fi

# Check test file - HEAD should have test for GET path item
echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs has test for GET path item..."
if grep -q "includes function summary/description and query parameters for arguments in the get path item" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test file has test for GET path item with query parameters"
else
    echo "✗ Test file missing test for GET path item - fix not applied"
    test_status=1
fi

# Check test file - HEAD should have test for VARIADIC parameter with multi collection format
echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs has test for VARIADIC parameter..."
if grep -q "uses a multi collection format when the function has a VARIADIC parameter" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test file has test for VARIADIC parameter"
else
    echo "✗ Test file missing test for VARIADIC parameter - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - GET path item for RPCs properly added to OpenAPI output"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
