#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.yaml" "test/io/fixtures.yaml"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"

# Verify source code matches HEAD state (jwt-aud validation fix applied)
# This is PR #4140 which ADDS the fix for jwt-aud URI validation
# HEAD state (c702d4fa6a) = fix applied, validates jwt-aud as StringOrURI
# BASE state (with bug.patch) = broken validation (bug state)
# ORACLE state (BASE + fix.patch) = proper validation (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (jwt-aud validation fix applied)..."
echo ""

echo "Checking that Config.hs imports isURI..."
if grep -q "import Network.URI.*isURI" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs imports isURI - fix applied!"
else
    echo "✗ Config.hs does not import isURI - fix not applied"
    test_status=1
fi

echo "Checking that parser uses optStringOrURI for jwt-aud..."
if grep -q "optStringOrURI \"jwt-aud\"" "src/PostgREST/Config.hs"; then
    echo "✓ Parser uses optStringOrURI for jwt-aud - fix applied!"
else
    echo "✗ Parser does not use optStringOrURI for jwt-aud - fix not applied"
    test_status=1
fi

echo "Checking that optStringOrURI function exists..."
if grep -q "optStringOrURI :: C.Key -> C.Parser C.Config (Maybe Text)" "src/PostgREST/Config.hs"; then
    echo "✓ optStringOrURI function exists - fix applied!"
else
    echo "✗ optStringOrURI function does not exist - fix not applied"
    test_status=1
fi

echo "Checking that validateURI helper exists..."
if grep -q "validateURI :: Text -> C.Parser C.Config (Maybe Text)" "src/PostgREST/Config.hs"; then
    echo "✓ validateURI helper exists - fix applied!"
else
    echo "✗ validateURI helper does not exist - fix not applied"
    test_status=1
fi

echo "Checking that validation uses isURI function..."
if grep -q "if isURI (T.unpack s)" "src/PostgREST/Config.hs"; then
    echo "✓ Validation uses isURI function - fix applied!"
else
    echo "✗ Validation does not use isURI function - fix not applied"
    test_status=1
fi

echo "Checking that error message is correct..."
if grep -q "jwt-aud should be a string or a valid URI" "src/PostgREST/Config.hs"; then
    echo "✓ Error message is correct - fix applied!"
else
    echo "✗ Error message is incorrect - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test file includes invalid jwt-aud test..."
if grep -q "def test_jwt_aud_config_set_to_invalid_uri" "test/io/test_cli.py"; then
    echo "✓ Test file includes test_jwt_aud_config_set_to_invalid_uri - test from HEAD!"
else
    echo "✗ Test file does not include test_jwt_aud_config_set_to_invalid_uri - test not from HEAD"
    test_status=1
fi

echo "Checking that test expects PostgrestError..."
if grep -A10 "def test_jwt_aud_config_set_to_invalid_uri" "test/io/test_cli.py" | grep -q "with pytest.raises(PostgrestError)"; then
    echo "✓ Test expects PostgrestError for invalid jwt-aud - test from HEAD!"
else
    echo "✗ Test does not properly check for error - test not from HEAD"
    test_status=1
fi

echo "Checking that fixtures.yaml includes invalid jwt-aud test case..."
if grep -q "name: invalid jwt-aud" "test/io/fixtures.yaml" && ! grep -q "# TODO: Bug needs to be fixed" "test/io/fixtures.yaml"; then
    echo "✓ Fixtures include invalid jwt-aud test case - test from HEAD!"
else
    echo "✗ Fixtures do not include proper invalid jwt-aud test case - test not from HEAD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
