#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/NullsStrip.hs" "test/spec/Feature/Query/NullsStrip.hs"

test_status=0

echo "Verifying fix for application/vnd.pgrst.array media type support..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for media type fix entry..."
if grep -q '#2899, Fix `application/vnd.pgrst.array` not accepted as a valid mediatype' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has media type fix entry"
else
    echo "✗ CHANGELOG.md missing media type fix entry - fix not applied"
    test_status=1
fi

# Check MediaType.hs has the fix for array media type without +json suffix
echo "Checking MediaType.hs for application/vnd.pgrst.array handler..."
if grep -q '"application/vnd.pgrst.array":rest.*-> checkArrayNullStrip rest' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has application/vnd.pgrst.array handler"
else
    echo "✗ MediaType.hs missing application/vnd.pgrst.array handler - fix not applied"
    test_status=1
fi

# Check test file has the test case for the new media type
echo "Checking NullsStrip.hs for test case..."
if grep -q 'strips nulls when Accept: application/vnd.pgrst.array;nulls=stripped' "test/spec/Feature/Query/NullsStrip.hs"; then
    echo "✓ NullsStrip.hs has test case for application/vnd.pgrst.array"
else
    echo "✗ NullsStrip.hs missing test case - fix not applied"
    test_status=1
fi

# Verify the test includes the correct Accept header
echo "Checking NullsStrip.hs test uses correct Accept header..."
if grep -q '"Accept","application/vnd.pgrst.array;nulls=stripped"' "test/spec/Feature/Query/NullsStrip.hs"; then
    echo "✓ NullsStrip.hs test uses application/vnd.pgrst.array;nulls=stripped header"
else
    echo "✗ NullsStrip.hs test missing correct Accept header - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
