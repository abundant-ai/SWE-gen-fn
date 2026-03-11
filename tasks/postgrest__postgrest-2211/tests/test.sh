#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for limit/offset on UPDATE/DELETE (PR #2211)..."
echo ""
echo "NOTE: This PR reverts automatic PK/ctid usage and requires explicit 'order'"
echo "for UPDATE/DELETE with limit/offset. We verify the source code has the fix."
echo ""

echo "Checking Query/SqlFragment.hs does NOT use ctid fallback..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && ! grep -q 'null rangeId then \["ctid"\]' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ Query/SqlFragment.hs does not have ctid fallback (fix applied)"
else
    echo "✗ Query/SqlFragment.hs still has ctid fallback (not fixed)"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs passes order terms to mutations..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q 'rootOrder' "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs uses rootOrder (fix applied)"
else
    echo "✗ DbRequestBuilder.hs does not use rootOrder (not fixed)"
    test_status=1
fi

echo "Checking ApiRequest.hs requires order for DELETE/UPDATE with limit..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q 'LimitNoOrderError' "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs requires explicit order (fix applied)"
else
    echo "✗ ApiRequest.hs does not require order (not fixed)"
    test_status=1
fi

echo "Checking App.hs uses failChangesOffLimits..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'failChangesOffLimits' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses failChangesOffLimits (fix applied)"
else
    echo "✗ App.hs does not use failChangesOffLimits (not fixed)"
    test_status=1
fi

echo "Checking Error.hs defines OffLimitsChangesError..."
if [ -f "src/PostgREST/Error.hs" ] && grep -q 'OffLimitsChangesError' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines OffLimitsChangesError (fix applied)"
else
    echo "✗ Error.hs does not define OffLimitsChangesError (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking DeleteSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/DeleteSpec.hs" ]; then
    echo "✓ DeleteSpec.hs exists (HEAD version)"
else
    echo "✗ DeleteSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking DeleteSpec.hs has tests WITH explicit order..."
if [ -f "test/spec/Feature/Query/DeleteSpec.hs" ] && grep -q 'limited_delete_items?order=id&limit=1' "test/spec/Feature/Query/DeleteSpec.hs"; then
    echo "✓ DeleteSpec.hs contains tests with explicit order (HEAD version)"
else
    echo "✗ DeleteSpec.hs does not contain expected tests - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking UpdateSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/UpdateSpec.hs" ]; then
    echo "✓ UpdateSpec.hs exists (HEAD version)"
else
    echo "✗ UpdateSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking UpdateSpec.hs has tests WITH explicit order..."
if [ -f "test/spec/Feature/Query/UpdateSpec.hs" ] && grep -q 'limited_update_items?order=id&limit=' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs contains tests with explicit order (HEAD version)"
else
    echo "✗ UpdateSpec.hs does not contain expected tests - HEAD file not properly copied!"
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
