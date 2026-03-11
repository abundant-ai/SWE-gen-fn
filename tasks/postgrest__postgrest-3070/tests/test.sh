#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ServerTimingSpec.hs" "test/spec/Feature/Query/ServerTimingSpec.hs"

test_status=0

echo "Verifying Server-Timing metric renaming (PR #3070)..."
echo ""
echo "NOTE: This PR renames Server-Timing metric from 'render' to 'response'"
echo "BASE (buggy) uses SMRender and renderTime' variables, tests expect 'render'"
echo "HEAD (fixed) uses SMResp and respTime' variables, tests expect 'response'"
echo ""

# Check that App.hs uses SMResp (not SMRender)
echo "Checking src/PostgREST/App.hs uses SMResp..."
if grep -q "SMResp" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses SMResp"
else
    echo "✗ App.hs does not use SMResp (still using SMRender) - fix not applied"
    test_status=1
fi

# Check that App.hs uses respTime' variable (not renderTime')
echo "Checking src/PostgREST/App.hs uses respTime'..."
if grep -q "respTime'" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses respTime' variable"
else
    echo "✗ App.hs does not use respTime' (still using renderTime') - fix not applied"
    test_status=1
fi

# Check that Performance.hs defines SMResp (not SMRender)
echo "Checking src/PostgREST/Response/Performance.hs defines SMResp..."
if grep -q "SMResp" "src/PostgREST/Response/Performance.hs"; then
    echo "✓ Performance.hs defines SMResp"
else
    echo "✗ Performance.hs does not define SMResp (still using SMRender) - fix not applied"
    test_status=1
fi

# Check that Performance.hs renders as "response" not "render"
echo "Checking src/PostgREST/Response/Performance.hs outputs 'response'..."
if grep -q '"response"' "src/PostgREST/Response/Performance.hs"; then
    echo "✓ Performance.hs outputs 'response' in Server-Timing header"
else
    echo "✗ Performance.hs does not output 'response' (still using 'render') - fix not applied"
    test_status=1
fi

# Check that App.hs doesn't have SMRender (should be fully replaced)
echo "Checking src/PostgREST/App.hs has no SMRender references..."
if ! grep -q "SMRender" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has no SMRender references"
else
    echo "✗ App.hs still has SMRender references - fix not fully applied"
    test_status=1
fi

# Check that App.hs doesn't have renderTime' (should be fully replaced)
echo "Checking src/PostgREST/App.hs has no renderTime' references..."
if ! grep -q "renderTime'" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has no renderTime' references"
else
    echo "✗ App.hs still has renderTime' references - fix not fully applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - Server-Timing metric renamed from 'render' to 'response'"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
