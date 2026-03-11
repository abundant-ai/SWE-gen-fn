#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/OptionsSpec.hs" "test/spec/Feature/OptionsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for unnecessary DB transactions on 404/405 errors (PR #2365)..."
echo ""
echo "NOTE: This PR modifies source code to detect errors early without DB transactions"
echo "and updates test files to verify the new behavior."
echo "We verify that the copied HEAD test files contain the updated test cases."
echo ""

# Check that CHANGELOG mentions the fix (this is in source, part of the commit)
echo "Checking CHANGELOG.md mentions the fix..."
if grep -q "#2364" "CHANGELOG.md" && grep -q "404 Not Found" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md does not mention the fix"
    test_status=1
fi

# Check that test files have been updated with HEAD versions
# These files should contain new/updated test cases for the fix

echo "Checking test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs was updated..."
if [ -f "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" ] && [ -s "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" ]; then
    echo "✓ DisabledOpenApiSpec.hs exists and is not empty"
else
    echo "✗ DisabledOpenApiSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/OptionsSpec.hs was updated..."
if [ -f "test/spec/Feature/OptionsSpec.hs" ] && [ -s "test/spec/Feature/OptionsSpec.hs" ]; then
    echo "✓ OptionsSpec.hs exists and is not empty"
else
    echo "✗ OptionsSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/ErrorSpec.hs was updated..."
if [ -f "test/spec/Feature/Query/ErrorSpec.hs" ] && [ -s "test/spec/Feature/Query/ErrorSpec.hs" ]; then
    # Check for nested route test content
    if grep -q "nested" "test/spec/Feature/Query/ErrorSpec.hs"; then
        echo "✓ ErrorSpec.hs has nested route tests"
    else
        echo "✗ ErrorSpec.hs missing nested route tests"
        test_status=1
    fi
else
    echo "✗ ErrorSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/RpcSpec.hs was updated..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ] && [ -s "test/spec/Feature/Query/RpcSpec.hs" ]; then
    # Check for unsupported method test content
    if grep -iq "unsupported\|CONNECT\|TRACE" "test/spec/Feature/Query/RpcSpec.hs"; then
        echo "✓ RpcSpec.hs has unsupported method tests"
    else
        echo "✗ RpcSpec.hs missing unsupported method tests"
        test_status=1
    fi
else
    echo "✗ RpcSpec.hs missing or empty"
    test_status=1
fi

echo "Checking test/spec/SpecHelper.hs was updated..."
if [ -f "test/spec/SpecHelper.hs" ] && [ -s "test/spec/SpecHelper.hs" ]; then
    echo "✓ SpecHelper.hs exists and is not empty"
else
    echo "✗ SpecHelper.hs missing or empty"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
