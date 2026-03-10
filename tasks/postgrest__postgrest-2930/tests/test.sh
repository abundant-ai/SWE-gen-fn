#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying embedded filter counts fix..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RelatedQueriesSpec.hs" "test/spec/Feature/Query/RelatedQueriesSpec.hs"

# Check that pgFmtLogicTreeCount is used in readPlanToCountQuery
echo "Checking QueryBuilder.hs uses pgFmtLogicTreeCount..."
if grep -q 'map (pgFmtLogicTreeCount qi) logicForest' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses pgFmtLogicTreeCount"
else
    echo "✗ QueryBuilder.hs not using pgFmtLogicTreeCount - fix not applied"
    test_status=1
fi

# Check that pgFmtLogicTreeCount function is defined
echo "Checking pgFmtLogicTreeCount function is defined..."
if grep -q 'pgFmtLogicTreeCount :: QualifiedIdentifier -> CoercibleLogicTree -> SQL.Snippet' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ pgFmtLogicTreeCount function is defined"
else
    echo "✗ pgFmtLogicTreeCount function missing - fix not applied"
    test_status=1
fi

# Check that findNullEmbedRel helper is defined
echo "Checking findNullEmbedRel helper is defined..."
if grep -q 'findNullEmbedRel fld = find' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ findNullEmbedRel helper is defined"
else
    echo "✗ findNullEmbedRel helper missing - fix not applied"
    test_status=1
fi

# Check that pgFmtLogicTreeCount handles CoercibleFilterNullEmbed
echo "Checking pgFmtLogicTreeCount handles CoercibleFilterNullEmbed..."
if grep -q 'pgFmtLogicTreeCount _ (CoercibleStmnt (CoercibleFilterNullEmbed hasNot fld))' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ pgFmtLogicTreeCount handles CoercibleFilterNullEmbed"
else
    echo "✗ pgFmtLogicTreeCount not handling CoercibleFilterNullEmbed - fix not applied"
    test_status=1
fi

# Check that pgFmtFilter is exported from SqlFragment module
echo "Checking SqlFragment.hs exports pgFmtFilter..."
if grep -q ', pgFmtFilter' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports pgFmtFilter"
else
    echo "✗ SqlFragment.hs missing pgFmtFilter export - fix not applied"
    test_status=1
fi

# Check that test file has Network.HTTP.Types import (should be present after fix)
echo "Checking RelatedQueriesSpec.hs has Network.HTTP.Types import..."
if grep -q '^import Network.HTTP.Types' "test/spec/Feature/Query/RelatedQueriesSpec.hs"; then
    echo "✓ RelatedQueriesSpec.hs has Network.HTTP.Types import"
else
    echo "✗ RelatedQueriesSpec.hs missing Network.HTTP.Types import - fix not applied"
    test_status=1
fi

# Check that test file has count tests (checking for one of the removed test cases)
echo "Checking RelatedQueriesSpec.hs has count tests..."
if grep -q 'works with count=exact' "test/spec/Feature/Query/RelatedQueriesSpec.hs"; then
    echo "✓ RelatedQueriesSpec.hs has count tests"
else
    echo "✗ RelatedQueriesSpec.hs missing count tests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
