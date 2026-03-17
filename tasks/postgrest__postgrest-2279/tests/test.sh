#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for type casting with underscores and numbers (PR #2279)..."
echo ""
echo "This PR allows casting to types with underscores and numbers (e.g., _int4)"
echo "in the select query parameter by updating the parser to accept these characters."
echo ""

echo "Checking CHANGELOG.md has the fix entry..."
if [ -f "CHANGELOG.md" ] && grep -q '#2278.*Allow casting to types with underscores and numbers' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes fix entry for casting to types with underscores (fix applied)"
else
    echo "✗ CHANGELOG.md does not include fix entry (not fixed)"
    test_status=1
fi

echo "Checking QueryParams.hs parser allows underscores and digits in cast types..."
if [ -f "src/PostgREST/Request/QueryParams.hs" ] && grep -q 'cast.*optionMaybe (string "::" \*> many (letter <|> digit <|> oneOf "_"))' "src/PostgREST/Request/QueryParams.hs"; then
    echo "✓ QueryParams.hs parser allows underscores and digits (fix applied)"
else
    echo "✗ QueryParams.hs parser does not allow underscores and digits (not fixed)"
    test_status=1
fi

echo "Checking QuerySpec.hs has test case for casting with underscores..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ] && grep -q 'can cast types with underscore and numbers' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs includes test case for casting with underscores (fix applied)"
else
    echo "✗ QuerySpec.hs does not include test case (not fixed)"
    test_status=1
fi

echo "Checking schema.sql has oid_test table definition..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q 'CREATE TABLE oid_test' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes oid_test table (fix applied)"
else
    echo "✗ schema.sql does not include oid_test table (not fixed)"
    test_status=1
fi

echo "Checking data.sql has oid_test data..."
if [ -f "test/spec/fixtures/data.sql" ] && grep -q "INSERT INTO oid_test" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql includes oid_test data (fix applied)"
else
    echo "✗ data.sql does not include oid_test data (not fixed)"
    test_status=1
fi

echo "Checking privileges.sql grants access to oid_test..."
if [ -f "test/spec/fixtures/privileges.sql" ] && grep -q "oid_test" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql includes oid_test permissions (fix applied)"
else
    echo "✗ privileges.sql does not include oid_test permissions (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking QuerySpec.hs exists..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ]; then
    echo "✓ QuerySpec.hs exists (HEAD version)"
else
    echo "✗ QuerySpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking test fixtures were copied..."
if [ -f "test/spec/fixtures/data.sql" ]; then
    echo "✓ data.sql exists (HEAD version)"
else
    echo "✗ data.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/spec/fixtures/privileges.sql" ]; then
    echo "✓ privileges.sql exists (HEAD version)"
else
    echo "✗ privileges.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
