#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for XML support in RPCs (PR #2202)..."
echo ""
echo "This PR adds support for returning XML from RPC endpoints."
echo ""

echo "Checking ContentType.hs defines CTTextXML..."
if [ -f "src/PostgREST/ContentType.hs" ] && grep -q '| CTTextXML' "src/PostgREST/ContentType.hs"; then
    echo "✓ ContentType.hs defines CTTextXML (fix applied)"
else
    echo "✗ ContentType.hs does not define CTTextXML (not fixed)"
    test_status=1
fi

echo "Checking ContentType.hs toMime function handles CTTextXML..."
if [ -f "src/PostgREST/ContentType.hs" ] && grep -q 'toMime CTTextXML' "src/PostgREST/ContentType.hs"; then
    echo "✓ ContentType.hs toMime handles CTTextXML (fix applied)"
else
    echo "✗ ContentType.hs toMime does not handle CTTextXML (not fixed)"
    test_status=1
fi

echo "Checking ContentType.hs decodeContentType handles text/xml..."
if [ -f "src/PostgREST/ContentType.hs" ] && grep -q '"text/xml".*CTTextXML' "src/PostgREST/ContentType.hs"; then
    echo "✓ ContentType.hs decodeContentType handles text/xml (fix applied)"
else
    echo "✗ ContentType.hs decodeContentType does not handle text/xml (not fixed)"
    test_status=1
fi

echo "Checking SqlFragment.hs exports asXmlF..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q 'asXmlF' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports/defines asXmlF (fix applied)"
else
    echo "✗ SqlFragment.hs does not export/define asXmlF (not fixed)"
    test_status=1
fi

echo "Checking SqlFragment.hs asXmlF uses xmlagg..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q 'xmlagg' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs asXmlF uses xmlagg (fix applied)"
else
    echo "✗ SqlFragment.hs asXmlF does not use xmlagg (not fixed)"
    test_status=1
fi

echo "Checking Statements.hs callProcStatement has asXml parameter..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q 'Bool -> Bool -> Bool -> Bool -> Maybe FieldName' "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs callProcStatement signature includes asXml (fix applied)"
else
    echo "✗ Statements.hs callProcStatement signature missing asXml (not fixed)"
    test_status=1
fi

echo "Checking Statements.hs uses asXmlF when asXml is true..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q 'asXmlF' "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs uses asXmlF (fix applied)"
else
    echo "✗ Statements.hs does not use asXmlF (not fixed)"
    test_status=1
fi

echo "Checking App.hs passes CTTextXML to callProcStatement..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'iAcceptContentType == CTTextXML' "src/PostgREST/App.hs"; then
    echo "✓ App.hs checks for CTTextXML (fix applied)"
else
    echo "✗ App.hs does not check for CTTextXML (not fixed)"
    test_status=1
fi

echo "Checking App.hs rawContentTypes includes CTTextXML..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'CTTextXML' "src/PostgREST/App.hs" && grep -q 'rawContentTypes' "src/PostgREST/App.hs"; then
    echo "✓ App.hs rawContentTypes includes CTTextXML (fix applied)"
else
    echo "✗ App.hs rawContentTypes does not include CTTextXML (not fixed)"
    test_status=1
fi

echo "Checking ApiRequest.hs rawContentTypes includes CTTextXML..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q 'CTTextXML' "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs rawContentTypes includes CTTextXML (fix applied)"
else
    echo "✗ ApiRequest.hs rawContentTypes does not include CTTextXML (not fixed)"
    test_status=1
fi

echo "Checking Error.hs handles xmlagg error with 406 status..."
if [ -f "src/PostgREST/Error.hs" ] && grep -q 'xmlagg' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs handles xmlagg error (fix applied)"
else
    echo "✗ Error.hs does not handle xmlagg error (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking RpcSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ]; then
    echo "✓ RpcSpec.hs exists (HEAD version)"
else
    echo "✗ RpcSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking RpcSpec.hs has XML tests..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ] && grep -q 'text/xml' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs contains text/xml tests (HEAD version)"
else
    echo "✗ RpcSpec.hs does not contain text/xml tests - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking RpcSpec.hs has return_scalar_xml test..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ] && grep -q 'return_scalar_xml' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs contains return_scalar_xml test (HEAD version)"
else
    echo "✗ RpcSpec.hs does not contain return_scalar_xml test - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking schema.sql was copied..."
if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking schema.sql has XML functions..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q 'return_scalar_xml' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql contains XML functions (HEAD version)"
else
    echo "✗ schema.sql does not contain XML functions - HEAD file not properly copied!"
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
