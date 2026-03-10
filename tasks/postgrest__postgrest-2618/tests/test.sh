#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

test_status=0

echo "Verifying fix for embedded resource ordering on PATCH (PR #2618)..."
echo ""
echo "NOTE: This PR refactors RPC param parsing to fix embedded ordering"
echo "HEAD (fixed) should have isRpcGet Bool parameter and parse query params AFTER pathInfo"
echo "BASE (buggy) has no Bool parameter and parses query params BEFORE pathInfo"
echo ""

# Check ApiRequest.hs - HEAD should parse query params AFTER getting pathInfo/action
echo "Checking src/PostgREST/ApiRequest.hs parses query params after pathInfo..."
if grep -B 2 "qPrms <- first QueryParamError" "src/PostgREST/ApiRequest.hs" | grep -q "pInfo <- getPathInfo" && \
   grep -B 1 "qPrms <- first QueryParamError" "src/PostgREST/ApiRequest.hs" | grep -q "act <- getAction"; then
    echo "✓ ApiRequest.hs parses query params after pathInfo and action"
else
    echo "✗ ApiRequest.hs has wrong parsing order - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should pass isRpcGet flag to parse
echo "Checking src/PostgREST/ApiRequest.hs passes isRpcGet flag to parse..."
if grep -q "QueryParams.parse (pathIsProc pInfo && act" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes isRpcGet flag to QueryParams.parse"
else
    echo "✗ ApiRequest.hs missing isRpcGet flag - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have Bool parameter in parse signature
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has Bool parameter in parse signature..."
if grep -q "^parse :: Bool -> ByteString -> Either QPError QueryParams" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has Bool parameter in parse signature"
else
    echo "✗ QueryParams.hs missing Bool parameter - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have do-notation style parsing with isRpcGet
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has do-notation parsing with isRpcGet..."
if grep -q "parse isRpcGet qs = do" "src/PostgREST/ApiRequest/QueryParams.hs" && \
   grep -q "pRequestFilter isRpcGet" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has do-notation parsing with isRpcGet parameter"
else
    echo "✗ QueryParams.hs missing do-notation or isRpcGet usage - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have hasOp and hasRootFilter helper functions
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has hasOp and hasRootFilter helpers..."
if grep -q "hasRootFilter, hasOp ::" "src/PostgREST/ApiRequest/QueryParams.hs" || \
   (grep -q "hasRootFilter" "src/PostgREST/ApiRequest/QueryParams.hs" && grep -q "hasOp" "src/PostgREST/ApiRequest/QueryParams.hs"); then
    echo "✓ QueryParams.hs has hasOp and hasRootFilter helper functions"
else
    echo "✗ QueryParams.hs missing helper functions - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - embedded ordering on PATCH properly fixed"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
