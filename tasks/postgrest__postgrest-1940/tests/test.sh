#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/data.sql" "test/fixtures/data.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #1940 which fixes handling of double quotes and backslashes in "in" filters
# HEAD state (b5cd092ff057464d00221f941b6afd87d51db6a5) = fix for escaping in "in" filters - FIXED
# BASE state (with bug.patch) = no escaping support, malformed array literals - BUGGY
# ORACLE state (BASE + fix.patch) = escaping support restored - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for double quotes and backslashes in 'in' filters)..."
echo ""

echo "Checking that CHANGELOG mentions the escaping feature..."
if grep -q "#1938, Allow escaping inside double quotes with a backslash" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions escaping feature - fix applied!"
else
    echo "✗ CHANGELOG missing escaping feature - fix not applied"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the bugfix for quotes and backslashes..."
if grep -q '#1938, Fix using single double quotes.*".*and backslashes.*as values on the "in" operator' "CHANGELOG.md"; then
    echo "✓ CHANGELOG has bugfix entry - fix applied!"
else
    echo "✗ CHANGELOG missing bugfix entry - fix not applied"
    test_status=1
fi

echo "Checking that SqlFragment.hs has pgFmtArrayLit function..."
if grep -q "pgFmtArrayLit" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has pgFmtArrayLit function - fix applied!"
else
    echo "✗ SqlFragment.hs missing pgFmtArrayLit function - fix not applied"
    test_status=1
fi

echo "Checking that SqlFragment.hs uses pgFmtArrayLit in In filter..."
if grep -q "pgFmtArrayLit vals" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs uses pgFmtArrayLit - fix applied!"
else
    echo "✗ SqlFragment.hs doesn't use pgFmtArrayLit - fix not applied"
    test_status=1
fi

echo "Checking that Parsers.hs has pCharsOrSlashed parser..."
if grep -q "pCharsOrSlashed" "src/PostgREST/Request/Parsers.hs"; then
    echo "✓ Parsers.hs has pCharsOrSlashed parser - fix applied!"
else
    echo "✗ Parsers.hs missing pCharsOrSlashed parser - fix not applied"
    test_status=1
fi

echo "Checking that QuerySpec.hs has test for escaped double quotes..."
if grep -q 'accepts escaped double quotes' "test/Feature/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has escaped double quotes test - fix applied!"
else
    echo "✗ QuerySpec.hs missing escaped double quotes test - fix not applied"
    test_status=1
fi

echo "Checking that QuerySpec.hs has test for escaped backslashes..."
if grep -q 'accepts escaped backslashes' "test/Feature/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has escaped backslashes test - fix applied!"
else
    echo "✗ QuerySpec.hs missing escaped backslashes test - fix not applied"
    test_status=1
fi

echo "Checking that data.sql has test data with double quotes..."
if grep -q 'Double"Quote"McGraw"' "test/fixtures/data.sql"; then
    echo "✓ data.sql has double quote test data - fix applied!"
else
    echo "✗ data.sql missing double quote test data - fix not applied"
    test_status=1
fi

echo "Checking that data.sql has test data with backslashes..."
if grep -q '/\\Slash/\\Beast' "test/fixtures/data.sql"; then
    echo "✓ data.sql has backslash test data - fix applied!"
else
    echo "✗ data.sql missing backslash test data - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
