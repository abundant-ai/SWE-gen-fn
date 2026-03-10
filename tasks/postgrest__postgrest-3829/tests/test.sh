#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the fix for insert with missing=default..."
if grep -q "#3706, Fix insert with \`missing=default\` uses default value of domain instead of column" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs uses column default before domain default..."
if grep -q "WHEN (t.typbasetype != 0) AND (ad.adbin IS NULL) THEN pg_get_expr(t.typdefaultbin, 0)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses correct default precedence - fix applied!"
else
    echo "✗ SchemaCache.hs does not use correct default precedence - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that InsertSpec.hs contains the test for column default before domain default..."
if grep -q 'it "inserts a COLUMN default before a DOMAIN default with missing=default"' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs contains the test case - fix applied!"
else
    echo "✗ InsertSpec.hs does not contain the test case - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that schema.sql contains evil_friends_with_column_default table..."
if grep -q "create table evil_friends_with_column_default" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql contains evil_friends_with_column_default table - fix applied!"
else
    echo "✗ schema.sql does not contain evil_friends_with_column_default table - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
