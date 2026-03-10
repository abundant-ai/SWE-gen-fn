#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PgSafeUpdateSpec.hs" "test/spec/Feature/Query/PgSafeUpdateSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpsertSpec.hs" "test/spec/Feature/Query/UpsertSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for reverting Range header changes..."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2705 entries (bug.patch removes them)
echo "Checking CHANGELOG.md has PR #2705 entries..."
if grep -q "#2705, Fix bug when using the \`Range\` header on \`PATCH/DELETE\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2705 bug fix entry"
else
    echo "✗ CHANGELOG.md missing PR #2705 entry - fix not applied"
    test_status=1
fi

if grep -q "#2705, The \`Range\` header is now only considered on \`GET\` requests" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2705 Range behavior change"
else
    echo "✗ CHANGELOG.md missing PR #2705 Range change entry - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should have conditional Range handling (bug.patch removes it)
echo "Checking src/PostgREST/ApiRequest.hs Range header handling..."
if grep -q 'headerRange = if method == "GET" then rangeRequested hdrs else allRange' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs has conditional Range handling (ignores for non-GET)"
else
    echo "✗ src/PostgREST/ApiRequest.hs doesn't have correct Range handling - fix not applied"
    test_status=1
fi

# Check error name is PutLimitNotAllowedError in HEAD (bug.patch changes it to PutRangeNotAllowedError)
echo "Checking src/PostgREST/ApiRequest.hs error reference..."
if grep -q "PutLimitNotAllowedError" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs references PutLimitNotAllowedError"
else
    echo "✗ src/PostgREST/ApiRequest.hs doesn't reference PutLimitNotAllowedError - fix not applied"
    test_status=1
fi

# Check Types has PutLimitNotAllowedError in HEAD
echo "Checking src/PostgREST/ApiRequest/Types.hs error type..."
if grep -q "PutLimitNotAllowedError" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs has PutLimitNotAllowedError"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs doesn't have PutLimitNotAllowedError - fix not applied"
    test_status=1
fi

# Check Error.hs has shorter error message (not mentioning Range header) in HEAD
echo "Checking src/PostgREST/Error.hs error message..."
if grep -q '"limit/offset querystring parameters are not allowed for PUT"' "src/PostgREST/Error.hs" && \
   ! grep -q "Range header and limit/offset" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has correct error message"
else
    echo "✗ src/PostgREST/Error.hs error message incorrect - fix not applied"
    test_status=1
fi

# Check DeleteSpec.hs - HEAD should have "ignores the Range header" tests (bug.patch removes them)
echo "Checking test/spec/Feature/Query/DeleteSpec.hs..."
if grep -q "ignores the Range header" "test/spec/Feature/Query/DeleteSpec.hs"; then
    echo "✓ test/spec/Feature/Query/DeleteSpec.hs has 'ignores Range header' tests"
else
    echo "✗ test/spec/Feature/Query/DeleteSpec.hs missing 'ignores Range header' tests - fix not applied"
    test_status=1
fi

# Check UpdateSpec.hs - HEAD should have "ignores the Range header" tests (bug.patch removes them)
echo "Checking test/spec/Feature/Query/UpdateSpec.hs..."
if grep -q "ignores the Range header" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpdateSpec.hs has 'ignores Range header' tests"
else
    echo "✗ test/spec/Feature/Query/UpdateSpec.hs missing 'ignores Range header' tests - fix not applied"
    test_status=1
fi

# Check UpsertSpec.hs - HEAD should NOT have "fails if Range is specified" test (bug.patch adds it)
echo "Checking test/spec/Feature/Query/UpsertSpec.hs..."
if ! grep -q "fails if Range is specified" "test/spec/Feature/Query/UpsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpsertSpec.hs does not have 'fails if Range is specified' test"
else
    echo "✗ test/spec/Feature/Query/UpsertSpec.hs has unexpected Range test - fix not applied"
    test_status=1
fi

# Check UpsertSpec.hs - HEAD should have "ignores the Range header" test (bug.patch removes it)
echo "Checking test/spec/Feature/Query/UpsertSpec.hs for ignores test..."
if grep -q "ignores the Range header" "test/spec/Feature/Query/UpsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpsertSpec.hs has 'ignores Range header' test"
else
    echo "✗ test/spec/Feature/Query/UpsertSpec.hs missing 'ignores Range header' test - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should have "ignores Range header when method is different than GET" context (bug.patch removes it)
echo "Checking test/spec/Feature/Query/RpcSpec.hs..."
if grep -q "ignores Range header when method is different than GET" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs has 'ignores Range header' tests"
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs missing 'ignores Range header' tests - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should have headers parameter in requestMutation (bug.patch removes it)
echo "Checking test/spec/SpecHelper.hs requestMutation signature..."
if grep -q "requestMutation :: Method -> ByteString -> \[Header\] -> BL.ByteString -> WaiExpectation ()" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs has correct requestMutation signature (with headers)"
else
    echo "✗ test/spec/SpecHelper.hs doesn't have correct requestMutation signature - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
