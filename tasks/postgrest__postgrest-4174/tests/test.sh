#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

test_status=0

echo "Verifying fix for OpenAPI volatile function GET method (PR #4174)..."
echo ""
echo "NOTE: This PR fixes OpenAPI to respect function volatility for GET methods"
echo "BASE (buggy) exposes GET methods for all functions including volatile ones"
echo "HEAD (fixed) only exposes GET methods for stable and immutable functions, not volatile"
echo ""

# Check that the fix was applied to OpenAPI.hs - look for pdVolatility usage
echo "Checking src/PostgREST/Response/OpenAPI.hs uses pdVolatility..."
if grep -q "pdVolatility" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs checks function volatility with pdVolatility"
else
    echo "✗ OpenAPI.hs does not use pdVolatility - fix not applied"
    test_status=1
fi

# Check that FuncVolatility import is present (needed for volatility check)
echo "Checking OpenAPI.hs imports FuncVolatility..."
if grep -q "FuncVolatility" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ FuncVolatility is imported"
else
    echo "✗ FuncVolatility not imported - fix not applied"
    test_status=1
fi

# Check that the case expression is used with Volatile pattern
echo "Checking code contains Volatile case pattern..."
if grep -q "Volatile ->" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ Code contains Volatile case pattern"
else
    echo "✗ Code does not contain Volatile case pattern - fix not applied"
    test_status=1
fi

# Check that CHANGELOG mentions the volatile function fix
echo "Checking CHANGELOG.md mentions volatile function OpenAPI fix..."
if grep -q "volatile function" "CHANGELOG.md" && grep -q "OpenAPI" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions volatile function OpenAPI fix"
else
    echo "✗ CHANGELOG does not mention fix - not documented"
    test_status=1
fi

# Check that test file contains the new test cases for volatility
echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs contains volatility tests..."
if grep -q "only includes POST method for volatile functions" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test for volatile functions exists"
else
    echo "✗ Test for volatile functions not found - fix not applied"
    test_status=1
fi

# Check that test validates stable functions have GET method
echo "Checking test validates stable functions have GET method..."
if grep -q "includes GET and POST methods for stable functions" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test for stable functions exists"
else
    echo "✗ Test for stable functions not found - fix not applied"
    test_status=1
fi

# Check that test validates immutable functions have GET method
echo "Checking test validates immutable functions have GET method..."
if grep -q "includes GET and POST methods for immutable functions" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test for immutable functions exists"
else
    echo "✗ Test for immutable functions not found - fix not applied"
    test_status=1
fi

# Check that test uses reset_table (volatile function example)
echo "Checking test uses reset_table as volatile function example..."
if grep -q "reset_table" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ Test references reset_table volatile function"
else
    echo "✗ Test does not reference reset_table - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - OpenAPI volatile function fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
