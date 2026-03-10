#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

# Verify that the fix has been applied by checking test file changes
test_status=0

echo "Verifying fix has been applied to test files..."
echo ""

# Check InsertSpec.hs has the correct error message for malformed JSON
echo "Checking InsertSpec.hs for 'Empty or invalid json' message (malformed JSON)..."
if grep -q '^\s*\[json|{"message":"Empty or invalid json","code":"PGRST102","details":null,"hint":null}|\]$' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has correct error message for malformed JSON"
else
    echo "✗ InsertSpec.hs missing correct error message for malformed JSON - fix not applied"
    echo "  Expected: [json|{\"message\":\"Empty or invalid json\",\"code\":\"PGRST102\",\"details\":null,\"hint\":null}|]"
    echo "  Context: Should appear around line 290 in the 'fails with 400 and error' test for '}{ x = 2'"
    test_status=1
fi

# Check InsertSpec.hs has the correct error message for empty JSON
echo "Checking InsertSpec.hs for 'Empty or invalid json' message (empty body)..."
if grep -A2 'post "/simple_pk" ""' "test/spec/Feature/Query/InsertSpec.hs" | grep -q 'Empty or invalid json'; then
    echo "✓ InsertSpec.hs has correct error message for empty body"
else
    echo "✗ InsertSpec.hs missing correct error message for empty body - fix not applied"
    echo "  Expected: [json|{\"message\":\"Empty or invalid json\",\"code\":\"PGRST102\",\"details\":null,\"hint\":null}|]"
    echo "  Context: Should appear around line 299 after 'post \"/simple_pk\" \"\"'"
    test_status=1
fi

# Check UpdateSpec.hs has the correct error message for malformed JSON
echo "Checking UpdateSpec.hs for 'Empty or invalid json' message (malformed JSON)..."
if grep -q '^\s*\[json|{"message":"Empty or invalid json","code":"PGRST102","details":null,"hint":null}|\]$' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has correct error message for malformed JSON"
else
    echo "✗ UpdateSpec.hs missing correct error message for malformed JSON - fix not applied"
    echo "  Expected: [json|{\"message\":\"Empty or invalid json\",\"code\":\"PGRST102\",\"details\":null,\"hint\":null}|]"
    echo "  Context: Should appear around line 47 in the 'fails with 400 and error' test for '}{ x = 2'"
    test_status=1
fi

# Check UpdateSpec.hs has the correct error message for empty JSON
echo "Checking UpdateSpec.hs for 'Empty or invalid json' message (empty body)..."
if grep -A2 'request methodPatch "/items" \[\] ""' "test/spec/Feature/Query/UpdateSpec.hs" | grep -q 'Empty or invalid json'; then
    echo "✓ UpdateSpec.hs has correct error message for empty body"
else
    echo "✗ UpdateSpec.hs missing correct error message for empty body - fix not applied"
    echo "  Expected: [json|{\"message\":\"Empty or invalid json\",\"code\":\"PGRST102\",\"details\":null,\"hint\":null}|]"
    echo "  Context: Should appear around line 56 after 'request methodPatch \"/items\" [] \"\"'"
    test_status=1
fi

# Check ApiRequest.hs for the fix
echo "Checking ApiRequest.hs for the generic error message logic..."
if grep -q "maybe (Left \"Empty or invalid json\") Right \$ JSON.decode reqBody" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs has the generic error message logic"
else
    echo "✗ ApiRequest.hs missing generic error message logic - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md for the entry
echo "Checking CHANGELOG.md for the fix entry..."
if grep -q "#2344, Replace JSON parser error with a clearer generic message" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
