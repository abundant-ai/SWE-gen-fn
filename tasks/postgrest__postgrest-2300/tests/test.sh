#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for RPC POST with single unnamed XML parameter (PR #2300)..."
echo ""
echo "NOTE: This PR adds support for posting XML directly to RPC functions"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking CHANGELOG.md mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#2300, RPC POST for function w/single unnamed XML param" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2300"
else
    echo "✗ CHANGELOG.md missing #2300 entry"
    test_status=1
fi

echo "Checking DbStructure.hs includes xml in callable types..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "'xml'::regtype" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs includes xml in callable types"
else
    echo "✗ DbStructure.hs missing xml regtype"
    test_status=1
fi

echo "Checking Error.hs has CTTextXML error message..."
if [ -f "src/PostgREST/Error.hs" ] && grep -q "CTTextXML.*function with a single unnamed xml parameter" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has CTTextXML error message"
else
    echo "✗ Error.hs missing CTTextXML error message"
    test_status=1
fi

echo "Checking ApiRequest.hs handles CTTextXML in RawPay..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q "(CTTextXML, True) -> Right \$ RawPay reqBody" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs handles CTTextXML in RawPay"
else
    echo "✗ ApiRequest.hs missing CTTextXML RawPay handling"
    test_status=1
fi

echo "Checking ApiRequest.hs has xml mapping in findProc..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q '(CTTextXML, "xml")' "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs has xml mapping in findProc"
else
    echo "✗ ApiRequest.hs missing xml mapping"
    test_status=1
fi

echo "Checking ApiRequest.hs includes CTTextXML in content type list..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q "CTOctetStream, CTTextPlain, CTTextXML" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs includes CTTextXML in content type list"
else
    echo "✗ ApiRequest.hs missing CTTextXML in content type list"
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

echo "Checking RpcSpec.hs has unnamed_xml_param test..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ] && grep -q "can insert xml directly" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has unnamed_xml_param test"
else
    echo "✗ RpcSpec.hs missing xml test case"
    test_status=1
fi

echo "Checking schema.sql has unnamed_xml_param function..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q "unnamed_xml_param(pg_catalog.xml)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has unnamed_xml_param function"
else
    echo "✗ schema.sql missing unnamed_xml_param function"
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
