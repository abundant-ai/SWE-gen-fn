#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4051 which improves PGRST301 JWT error details
# HEAD state (63f03fcc) = fix applied, KeyError/BadAlgorithm have Text parameter and details function
# BASE state (with bug.patch) = KeyError/BadAlgorithm without Text parameter, no details
# ORACLE state (BASE + fix.patch) = KeyError/BadAlgorithm with Text parameter, details added

test_status=0

echo "Verifying source code matches HEAD state (improved JWT error details)..."
echo ""

echo "Checking that CHANGELOG mentions the fix..."
if grep -q "Improve error details of \`PGRST301\` error" "CHANGELOG.md" && grep -q "#4051" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs has KeyError and BadAlgorithm with Text parameter..."
if grep -q "KeyError Text" "src/PostgREST/Error.hs" && grep -q "BadAlgorithm Text" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has KeyError/BadAlgorithm with Text parameter - fix applied!"
else
    echo "✗ Error.hs does not have KeyError/BadAlgorithm with Text parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs has details function for JwtDecodeErr..."
if grep -q "details (JwtDecodeErr jde) = case jde of" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has details function for JwtDecodeErr - fix applied!"
else
    echo "✗ Error.hs does not have details function for JwtDecodeErr - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs details function handles KeyError and BadAlgorithm..."
if grep -q "KeyError dets" "src/PostgREST/Error.hs" && grep -q "BadAlgorithm dets" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs details function handles KeyError/BadAlgorithm - fix applied!"
else
    echo "✗ Error.hs details function does not handle KeyError/BadAlgorithm - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs passes error messages to KeyError and BadAlgorithm..."
if grep -q "KeyError m" "src/PostgREST/Auth.hs" && grep -q "BadAlgorithm m" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs passes error messages to KeyError/BadAlgorithm - fix applied!"
else
    echo "✗ Auth.hs does not pass error messages to KeyError/BadAlgorithm - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py test_jwt_errors checks for details in KeyError response..."
if grep -q "response.json()\[\"details\"\] == \"None of the keys was able to decode the JWT\"" "test/io/test_io.py"; then
    echo "✓ test_io.py checks for details in KeyError response - fix applied!"
else
    echo "✗ test_io.py does not check for details in KeyError response - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py test_jwt_errors checks for details in BadAlgorithm response..."
if grep -q "JWT is unsecured but expected 'alg' was not 'none'" "test/io/test_io.py"; then
    echo "✓ test_io.py checks for details in BadAlgorithm response - fix applied!"
else
    echo "✗ test_io.py does not check for details in BadAlgorithm response - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
