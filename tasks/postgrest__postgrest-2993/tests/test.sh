#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

# Check that ApiRequest/Types.hs HAS the error constructors (this is the fix!)
echo "Checking ApiRequest/Types.hs for error constructors..."
if grep -q 'GucHeadersError' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -q 'GucStatusError' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -q 'OffLimitsChangesError' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -q 'PutMatchingPkError' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -q 'SingularityError' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -q 'PGRSTParseError' "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs has error constructors"
else
    echo "✗ ApiRequest/Types.hs missing error constructors - fix not applied"
    test_status=1
fi

# Check that Error.hs does NOT have these error constructors in the Error data type
echo "Checking Error.hs for error constructor removal from Error type..."
if ! grep -A 10 'data Error' "src/PostgREST/Error.hs" | grep -q 'GucHeadersError\|GucStatusError\|OffLimitsChangesError\|PutMatchingPkError\|SingularityError\|JSONParseError'; then
    echo "✓ Error.hs removed error constructors from Error type"
else
    echo "✗ Error.hs still has error constructors in Error type - fix not applied"
    test_status=1
fi

# Check that singularityError helper function does NOT exist (it's only needed when SingularityError is in Error type)
echo "Checking Error.hs for singularityError helper function removal..."
if ! grep -q 'singularityError ::' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs removed singularityError helper function"
else
    echo "✗ Error.hs still has singularityError helper function - fix not applied"
    test_status=1
fi

# Check that Query.hs uses ApiRequestTypes.SingularityError instead of Error
echo "Checking Query.hs for ApiRequestTypes.SingularityError usage..."
if grep -q 'ApiRequestTypes.SingularityError' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs uses ApiRequestTypes.SingularityError"
else
    echo "✗ Query.hs not using ApiRequestTypes.SingularityError - fix not applied"
    test_status=1
fi

# Check that Query.hs uses ApiRequestTypes.PutMatchingPkError
echo "Checking Query.hs for ApiRequestTypes.PutMatchingPkError usage..."
if grep -q 'ApiRequestTypes.PutMatchingPkError' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs uses ApiRequestTypes.PutMatchingPkError"
else
    echo "✗ Query.hs not using ApiRequestTypes.PutMatchingPkError - fix not applied"
    test_status=1
fi

# Check that Query.hs uses ApiRequestTypes.OffLimitsChangesError
echo "Checking Query.hs for ApiRequestTypes.OffLimitsChangesError usage..."
if grep -q 'ApiRequestTypes.OffLimitsChangesError' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs uses ApiRequestTypes.OffLimitsChangesError"
else
    echo "✗ Query.hs not using ApiRequestTypes.OffLimitsChangesError - fix not applied"
    test_status=1
fi

# Check that Response.hs uses ApiRequestTypes.GucHeadersError
echo "Checking Response.hs for ApiRequestTypes.GucHeadersError usage..."
if grep -q 'ApiRequestTypes.GucHeadersError' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses ApiRequestTypes.GucHeadersError"
else
    echo "✗ Response.hs not using ApiRequestTypes.GucHeadersError - fix not applied"
    test_status=1
fi

# Check that Response.hs uses ApiRequestTypes.GucStatusError
echo "Checking Response.hs for ApiRequestTypes.GucStatusError usage..."
if grep -q 'ApiRequestTypes.GucStatusError' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses ApiRequestTypes.GucStatusError"
else
    echo "✗ Response.hs not using ApiRequestTypes.GucStatusError - fix not applied"
    test_status=1
fi

# Check that Error.hs uses PGRSTParseError (not JSONParseError)
echo "Checking Error.hs for PGRSTParseError usage..."
if grep -q 'PGRSTParseError' "src/PostgREST/Error.hs" && \
   ! grep -A 10 'data Error' "src/PostgREST/Error.hs" | grep -q 'JSONParseError'; then
    echo "✓ Error.hs uses PGRSTParseError correctly"
else
    echo "✗ Error.hs not using PGRSTParseError correctly - fix not applied"
    test_status=1
fi

# Check that RpcSpec test has "error" in descriptions (not JSONParseError)
echo "Checking RpcSpec.hs for correct test descriptions..."
if grep -q 'returns error for invalid JSON in RAISE Message field' "test/spec/Feature/Query/RpcSpec.hs" && \
   grep -q 'returns error for invalid JSON in RAISE Details field' "test/spec/Feature/Query/RpcSpec.hs" && \
   grep -q 'returns error for missing Details field in RAISE' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has correct test descriptions"
else
    echo "✗ RpcSpec.hs test descriptions not correct - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
