#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AsymmetricJwtSpec.hs" "test/spec/Feature/Auth/AsymmetricJwtSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AudienceJwtSecretSpec.hs" "test/spec/Feature/Auth/AudienceJwtSecretSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AuthSpec.hs" "test/spec/Feature/Auth/AuthSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/BinaryJwtSecretSpec.hs" "test/spec/Feature/Auth/BinaryJwtSecretSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/NoAnonSpec.hs" "test/spec/Feature/Auth/NoAnonSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/NoJwtSpec.hs" "test/spec/Feature/Auth/NoJwtSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/IgnorePrivOpenApiSpec.hs" "test/spec/Feature/OpenApi/IgnorePrivOpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/ProxySpec.hs" "test/spec/Feature/OpenApi/ProxySpec.hs"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AndOrParamsSpec.hs" "test/spec/Feature/Query/AndOrParamsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedInnerJoinSpec.hs" "test/spec/Feature/Query/EmbedInnerJoinSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/HtmlRawOutputSpec.hs" "test/spec/Feature/Query/HtmlRawOutputSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/JsonOperatorSpec.hs" "test/spec/Feature/Query/JsonOperatorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs"

test_status=0

echo "Verifying fix for HTTP 405 Method Not Allowed for unsupported verbs (PR #2139)..."
echo ""
echo "This PR fixes PostgREST to return 405 Method Not Allowed instead of 404 Not Found"
echo "for unsupported HTTP verbs like CONNECT, TRACE, or unknown methods."
echo ""

echo "Checking App.hs has ActionUnknown handler that throws UnsupportedVerb..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'ActionUnknown' "src/PostgREST/App.hs" && grep -q 'Error.UnsupportedVerb' "src/PostgREST/App.hs"; then
    echo "✓ App.hs includes ActionUnknown handler (fix applied)"
else
    echo "✗ App.hs does not include ActionUnknown handler (not fixed)"
    test_status=1
fi

echo "Checking Error.hs has UnsupportedVerb in Error data type..."
if [ -f "src/PostgREST/Error.hs" ]; then
    # The fix adds UnsupportedVerb Text to the Error data type
    if grep -A30 'data Error' "src/PostgREST/Error.hs" | grep -q 'UnsupportedVerb Text'; then
        echo "✓ Error.hs includes UnsupportedVerb in Error type (fix applied)"
    else
        echo "✗ Error.hs does not include UnsupportedVerb in Error type (not fixed)"
        test_status=1
    fi
else
    echo "✗ Error.hs not found"
    test_status=1
fi

echo "Checking Error.hs has UnsupportedVerb with status 405 in Error instance..."
if [ -f "src/PostgREST/Error.hs" ]; then
    # Look for status function in Error instance (not ApiRequestError)
    if grep -A50 'instance PgrstError Error where' "src/PostgREST/Error.hs" | grep -q 'status UnsupportedVerb.*HTTP.status405'; then
        echo "✓ Error.hs includes UnsupportedVerb status 405 in Error instance (fix applied)"
    else
        echo "✗ Error.hs does not include UnsupportedVerb status in Error instance (not fixed)"
        test_status=1
    fi
fi

echo "Checking Error.hs has UnsupportedVerb JSON error message..."
if [ -f "src/PostgREST/Error.hs" ]; then
    # Check for the JSON message in Error instance (not ApiRequestError)
    if grep -A100 'instance JSON.ToJSON Error where' "src/PostgREST/Error.hs" | grep -q 'toJSON (UnsupportedVerb'; then
        echo "✓ Error.hs includes UnsupportedVerb JSON message (fix applied)"
    else
        echo "✗ Error.hs does not include UnsupportedVerb JSON message (not fixed)"
        test_status=1
    fi
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

for test_file in \
    "test/spec/Feature/Auth/AsymmetricJwtSpec.hs" \
    "test/spec/Feature/Auth/AudienceJwtSecretSpec.hs" \
    "test/spec/Feature/Auth/AuthSpec.hs" \
    "test/spec/Feature/Auth/BinaryJwtSecretSpec.hs" \
    "test/spec/Feature/Auth/NoAnonSpec.hs" \
    "test/spec/Feature/Auth/NoJwtSpec.hs" \
    "test/spec/Feature/OpenApi/DisabledOpenApiSpec.hs" \
    "test/spec/Feature/OpenApi/IgnorePrivOpenApiSpec.hs" \
    "test/spec/Feature/OpenApi/OpenApiSpec.hs" \
    "test/spec/Feature/OpenApi/ProxySpec.hs" \
    "test/spec/Feature/OpenApi/RootSpec.hs" \
    "test/spec/Feature/Query/AndOrParamsSpec.hs" \
    "test/spec/Feature/Query/DeleteSpec.hs" \
    "test/spec/Feature/Query/EmbedDisambiguationSpec.hs" \
    "test/spec/Feature/Query/EmbedInnerJoinSpec.hs" \
    "test/spec/Feature/Query/ErrorSpec.hs" \
    "test/spec/Feature/Query/HtmlRawOutputSpec.hs" \
    "test/spec/Feature/Query/InsertSpec.hs" \
    "test/spec/Feature/Query/JsonOperatorSpec.hs" \
    "test/spec/Feature/Query/MultipleSchemaSpec.hs" \
    "test/spec/Feature/Query/QueryLimitedSpec.hs"; do
    if [ -f "$test_file" ]; then
        echo "✓ $test_file exists (HEAD version)"
    else
        echo "✗ $test_file not found - HEAD file not copied!"
        test_status=1
    fi
done

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
