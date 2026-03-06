#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #3960 which adds PGRST125 and PGRST126 error codes
# HEAD state (051ff03f) = fix applied, specific error codes returned
# BASE state (with bug.patch) = generic NotFound error or empty JSON

test_status=0

echo "Verifying source code matches HEAD state (PGRST125/PGRST126 error codes fix applied)..."
echo ""

echo "Checking that CHANGELOG.md has error codes entry..."
if grep -q "#3906, Return \`PGRST125\` and \`PGRST126\` errors instead of empty json" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has error codes entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have error codes entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst documents PGRST125 error..."
if grep -q "PGRST125" "docs/references/errors.rst" && grep -q "Invalid path is specified in request URL" "docs/references/errors.rst"; then
    echo "✓ errors.rst documents PGRST125 - fix applied!"
else
    echo "✗ errors.rst does not document PGRST125 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst documents PGRST126 error..."
if grep -q "PGRST126" "docs/references/errors.rst" && grep -q "Open API config is disabled but API root path is" "docs/references/errors.rst"; then
    echo "✓ errors.rst documents PGRST126 - fix applied!"
else
    echo "✗ errors.rst does not document PGRST126 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ApiRequest.hs uses OpenAPIDisabled error..."
if grep -q "Left OpenAPIDisabled" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs uses OpenAPIDisabled - fix applied!"
else
    echo "✗ ApiRequest.hs does not use OpenAPIDisabled - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ApiRequest.hs uses InvalidResourcePath error..."
if grep -q "Left InvalidResourcePath" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs uses InvalidResourcePath - fix applied!"
else
    echo "✗ ApiRequest.hs does not use InvalidResourcePath - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs defines InvalidResourcePath..."
if grep -q "| InvalidResourcePath" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines InvalidResourcePath - fix applied!"
else
    echo "✗ Error.hs does not define InvalidResourcePath - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs defines OpenAPIDisabled..."
if grep -q "| OpenAPIDisabled" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines OpenAPIDisabled - fix applied!"
else
    echo "✗ Error.hs does not define OpenAPIDisabled - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs defines ApiRequestErrorCode25..."
if grep -q "| ApiRequestErrorCode25" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines ApiRequestErrorCode25 - fix applied!"
else
    echo "✗ Error.hs does not define ApiRequestErrorCode25 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs defines ApiRequestErrorCode26..."
if grep -q "| ApiRequestErrorCode26" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines ApiRequestErrorCode26 - fix applied!"
else
    echo "✗ Error.hs does not define ApiRequestErrorCode26 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs maps ApiRequestErrorCode25 to PGRST125..."
if grep -q 'ApiRequestErrorCode25  -> "PGRST125"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs maps ApiRequestErrorCode25 to PGRST125 - fix applied!"
else
    echo "✗ Error.hs does not map ApiRequestErrorCode25 correctly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs maps ApiRequestErrorCode26 to PGRST126..."
if grep -q 'ApiRequestErrorCode26  -> "PGRST126"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs maps ApiRequestErrorCode26 to PGRST126 - fix applied!"
else
    echo "✗ Error.hs does not map ApiRequestErrorCode26 correctly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs has InvalidResourcePath JSON implementation..."
if grep -q "toJSON InvalidResourcePath = toJsonPgrstError" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has InvalidResourcePath JSON - fix applied!"
else
    echo "✗ Error.hs does not have InvalidResourcePath JSON - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs has OpenAPIDisabled JSON implementation..."
if grep -q "toJSON OpenAPIDisabled = toJsonPgrstError" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has OpenAPIDisabled JSON - fix applied!"
else
    echo "✗ Error.hs does not have OpenAPIDisabled JSON - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs uses fromJust (part of the fix)..."
if grep -q "import Data.Maybe.*fromJust" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs imports fromJust - fix applied!"
else
    echo "✗ Plan.hs does not import fromJust - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs uses TableNotFound instead of NotFound..."
if grep -q "Error.TableNotFound qiSchema qiName" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses TableNotFound - fix applied!"
else
    echo "✗ Response.hs does not use TableNotFound - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
