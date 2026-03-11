#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for GET requests to RPC functions with Content-Type headers (PR #2168)..."
echo ""
echo "This PR fixes GET requests to RPC functions with no parameters incorrectly returning 404"
echo "when the request includes Content-Type headers like text/plain or application/octet-stream."
echo ""

echo "Checking ApiRequest.hs has the correct fix for Content-Type handling..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q 'then null argumentsKeys && not (isInvPost && contentType' "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs has correct Content-Type handling (fix applied)"
else
    echo "✗ ApiRequest.hs does not have correct Content-Type handling (not fixed)"
    test_status=1
fi

echo "Checking CHANGELOG.md has entry for PR #2147..."
if [ -f "CHANGELOG.md" ] && grep -q '#2147' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for PR #2147 (fix applied)"
else
    echo "✗ CHANGELOG.md missing entry for PR #2147 (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test file exists..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ]; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs exists (HEAD version)"
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking RpcSpec.hs has test for Content-Type headers with GET..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ] && grep -q 'should call the function with no parameters and not fallback to the single unnamed parameter function when using GET with Content-Type headers' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs contains Content-Type GET test (HEAD version)"
else
    echo "✗ RpcSpec.hs does not contain Content-Type GET test - HEAD file not properly copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
