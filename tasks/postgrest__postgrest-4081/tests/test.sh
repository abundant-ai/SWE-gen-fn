#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.yaml" "test/io/fixtures.yaml"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4081 which fixes JWT error returning HTTP status 400 for invalid role (should be 401)
# HEAD state (11b679448e4) = fix applied
# BASE state (with bug.patch) = returns 400 for invalid role
# ORACLE state (BASE + fix.patch) = returns 401 for invalid role

test_status=0

echo "Verifying source code matches HEAD state (JWT invalid role returns 401)..."
echo ""

echo "Checking that Error.hs includes the 22023 error code handler for invalid role..."
if grep -q '"22023"   -> -- invalid_parameter_value. Catch nonexistent role error' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has 22023 error code handler - fix applied!"
else
    echo "✗ Error.hs missing 22023 error code handler - fix not applied"
    test_status=1
fi

echo "Checking that Error.hs returns 401 for nonexistent role..."
if grep -q 'if BS.isPrefixOf "role" m && BS.isSuffixOf "does not exist" m' "src/PostgREST/Error.hs" && \
   grep -q 'then HTTP.status401 -- role in jwt does not exist' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs returns 401 for nonexistent role - fix applied!"
else
    echo "✗ Error.hs not returning 401 for nonexistent role - fix not applied"
    test_status=1
fi

echo "Checking that test file expects 401 for invalid role..."
if grep -q 'assert response.status_code == 401' "test/io/test_io.py" && \
   ! grep -q '# TODO: Should this return 401?' "test/io/test_io.py"; then
    echo "✓ test_io.py expects 401 for invalid role - test from HEAD!"
else
    echo "✗ test_io.py does not expect 401 for invalid role - test not from HEAD"
    test_status=1
fi

echo "Checking that fixtures.yaml expects 401 for invalid role..."
if grep -q 'expected_status: 401' "test/io/fixtures.yaml"; then
    echo "✓ fixtures.yaml expects 401 for invalid role - test from HEAD!"
else
    echo "✗ fixtures.yaml does not expect 401 for invalid role - test not from HEAD"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the JWT error fix..."
if grep -q "Fix jwt error returning HTTP status \`400\` for invalid role" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions JWT error fix - fix applied!"
else
    echo "✗ CHANGELOG does not mention JWT error fix - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
