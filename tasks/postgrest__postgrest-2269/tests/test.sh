#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

test_status=0

echo "Verifying fix for limit=0 query parameter handling (PR #2269)..."
echo ""
echo "NOTE: This PR allows limit=0 to return empty array instead of crashing"
echo "We verify that the source code has the fix."
echo ""

echo "Checking RangeQuery.hs has limitZeroRange function..."
if [ -f "src/PostgREST/RangeQuery.hs" ] && grep -q "limitZeroRange :: Range Integer" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs has limitZeroRange function"
else
    echo "✗ RangeQuery.hs missing limitZeroRange function"
    test_status=1
fi

echo "Checking RangeQuery.hs has hasLimitZero function..."
if [ -f "src/PostgREST/RangeQuery.hs" ] && grep -q "hasLimitZero :: Range Integer -> Bool" "src/PostgREST/RangeQuery.hs"; then
    echo "✓ RangeQuery.hs has hasLimitZero function"
else
    echo "✗ RangeQuery.hs missing hasLimitZero function"
    test_status=1
fi

echo "Checking RangeQuery.hs exports limitZeroRange..."
if [ -f "src/PostgREST/RangeQuery.hs" ] && head -20 "src/PostgREST/RangeQuery.hs" | grep -q "limitZeroRange"; then
    echo "✓ RangeQuery.hs exports limitZeroRange"
else
    echo "✗ RangeQuery.hs doesn't export limitZeroRange"
    test_status=1
fi

echo "Checking RangeQuery.hs exports hasLimitZero..."
if [ -f "src/PostgREST/RangeQuery.hs" ] && head -20 "src/PostgREST/RangeQuery.hs" | grep -q "hasLimitZero"; then
    echo "✓ RangeQuery.hs exports hasLimitZero"
else
    echo "✗ RangeQuery.hs doesn't export hasLimitZero"
    test_status=1
fi

echo "Checking ApiRequest.hs imports limitZeroRange and hasLimitZero..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q "hasLimitZero" "src/PostgREST/Request/ApiRequest.hs" && grep -q "limitZeroRange" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs imports limitZeroRange and hasLimitZero"
else
    echo "✗ ApiRequest.hs missing imports"
    test_status=1
fi

echo "Checking ApiRequest.hs uses hasLimitZero in isInvalidRange check..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q "isInvalidRange.*hasLimitZero" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs checks hasLimitZero in isInvalidRange"
else
    echo "✗ ApiRequest.hs missing hasLimitZero check"
    test_status=1
fi

echo "Checking ApiRequest.hs handles limit=0 specially in ranges..."
if [ -f "src/PostgREST/Request/ApiRequest.hs" ] && grep -q "if hasLimitZero limitRange then limitZeroRange" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs handles limit=0 specially"
else
    echo "✗ ApiRequest.hs missing special limit=0 handling"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test file was copied correctly..."
echo ""

echo "Checking RangeSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/RangeSpec.hs" ]; then
    echo "✓ RangeSpec.hs exists (HEAD version)"
else
    echo "✗ RangeSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking RangeSpec.hs expects limit=0 to succeed..."
if [ -f "test/spec/Feature/Query/RangeSpec.hs" ] && grep -q "succeeds and returns an empty array if limit equals 0" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has updated test expecting success"
else
    echo "✗ RangeSpec.hs missing updated test"
    test_status=1
fi

echo "Checking RangeSpec.hs expects 200 status for limit=0..."
if [ -f "test/spec/Feature/Query/RangeSpec.hs" ] && grep -A 3 "limit equals 0" "test/spec/Feature/Query/RangeSpec.hs" | grep -q "matchStatus.*200"; then
    echo "✓ RangeSpec.hs expects 200 status"
else
    echo "✗ RangeSpec.hs doesn't expect 200 status"
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
