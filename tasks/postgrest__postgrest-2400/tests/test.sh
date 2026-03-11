#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

test_status=0

echo "Verifying fix for plan media type 'for' parameter support (PR #2400)..."
echo ""
echo "NOTE: This PR adds support for 'for' parameter in application/vnd.pgrst.plan media type"
echo "BASE (buggy) does not support 'for' parameter"
echo "HEAD (fixed) adds support for 'for' parameter with proper parsing and Content-Type handling"
echo ""

# Check CHANGELOG - HEAD should have 'for' parameter documentation
echo "Checking CHANGELOG.md documents 'for' parameter..."
if grep -q 'Can generate the plan for different media types using the `for` parameter' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md documents 'for' parameter support"
else
    echo "✗ CHANGELOG.md does not document 'for' parameter - fix not applied"
    test_status=1
fi

# Check that CHANGELOG mentions both options and for parameters
if grep -q 'Different options for the plan can be used with the `options` parameter' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md documents 'options' parameter"
else
    echo "✗ CHANGELOG.md does not properly document parameters - fix not applied"
    test_status=1
fi

# Check MediaType.hs - HEAD should have 'for' parameter in MTPlanAttrs
echo "Checking src/PostgREST/MediaType.hs has MTPlanAttrs with Maybe MediaType..."
if grep -q "data MTPlanAttrs = MTPlanAttrs (Maybe MediaType) MTPlanFormat \[MTPlanOption\]" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has MTPlanAttrs with (Maybe MediaType) for 'for' parameter"
else
    echo "✗ MediaType.hs does not have proper MTPlanAttrs definition - fix not applied"
    test_status=1
fi

# Check that getMediaType function exists
if grep -q "getMediaType :: MediaType -> MediaType" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs exports getMediaType function"
else
    echo "✗ MediaType.hs does not export getMediaType - fix not applied"
    test_status=1
fi

# Check that toMime includes 'for' parameter in output
if grep -q 'for=\\"' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs toMime includes 'for' parameter in output"
else
    echo "✗ MediaType.hs toMime does not include 'for' parameter - fix not applied"
    test_status=1
fi

# Check that decodeMediaType parses 'for' parameter
if grep -q 'mtFor' "src/PostgREST/MediaType.hs" && grep -q 'for=' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs decodeMediaType parses 'for' parameter"
else
    echo "✗ MediaType.hs does not parse 'for' parameter - fix not applied"
    test_status=1
fi

# Check Query/Statements.hs - HEAD should use getMediaType
echo "Checking src/PostgREST/Query/Statements.hs uses getMediaType..."
if grep -q "getMediaType" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Query/Statements.hs uses getMediaType function"
else
    echo "✗ Query/Statements.hs does not use getMediaType - fix not applied"
    test_status=1
fi

# Check that Query/Statements imports getMediaType
if grep -q "getMediaType)" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Query/Statements.hs imports getMediaType"
else
    echo "✗ Query/Statements.hs does not import getMediaType - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should handle MTPlan with 'for' parameter
echo "Checking src/PostgREST/App.hs handles plan media type properly..."
if grep -q "MTPlanAttrs" "src/PostgREST/App.hs"; then
    echo "✓ App.hs references MTPlanAttrs"
else
    echo "✗ App.hs does not handle MTPlanAttrs properly - fix not applied"
    test_status=1
fi

# Check test file - HEAD should have tests for 'for' parameter
echo "Checking test/spec/Feature/Query/PlanSpec.hs has tests for 'for' parameter..."
if grep -q 'for=\\"application/json\\"' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has test for 'for=\"application/json\"'"
else
    echo "✗ PlanSpec.hs does not test 'for' parameter with application/json - fix not applied"
    test_status=1
fi

if grep -q 'for=\\"application/vnd.pgrst.object\\"' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has test for 'for=\"application/vnd.pgrst.object\"'"
else
    echo "✗ PlanSpec.hs does not test 'for' parameter with object type - fix not applied"
    test_status=1
fi

if grep -q 'for=\\"text/xml\\"' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has test for 'for=\"text/xml\"'"
else
    echo "✗ PlanSpec.hs does not test 'for' parameter with text/xml - fix not applied"
    test_status=1
fi

# Check that response Content-Type includes the 'for' parameter
if grep -q 'for=\\"application/json\\"' "test/spec/Feature/Query/PlanSpec.hs" && \
   grep -q 'shouldSatisfy.*Content-Type' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs tests Content-Type header with 'for' parameter"
else
    echo "✗ PlanSpec.hs does not verify Content-Type with 'for' parameter - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should have default plan with Nothing for 'for' parameter
if grep -q "MTPlan \$ MTPlanAttrs Nothing PlanJSON mempty" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs has default MTPlan with Nothing for 'for' parameter"
else
    echo "✗ ApiRequest.hs does not have proper default MTPlan - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - 'for' parameter support applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
