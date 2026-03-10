#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

test_status=0

echo "Verifying fix for duplicate CHANGELOG entries (PR #2432)..."
echo ""
echo "NOTE: This PR removes duplicate CHANGELOG documentation lines"
echo "BASE (buggy) has duplicate lines about plan formats and PlanJSON as default"
echo "HEAD (fixed) removes duplicate lines and keeps PlanText as default"
echo ""

# Check CHANGELOG - HEAD should NOT have the duplicate lines
echo "Checking CHANGELOG.md does not have duplicate plan documentation..."
if ! grep -q "Limited to generating the plan of a json representation" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md does not have duplicate documentation lines"
else
    echo "✗ CHANGELOG.md still has duplicate lines - fix not applied"
    test_status=1
fi

# Check MediaType.hs - HEAD should have PlanText as default (not PlanJSON)
echo "Checking src/PostgREST/MediaType.hs defaults to PlanText..."
if grep -q '"application/vnd.pgrst.plan":rest.*-> getPlan PlanText rest' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs defaults to PlanText for application/vnd.pgrst.plan"
else
    echo "✗ MediaType.hs does not default to PlanText - fix not applied"
    test_status=1
fi

# Check MediaType.hs - HEAD should have plan+text before plan+json
echo "Checking src/PostgREST/MediaType.hs has plan+text before plan+json..."
if grep -B1 '"application/vnd.pgrst.plan+json":rest' "src/PostgREST/MediaType.hs" | grep -q '"application/vnd.pgrst.plan+text":rest'; then
    echo "✓ MediaType.hs has plan+text declaration before plan+json"
else
    echo "✗ MediaType.hs ordering incorrect - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should use "application/vnd.pgrst.plan+json" (not short version)
echo "Checking test/spec/Feature/Query/PlanSpec.hs uses plan+json Accept header..."
if grep -q 'acceptHdrs "application/vnd.pgrst.plan+json"' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs uses plan+json Accept header"
else
    echo "✗ PlanSpec.hs does not use plan+json Accept header - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should have "outputs in text format by default" test
echo "Checking test/spec/Feature/Query/PlanSpec.hs has text default test..."
if grep -q "outputs in text format by default" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has 'outputs in text format by default' test"
else
    echo "✗ PlanSpec.hs missing text default test - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD text format describe should have nested it blocks
echo "Checking test/spec/Feature/Query/PlanSpec.hs text format has multiple tests..."
# The fixed version should have "describe \"text format\" $ do" with nested tests
if grep -q 'describe "text format" \$ do' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs text format section properly structured with multiple tests"
else
    echo "✗ PlanSpec.hs text format section not properly structured - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - duplicate CHANGELOG entries removed successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
