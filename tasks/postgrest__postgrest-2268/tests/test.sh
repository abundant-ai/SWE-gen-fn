#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for XML single-column query support (PR #2268)..."
echo ""
echo "NOTE: This PR allows returning XML from single-column queries"
echo "We verify that the source code has the fix."
echo ""

echo "Checking CHANGELOG.md has the PR entry..."
if [ -f "CHANGELOG.md" ] && grep -q "#2268, Allow returning XML from single-column queries" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2268 entry"
else
    echo "✗ CHANGELOG.md missing PR #2268 entry"
    test_status=1
fi

echo "Checking App.hs passes CTTextXML parameter to createReadStatement..."
if [ -f "src/PostgREST/App.hs" ] && grep -q "iAcceptContentType == CTTextXML" "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes CTTextXML to createReadStatement"
else
    echo "✗ App.hs missing CTTextXML parameter"
    test_status=1
fi

echo "Checking Statements.hs has asXml parameter in createReadStatement signature..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q "createReadStatement :: SQL.Snippet -> SQL.Snippet -> Bool -> Bool -> Bool ->  Bool -> Maybe FieldName -> Bool" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs has asXml parameter in signature"
else
    echo "✗ Statements.hs missing asXml parameter in signature"
    test_status=1
fi

echo "Checking Statements.hs has asXml in function parameters..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q "createReadStatement selectQuery countQuery isSingle countTotal asCsv asXml binaryField" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs has asXml in function parameters"
else
    echo "✗ Statements.hs missing asXml in function parameters"
    test_status=1
fi

echo "Checking Statements.hs uses asXml in bodyF logic..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q "isJust binaryField && asXml = asXmlF" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs uses asXml in bodyF logic"
else
    echo "✗ Statements.hs missing asXml in bodyF logic"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking QuerySpec.hs was copied..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ]; then
    echo "✓ QuerySpec.hs exists (HEAD version)"
else
    echo "✗ QuerySpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking QuerySpec.hs has XML single-column test..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ] && grep -q "can get raw xml output with Accept: text/xml" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has XML single-column test"
else
    echo "✗ QuerySpec.hs missing XML single-column test"
    test_status=1
fi

echo "Checking schema.sql has xmltest table..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q "CREATE TABLE test.xmltest" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has xmltest table"
else
    echo "✗ schema.sql missing xmltest table"
    test_status=1
fi

echo "Checking privileges.sql grants access to xmltest..."
if [ -f "test/spec/fixtures/privileges.sql" ] && grep -q "xmltest" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql grants access to xmltest"
else
    echo "✗ privileges.sql missing xmltest grant"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
