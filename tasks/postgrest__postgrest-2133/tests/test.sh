#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/QuerySpec.hs" "test/spec/Feature/QuerySpec.hs"

test_status=0

echo "Verifying fix for silently ignoring filter on non-existent embedded resource (PR #2133)..."
echo ""
echo "This PR fixes PostgREST to return 400 error instead of silently ignoring filters"
echo "on non-existent embedded resources."
echo ""

echo "Checking Error.hs has NotEmbedded in Error data type..."
if [ -f "src/PostgREST/Request/Types.hs" ]; then
    # The fix adds NotEmbedded Text to the ApiRequestError data type
    if grep -A30 'data ApiRequestError' "src/PostgREST/Request/Types.hs" | grep -q 'NotEmbedded Text'; then
        echo "✓ Types.hs includes NotEmbedded in ApiRequestError type (fix applied)"
    else
        echo "✗ Types.hs does not include NotEmbedded in ApiRequestError type (not fixed)"
        test_status=1
    fi
else
    echo "✗ Types.hs not found"
    test_status=1
fi

echo "Checking Error.hs has NotEmbedded with status 400..."
if [ -f "src/PostgREST/Error.hs" ]; then
    if grep -q 'status (NotEmbedded _).*HTTP.status400' "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs includes NotEmbedded status 400 (fix applied)"
    else
        echo "✗ Error.hs does not include NotEmbedded status (not fixed)"
        test_status=1
    fi
else
    echo "✗ Error.hs not found"
    test_status=1
fi

echo "Checking Error.hs has NotEmbedded JSON error message..."
if [ -f "src/PostgREST/Error.hs" ]; then
    if grep -A50 'instance JSON.ToJSON ApiRequestError where' "src/PostgREST/Error.hs" | grep -q 'toJSON (NotEmbedded'; then
        echo "✓ Error.hs includes NotEmbedded JSON message (fix applied)"
    else
        echo "✗ Error.hs does not include NotEmbedded JSON message (not fixed)"
        test_status=1
    fi
else
    echo "✗ Error.hs not found"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs has updateNode function that returns Left NotEmbedded..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ]; then
    # Check for the updateNode function that validates embedded resources
    if grep -A20 'updateNode.*::' "src/PostgREST/Request/DbRequestBuilder.hs" | grep -q 'Left.*NotEmbedded'; then
        echo "✓ DbRequestBuilder.hs includes updateNode with NotEmbedded error (fix applied)"
    else
        echo "✗ DbRequestBuilder.hs does not include updateNode with NotEmbedded error (not fixed)"
        test_status=1
    fi
else
    echo "✗ DbRequestBuilder.hs not found"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

test_file="test/spec/Feature/QuerySpec.hs"
if [ -f "$test_file" ]; then
    echo "✓ $test_file exists (HEAD version)"
else
    echo "✗ $test_file not found - HEAD file not copied!"
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
