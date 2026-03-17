#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/OpenApiSpec.hs" "test/Feature/OpenApiSpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/privileges.sql" "test/fixtures/privileges.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #1928 which fixes OpenAPI default values for String types and Array type detection
# HEAD state (553a3c32b1d884e3d791769fad3ff0c1a2870acc) = fix for OpenAPI defaults - FIXED
# BASE state (with bug.patch) = OpenAPI missing default values for strings - BUGGY
# ORACLE state (BASE + fix.patch) = OpenAPI includes default values properly - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for OpenAPI default values)..."
echo ""

echo "Checking that CHANGELOG mentions the bugfix for OpenAPI default values..."
if grep -q '#1871, Fix OpenAPI missing default values for String types and identify Array types as "array" instead of "string"' "CHANGELOG.md"; then
    echo "✓ CHANGELOG has bugfix entry - fix applied!"
else
    echo "✗ CHANGELOG missing bugfix entry - fix not applied"
    test_status=1
fi

echo "Checking that OpenAPI.hs has parseDefault function for handling string defaults..."
if grep -q "parseDefault :: Text -> Text -> Text" "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has parseDefault function - fix applied!"
else
    echo "✗ OpenAPI.hs missing parseDefault function - fix not applied"
    test_status=1
fi

echo "Checking that OpenAPI.hs recognizes ARRAY type as SwaggerArray..."
if grep -q 'toSwaggerType "ARRAY".*= SwaggerArray' "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs maps ARRAY to SwaggerArray - fix applied!"
else
    echo "✗ OpenAPI.hs doesn't map ARRAY to SwaggerArray - fix not applied"
    test_status=1
fi

echo "Checking that OpenAPI.hs uses parseDefault to process column defaults..."
if grep -q "parseDefault (colType c)" "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs uses parseDefault for column defaults - fix applied!"
else
    echo "✗ OpenAPI.hs doesn't use parseDefault - fix not applied"
    test_status=1
fi

echo "Checking that OpenApiSpec.hs has test for text default value..."
if grep -q '"openapi_defaults".*"text".*"default"' "test/Feature/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs has text default value test - fix applied!"
else
    echo "✗ OpenApiSpec.hs missing text default value test - fix not applied"
    test_status=1
fi

echo "Checking that schema.sql has openapi_defaults table..."
if grep -q "CREATE TABLE test.openapi_defaults" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has openapi_defaults table - fix applied!"
else
    echo "✗ schema.sql missing openapi_defaults table - fix not applied"
    test_status=1
fi

echo "Checking that privileges.sql grants access to openapi_defaults..."
if grep -q "openapi_defaults" "test/fixtures/privileges.sql"; then
    echo "✓ privileges.sql grants access to openapi_defaults - fix applied!"
else
    echo "✗ privileges.sql missing openapi_defaults grant - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
