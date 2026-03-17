#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/JsonOperatorSpec.hs" "test/spec/Feature/Query/JsonOperatorSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for accessing JSON array fields with -> and ->> in ?select= and ?order= (PR #2145)..."
echo ""
echo "This PR fixes issues with JSON operator path parsing and SQL generation for array indexing."
echo ""

echo "Checking CHANGELOG.md has the fix entry..."
if [ -f "CHANGELOG.md" ] && grep -q '#2145.*Fix accessing json array fields with -> and ->> in ?select= and ?order=' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes fix entry for #2145 (fix applied)"
else
    echo "✗ CHANGELOG.md does not include fix entry for #2145 (not fixed)"
    test_status=1
fi

echo "Checking CHANGELOG.md has feature entries for #1543 and #2075..."
if [ -f "CHANGELOG.md" ] && grep -q '#1543.*Allow access to fields of composite types' "CHANGELOG.md" && grep -q '#2075.*Allow access to array items' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes feature entries for #1543 and #2075 (fix applied)"
else
    echo "✗ CHANGELOG.md does not include feature entries for #1543 and #2075 (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/Query/SqlFragment.hs has to_jsonb wrapping..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q 'pgFmtField table (c, \[\]) = SQL.sql (pgFmtColumn table c)' "src/PostgREST/Query/SqlFragment.hs" && grep -q 'pgFmtField table (c, jp) = SQL.sql ("to_jsonb(" <> pgFmtColumn table c <> ")") <> pgFmtJsonPath jp' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs uses to_jsonb wrapping for JSON paths (fix applied)"
else
    echo "✗ SqlFragment.hs does not use to_jsonb wrapping (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/Request/QueryParams.hs has enhanced pJsonPath parser..."
if [ -f "src/PostgREST/Request/QueryParams.hs" ] && grep -q 'try (void $ lookAhead (string "\."))'  "src/PostgREST/Request/QueryParams.hs" && grep -q 'try (void $ lookAhead (string ","))' "src/PostgREST/Request/QueryParams.hs"; then
    echo "✓ QueryParams.hs includes lookAhead for '.' and ',' (fix applied)"
else
    echo "✗ QueryParams.hs does not include lookAhead for '.' and ',' (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking JsonOperatorSpec.hs exists..."
if [ -f "test/spec/Feature/Query/JsonOperatorSpec.hs" ]; then
    echo "✓ JsonOperatorSpec.hs exists (HEAD version)"
else
    echo "✗ JsonOperatorSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking data.sql exists..."
if [ -f "test/spec/fixtures/data.sql" ]; then
    echo "✓ data.sql exists (HEAD version)"
else
    echo "✗ data.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking privileges.sql exists..."
if [ -f "test/spec/fixtures/privileges.sql" ]; then
    echo "✓ privileges.sql exists (HEAD version)"
else
    echo "✗ privileges.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking schema.sql exists..."
if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
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
