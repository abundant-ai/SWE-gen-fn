#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

test_status=0

echo "Verifying fix for plan media type handling (#2833)..."
echo ""

# Check src/PostgREST/MediaType.hs for MTPlanFormat import
echo "Checking src/PostgREST/ApiRequest.hs for MTPlanFormat import..."
if grep -q "import PostgREST.MediaType.*MTPlanFormat" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs imports MTPlanFormat"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing MTPlanFormat import - fix not applied"
    test_status=1
fi

# Check that MTPlan uses non-Maybe types (MediaType MTPlanFormat [MTPlanOption])
echo "Checking src/PostgREST/MediaType.hs for non-Maybe MTPlan definition..."
if grep -q "MTPlan MediaType MTPlanFormat \[MTPlanOption\]" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has non-Maybe MTPlan definition"
else
    echo "✗ src/PostgREST/MediaType.hs missing correct MTPlan definition - fix not applied"
    test_status=1
fi

# Check that Data.Maybe (fromJust) is NOT imported
echo "Checking src/PostgREST/MediaType.hs for absence of fromJust import..."
if grep -q "import.*Data.Maybe.*fromJust" "src/PostgREST/MediaType.hs"; then
    echo "✗ src/PostgREST/MediaType.hs still has fromJust import - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/MediaType.hs does not import fromJust"
fi

# Check that toMime uses direct field access (not isNothing/fromJust pattern)
echo "Checking src/PostgREST/MediaType.hs toMime function for direct field access..."
if grep -q 'toMime (MTPlan mt fmt opts) =' "src/PostgREST/MediaType.hs" && \
   grep -q '"application/vnd.pgrst.plan+" <> toMimePlanFormat fmt' "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs toMime uses direct field access"
else
    echo "✗ src/PostgREST/MediaType.hs toMime not using correct pattern - fix not applied"
    test_status=1
fi

# Check that producedMediaTypes uses MTPlan MTApplicationJSON PlanText mempty
echo "Checking src/PostgREST/ApiRequest.hs for correct MTPlan default..."
if grep -q "MTPlan MTApplicationJSON PlanText mempty" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs uses correct MTPlan default"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing correct MTPlan default - fix not applied"
    test_status=1
fi

# Check test file for correct Content-Type expectations with for parameter
echo "Checking test/spec/Feature/Query/PlanSpec.hs for correct Content-Type with 'for' parameter..."
if grep -q 'application/vnd.pgrst.plan+json; for=\\"application/json\\"; charset=utf-8' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ test/spec/Feature/Query/PlanSpec.hs expects correct Content-Type with 'for' parameter"
else
    echo "✗ test/spec/Feature/Query/PlanSpec.hs missing correct Content-Type expectations - fix not applied"
    test_status=1
fi

# Check that explainF uses MTPlanFormat (not Maybe MTPlanFormat)
echo "Checking src/PostgREST/Query/SqlFragment.hs for non-Maybe MTPlanFormat..."
if grep -q "explainF :: MTPlanFormat -> \[MTPlanOption\]" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs uses non-Maybe MTPlanFormat"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing correct type signature - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
