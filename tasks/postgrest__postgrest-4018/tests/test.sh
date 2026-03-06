#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AuthSpec.hs" "test/spec/Feature/Auth/AuthSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/IgnorePrivOpenApiSpec.hs" "test/spec/Feature/OpenApi/IgnorePrivOpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/OptionsSpec.hs" "test/spec/Feature/OptionsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/RollbackSpec.hs" "test/spec/Feature/RollbackSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/RpcPreRequestGucsSpec.hs" "test/spec/Feature/RpcPreRequestGucsSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4018 which adds Content-Length response header
# HEAD state (2ad660d) = fix applied, has Content-Length header support
# BASE state (with bug.patch) = no Content-Length header

test_status=0

echo "Verifying source code matches HEAD state (Content-Length header added)..."
echo ""

echo "Checking that CHANGELOG.md has Content-Length header entry..."
if grep -q "#4016, Add \`Content-Length\` response header" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has Content-Length header entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have Content-Length header entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that observability.rst mentions response body size in logs..."
if grep -q "the HTTP response status and the response body size in bytes if available" "docs/references/observability.rst"; then
    echo "✓ observability.rst mentions response body size - fix applied!"
else
    echo "✗ observability.rst does not mention response body size - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that observability.rst has Content-Length header section..."
if grep -q "_content-length_header:" "docs/references/observability.rst"; then
    echo "✓ observability.rst has Content-Length header section - fix applied!"
else
    echo "✗ observability.rst does not have Content-Length header section - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs imports Data.ByteString.Lazy..."
if grep -q "import qualified Data.ByteString.Lazy" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs imports Data.ByteString.Lazy - fix applied!"
else
    echo "✗ Error.hs does not import Data.ByteString.Lazy - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs has cLHeader function for Content-Length..."
if grep -q 'cLHeader body = (,) "Content-Length" (show \$ LBS.length body)' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has cLHeader function - fix applied!"
else
    echo "✗ Error.hs does not have cLHeader function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses Content-Length header in errorResponseFor..."
if grep -q "cLHeader (errorPayload err)" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses Content-Length in errorResponseFor - fix applied!"
else
    echo "✗ Error.hs does not use Content-Length in errorResponseFor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs imports Data.ByteString.Lazy..."
if grep -q "import qualified Data.ByteString.Lazy" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs imports Data.ByteString.Lazy - fix applied!"
else
    echo "✗ Response.hs does not import Data.ByteString.Lazy - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs has contentLengthHeader functions..."
if grep -q "contentLengthHeader ::" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has contentLengthHeader function - fix applied!"
else
    echo "✗ Response.hs does not have contentLengthHeader function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs has contentLengthHeaderStrict function..."
if grep -q "contentLengthHeaderStrict ::" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has contentLengthHeaderStrict function - fix applied!"
else
    echo "✗ Response.hs does not have contentLengthHeaderStrict function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs uses contentLengthHeaderStrict in responses..."
if grep -q "contentLengthHeaderStrict" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses contentLengthHeaderStrict - fix applied!"
else
    echo "✗ Response.hs does not use contentLengthHeaderStrict - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
