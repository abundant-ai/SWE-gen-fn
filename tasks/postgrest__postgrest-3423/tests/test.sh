#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking test file changes
test_status=0

echo "Verifying test file matches HEAD state (fix applied)..."
echo ""

# Check that error message for invalid JSON in MESSAGE has detailed error
echo "Checking that error message for invalid JSON in MESSAGE option is detailed..."
if grep -q 'it "returns error for invalid JSON in the MESSAGE option of the RAISE statement"' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ Test description for MESSAGE option found - fix applied!"
else
    echo "✗ Test description for MESSAGE option not found - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error expectation includes detailed MESSAGE error..."
if grep -q 'Invalid JSON value for MESSAGE' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ Detailed MESSAGE error found in test expectations - fix applied!"
else
    echo "✗ Detailed MESSAGE error not found in test expectations - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error includes hint for MESSAGE format..."
if grep -q 'MESSAGE must be a JSON object with obligatory keys' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ MESSAGE format hint found in test expectations - fix applied!"
else
    echo "✗ MESSAGE format hint not found - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error message for invalid JSON in DETAIL option is detailed..."
if grep -q 'it "returns error for invalid JSON in the DETAIL option of the RAISE statement"' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ Test description for DETAIL option found - fix applied!"
else
    echo "✗ Test description for DETAIL option not found - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error expectation includes detailed DETAIL error..."
if grep -q 'Invalid JSON value for DETAIL' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ Detailed DETAIL error found in test expectations - fix applied!"
else
    echo "✗ Detailed DETAIL error not found in test expectations - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error message for missing DETAIL option is detailed..."
if grep -q 'it "returns error for missing DETAIL option in the RAISE statement"' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ Test description for missing DETAIL found - fix applied!"
else
    echo "✗ Test description for missing DETAIL not found - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that error includes DETAIL missing message..."
if grep -q 'DETAIL is missing in the RAISE statement' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ DETAIL missing message found in test expectations - fix applied!"
else
    echo "✗ DETAIL missing message not found - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
