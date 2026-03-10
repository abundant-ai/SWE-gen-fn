#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying OpenAPI content negotiation fix..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

# Check that PathInfo is exported from ApiRequest module
echo "Checking ApiRequest.hs exports PathInfo..."
if grep -q 'PathInfo(..)' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs exports PathInfo"
else
    echo "✗ ApiRequest.hs missing PathInfo export - fix not applied"
    test_status=1
fi

# Check that iPathInfo field is added back to ApiRequest
echo "Checking ApiRequest has iPathInfo field..."
if grep -q 'iPathInfo.*::.*PathInfo' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest has iPathInfo field"
else
    echo "✗ ApiRequest missing iPathInfo field - fix not applied"
    test_status=1
fi

# Check that iAcceptMediaType is [MediaType] not MediaType
echo "Checking iAcceptMediaType is a list..."
if grep -q 'iAcceptMediaType.*::.*\[MediaType\]' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ iAcceptMediaType is [MediaType]"
else
    echo "✗ iAcceptMediaType not a list - fix not applied"
    test_status=1
fi

# Check that negotiateContent is NOT in ApiRequest.hs (should be moved to Plan.hs)
echo "Checking negotiateContent removed from ApiRequest.hs..."
if ! grep -q '^negotiateContent ::' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ negotiateContent removed from ApiRequest.hs"
else
    echo "✗ negotiateContent still in ApiRequest.hs - fix not applied"
    test_status=1
fi

# Check that getMediaTypes is NOT in ApiRequest.hs
echo "Checking getMediaTypes removed from ApiRequest.hs..."
if ! grep -q '^getMediaTypes ::' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ getMediaTypes removed from ApiRequest.hs"
else
    echo "✗ getMediaTypes still in ApiRequest.hs - fix not applied"
    test_status=1
fi

# Check that producedMediaTypes is NOT in ApiRequest.hs (should be moved to Plan.hs)
echo "Checking producedMediaTypes removed from ApiRequest.hs..."
if ! grep -q '^producedMediaTypes ::' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ producedMediaTypes removed from ApiRequest.hs"
else
    echo "✗ producedMediaTypes still in ApiRequest.hs - fix not applied"
    test_status=1
fi

# Check that contentMediaType is defined locally in userApiRequest
echo "Checking contentMediaType defined locally in userApiRequest..."
if grep -q 'contentMediaType = maybe MTApplicationJSON MediaType.decodeMediaType' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ contentMediaType defined locally"
else
    echo "✗ contentMediaType not defined locally - fix not applied"
    test_status=1
fi

# Check that Plan.hs has wrMedia field in WrappedReadPlan
echo "Checking WrappedReadPlan has wrMedia field..."
if grep -q 'wrMedia.*::.*MediaType' "src/PostgREST/Plan.hs"; then
    echo "✓ WrappedReadPlan has wrMedia field"
else
    echo "✗ WrappedReadPlan missing wrMedia field - fix not applied"
    test_status=1
fi

# Check that Plan.hs has mrMedia field in MutateReadPlan
echo "Checking MutateReadPlan has mrMedia field..."
if grep -q 'mrMedia.*::.*MediaType' "src/PostgREST/Plan.hs"; then
    echo "✓ MutateReadPlan has mrMedia field"
else
    echo "✗ MutateReadPlan missing mrMedia field - fix not applied"
    test_status=1
fi

# Check that Plan.hs has crMedia field in CallReadPlan
echo "Checking CallReadPlan has crMedia field..."
if grep -q 'crMedia.*::.*MediaType' "src/PostgREST/Plan.hs"; then
    echo "✓ CallReadPlan has crMedia field"
else
    echo "✗ CallReadPlan missing crMedia field - fix not applied"
    test_status=1
fi

# Check that InspectPlan is defined in Plan.hs
echo "Checking InspectPlan is defined..."
if grep -q 'data InspectPlan' "src/PostgREST/Plan.hs"; then
    echo "✓ InspectPlan is defined"
else
    echo "✗ InspectPlan not defined - fix not applied"
    test_status=1
fi

# Check that inspectPlan function exists in Plan.hs
echo "Checking inspectPlan function exists..."
if grep -q 'inspectPlan :: AppConfig -> ApiRequest -> Either Error InspectPlan' "src/PostgREST/Plan.hs"; then
    echo "✓ inspectPlan function exists"
else
    echo "✗ inspectPlan function missing - fix not applied"
    test_status=1
fi

# Check that negotiateContent is NOW in Plan.hs
echo "Checking negotiateContent moved to Plan.hs..."
if grep -q '^negotiateContent :: AppConfig -> Action -> PathInfo -> \[MediaType\] -> Either ApiRequestError MediaType' "src/PostgREST/Plan.hs"; then
    echo "✓ negotiateContent in Plan.hs"
else
    echo "✗ negotiateContent not in Plan.hs - fix not applied"
    test_status=1
fi

# Check that producedMediaTypes is NOW in Plan.hs
echo "Checking producedMediaTypes moved to Plan.hs..."
if grep -q '^producedMediaTypes :: AppConfig -> Action -> PathInfo -> \[MediaType\]' "src/PostgREST/Plan.hs"; then
    echo "✓ producedMediaTypes in Plan.hs"
else
    echo "✗ producedMediaTypes not in Plan.hs - fix not applied"
    test_status=1
fi

# Check that inspectPlanTxMode is removed from Plan.hs
echo "Checking inspectPlanTxMode removed from Plan.hs..."
if ! grep -q '^inspectPlanTxMode ::' "src/PostgREST/Plan.hs"; then
    echo "✓ inspectPlanTxMode removed"
else
    echo "✗ inspectPlanTxMode still exists - fix not applied"
    test_status=1
fi

# Check that App.hs uses wrPlan in readResponse call
echo "Checking App.hs passes wrPlan to readResponse..."
if grep -q 'Response.readResponse wrPlan headersOnly' "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes wrPlan to readResponse"
else
    echo "✗ App.hs not passing wrPlan to readResponse - fix not applied"
    test_status=1
fi

# Check that App.hs uses mrPlan in updateResponse call
echo "Checking App.hs passes mrPlan to updateResponse..."
if grep -q 'Response.updateResponse mrPlan apiReq' "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes mrPlan to updateResponse"
else
    echo "✗ App.hs not passing mrPlan to updateResponse - fix not applied"
    test_status=1
fi

# Check that App.hs uses iPlan for inspectPlan
echo "Checking App.hs calls inspectPlan..."
if grep -q 'iPlan <- liftEither \$ Plan.inspectPlan conf apiReq' "src/PostgREST/App.hs"; then
    echo "✓ App.hs calls inspectPlan"
else
    echo "✗ App.hs not calling inspectPlan - fix not applied"
    test_status=1
fi

# Check that Response.hs readResponse signature includes WrappedReadPlan
echo "Checking Response.hs readResponse signature..."
if grep -q 'readResponse :: WrappedReadPlan -> Bool -> QualifiedIdentifier -> ApiRequest -> ResultSet -> Wai.Response' "src/PostgREST/Response.hs"; then
    echo "✓ readResponse signature updated"
else
    echo "✗ readResponse signature not updated - fix not applied"
    test_status=1
fi

# Check that Response.hs uses wrMedia from plan
echo "Checking Response.hs extracts wrMedia from WrappedReadPlan..."
if grep -q 'readResponse WrappedReadPlan{wrMedia}' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs extracts wrMedia"
else
    echo "✗ Response.hs not extracting wrMedia - fix not applied"
    test_status=1
fi

# Check that Response.hs contentTypeHeaders uses MediaType parameter
echo "Checking Response.hs contentTypeHeaders signature..."
if grep -q 'contentTypeHeaders :: MediaType -> ApiRequest -> \[HTTP.Header\]' "src/PostgREST/Response.hs"; then
    echo "✓ contentTypeHeaders signature updated"
else
    echo "✗ contentTypeHeaders signature not updated - fix not applied"
    test_status=1
fi

# Check that Query.hs readQuery uses wrMedia
echo "Checking Query.hs readQuery uses wrMedia..."
if grep -q 'readQuery WrappedReadPlan{wrReadPlan, wrMedia, wrResAgg}' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs readQuery uses wrMedia"
else
    echo "✗ Query.hs readQuery not using wrMedia - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
