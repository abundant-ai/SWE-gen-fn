#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AndOrParamsSpec.hs" "test/spec/Feature/Query/AndOrParamsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the to_tsvector fix..."
if grep -q "Apply \`to_tsvector()\` explicitly to the full-text search filtered column" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions to_tsvector fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention automatic tsvector conversion..."
if grep -q "Automatic \`\`tsvector\`\` conversion" "docs/references/api/tables_views.rst"; then
    echo "✓ Documentation mentions automatic tsvector conversion - fix applied!"
else
    echo "✗ Documentation does not mention automatic tsvector conversion - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CoercibleField includes cfToTsVector field..."
if grep -q "cfToTsVector :: Maybe ToTsVector" "src/PostgREST/Plan/Types.hs"; then
    echo "✓ CoercibleField includes cfToTsVector field - fix applied!"
else
    echo "✗ CoercibleField missing cfToTsVector field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that pgFmtField uses cfToTsVector..."
if grep -q "pgFmtField table cf = case cfToTsVector cf of" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ pgFmtField uses cfToTsVector - fix applied!"
else
    echo "✗ pgFmtField does not use cfToTsVector - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that to_tsvector function call is generated..."
if grep -q 'Just (ToTsVector lang) -> "to_tsvector("' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ to_tsvector function call is generated - fix applied!"
else
    echo "✗ to_tsvector function call not generated - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that tsvector types are handled specially..."
if grep -q 'cfIRType="tsvector"} -> cf{cfJsonPath=jp, cfToJson=True, cfToTsVector=Nothing}' "src/PostgREST/Plan.hs"; then
    echo "✓ tsvector types handled specially - fix applied!"
else
    echo "✗ tsvector types not handled specially - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Language type is exported from ApiRequest.Types..."
if head -20 "src/PostgREST/ApiRequest/Types.hs" | grep -q "Language"; then
    echo "✓ Language type is exported - fix applied!"
else
    echo "✗ Language type not exported - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
