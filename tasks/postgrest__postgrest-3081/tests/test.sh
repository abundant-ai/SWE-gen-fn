#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/JsonOperatorSpec.hs" "test/spec/Feature/Query/JsonOperatorSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"

# Verify that the fix has been applied by checking test file and source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check CHANGELOG.md for the fix entry
echo "Checking CHANGELOG.md for the fix entry..."
if grep -q "#3054, Fix not allowing special characters in JSON keys" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check QueryParams.hs for pJsonKeyName function
echo "Checking QueryParams.hs for pJsonKeyName function..."
if grep -q "pJsonKeyName :: Parser Text" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has pJsonKeyName function"
else
    echo "✗ QueryParams.hs missing pJsonKeyName function - fix not applied"
    test_status=1
fi

# Check QueryParams.hs for pJsonKeyIdentifier function
echo "Checking QueryParams.hs for pJsonKeyIdentifier function..."
if grep -q "pJsonKeyIdentifier :: Parser Text" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has pJsonKeyIdentifier function"
else
    echo "✗ QueryParams.hs missing pJsonKeyIdentifier function - fix not applied"
    test_status=1
fi

# Check QueryParams.hs for sepByDash function
echo "Checking QueryParams.hs for sepByDash function..."
if grep -q "sepByDash :: Parser Text -> Parser Text" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has sepByDash function"
else
    echo "✗ QueryParams.hs missing sepByDash function - fix not applied"
    test_status=1
fi

# Check QueryParams.hs for special character doctest examples
echo "Checking QueryParams.hs for special character doctest examples..."
if grep -q 'P.parse pJsonPath "" "->!@#' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has special character doctest examples"
else
    echo "✗ QueryParams.hs missing special character doctest examples - fix not applied"
    test_status=1
fi

# Check QueryParams.hs uses pJsonKeyName instead of pFieldName in pJsonOperand
echo "Checking QueryParams.hs uses pJsonKeyName in pJsonOperand..."
if grep -A 2 "pJsonOperand =" "src/PostgREST/ApiRequest/QueryParams.hs" | grep -q "pJsonKeyName"; then
    echo "✓ QueryParams.hs uses pJsonKeyName in pJsonOperand"
else
    echo "✗ QueryParams.hs not using pJsonKeyName in pJsonOperand - fix not applied"
    test_status=1
fi

# Check JsonOperatorSpec.hs has tests for special characters in keys
echo "Checking JsonOperatorSpec.hs for special character tests..."
if grep -q 'it "accepts non reserved special characters in the key'"'"'s name"' "test/spec/Feature/Query/JsonOperatorSpec.hs"; then
    echo "✓ JsonOperatorSpec.hs has special character acceptance test"
else
    echo "✗ JsonOperatorSpec.hs missing special character acceptance test - fix not applied"
    test_status=1
fi

# Check JsonOperatorSpec.hs has test with actual special characters
echo "Checking JsonOperatorSpec.hs for actual special character usage..."
if grep -q '!@#\$%\^\%26\*_d' "test/spec/Feature/Query/JsonOperatorSpec.hs"; then
    echo "✓ JsonOperatorSpec.hs has tests with special characters"
else
    echo "✗ JsonOperatorSpec.hs missing tests with special characters - fix not applied"
    test_status=1
fi

# Check JsonOperatorSpec.hs has filter test for special characters
echo "Checking JsonOperatorSpec.hs for filter test with special characters..."
if grep -q 'it "can filter when the key'"'"'s name has non reserved special characters"' "test/spec/Feature/Query/JsonOperatorSpec.hs"; then
    echo "✓ JsonOperatorSpec.hs has filter test with special characters"
else
    echo "✗ JsonOperatorSpec.hs missing filter test with special characters - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
