#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

# Verify source code matches HEAD state (fix applied)
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the fix for not_null value..."
if grep -q "#3747, Allow \`not_null\` value for the \`is\` operator" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention not_null in the is operator..."
if grep -q "is.*IS.*checking for exact equality (null,not_null,true,false,unknown)" "docs/references/api/tables_views.rst"; then
    echo "✓ Docs mention not_null - fix applied!"
else
    echo "✗ Docs do not mention not_null - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QueryParams.hs parses IsVal with IsNotNull..."
if grep -q 'IsNotNull' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has IsNotNull parsing - fix applied!"
else
    echo "✗ QueryParams.hs does not have IsNotNull parsing - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Types.hs defines IsNotNull in IsVal..."
if grep -q 'IsNotNull' "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs defines IsNotNull - fix applied!"
else
    echo "✗ Types.hs does not define IsNotNull - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SqlFragment.hs handles IsNotNull..."
if grep -q 'IsNotNull.*NOT NULL' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs handles IsNotNull - fix applied!"
else
    echo "✗ SqlFragment.hs does not handle IsNotNull - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QuerySpec.hs contains test for is.not_null..."
if grep -q 'it "matches not_null using is operator"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs contains is.not_null test - fix applied!"
else
    echo "✗ QuerySpec.hs does not contain is.not_null test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QuerySpec.hs contains test for not.is.not_null..."
if grep -q 'it "not.is.not_null is equivalent to is.null"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs contains not.is.not_null test - fix applied!"
else
    echo "✗ QuerySpec.hs does not contain not.is.not_null test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
