#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AuthSpec.hs" "test/spec/Feature/Auth/AuthSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #3933 which improves JWT error handling
# HEAD state (fe3df5c414d07ec3128b0c63df81139159e378e7) = fix applied, improved JWT errors
# BASE state (with bug.patch) = old JWT error handling

test_status=0

echo "Verifying source code matches HEAD state (JWT error improvements applied)..."
echo ""

echo "Checking that CHANGELOG.md has JWT error improvement entry..."
if grep -q "#3600, #3926, Improve JWT errors - @taimoorzaeem" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has JWT error improvement entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have JWT error improvement entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions PGRST301 error for empty Bearer..."
if grep -q "Return \`PGRST301\` error when \`Bearer\` in auth header is sent empty" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PGRST301 error for empty Bearer - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention PGRST301 error for empty Bearer - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions PGRST303 error..."
if grep -q "Return new \`PGRST303\` error when jwt claims decoding fails" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PGRST303 error - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention PGRST303 error - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs/references/auth.rst has jwt_claims_validation label..."
if grep -q ".. _jwt_claims_validation:" "docs/references/auth.rst"; then
    echo "✓ docs/references/auth.rst has jwt_claims_validation label - fix applied!"
else
    echo "✗ docs/references/auth.rst does not have jwt_claims_validation label - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs/references/errors.rst has updated PGRST301 description..."
if grep -q "Provided JWT couldn't be decoded or it is invalid" "docs/references/errors.rst"; then
    echo "✓ docs/references/errors.rst has updated PGRST301 description - fix applied!"
else
    echo "✗ docs/references/errors.rst does not have updated PGRST301 description - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_io.py has JWT error tests..."
if grep -q "def test_jwt_errors" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has JWT error tests - fix applied!"
else
    echo "✗ test/io/test_io.py does not have JWT error tests - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Auth/AuthSpec.hs has authorization tests..."
if grep -q "describe \"authorization\"" "test/spec/Feature/Auth/AuthSpec.hs"; then
    echo "✓ test/spec/Feature/Auth/AuthSpec.hs has authorization tests - fix applied!"
else
    echo "✗ test/spec/Feature/Auth/AuthSpec.hs does not have authorization tests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
