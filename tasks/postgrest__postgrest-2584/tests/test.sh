#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
cp "/tests/spec/Feature/Query/RelatedQueriesSpec.hs" "test/spec/Feature/Query/RelatedQueriesSpec.hs"

test_status=0

echo "Verifying fix for is.null/not.is.null on embedded resources (PR #2584)..."
echo ""
echo "NOTE: This PR adds support for is.null and not.is.null filters on embedded resources"
echo "HEAD (fixed) should have FilterNullEmbed, UnacceptableFilter, and addNullEmbedFilters"
echo "BASE (buggy) removes these features"
echo ""

# Check ApiRequest/Types.hs - HEAD should HAVE UnacceptableFilter error type
echo "Checking src/PostgREST/ApiRequest/Types.hs has UnacceptableFilter..."
if grep -q "| UnacceptableFilter Text" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs has UnacceptableFilter error type"
else
    echo "✗ ApiRequest/Types.hs missing UnacceptableFilter - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should HAVE FilterNullEmbed constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has FilterNullEmbed..."
if grep -q "| FilterNullEmbed Bool FieldName" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs has FilterNullEmbed constructor"
else
    echo "✗ ApiRequest/Types.hs missing FilterNullEmbed - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE UnacceptableFilter status handler
echo "Checking src/PostgREST/Error.hs has UnacceptableFilter status..."
if grep -q "status UnacceptableFilter{}" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has UnacceptableFilter status handler"
else
    echo "✗ Error.hs missing UnacceptableFilter status - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE UnacceptableFilter JSON serialization
echo "Checking src/PostgREST/Error.hs has UnacceptableFilter toJSON..."
if grep -q "toJSON (UnacceptableFilter target)" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has UnacceptableFilter JSON serialization"
else
    echo "✗ Error.hs missing UnacceptableFilter toJSON - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE ApiRequestErrorCode20
echo "Checking src/PostgREST/Error.hs has ApiRequestErrorCode20..."
if grep -q "| ApiRequestErrorCode20" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has ApiRequestErrorCode20"
else
    echo "✗ Error.hs missing ApiRequestErrorCode20 - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should HAVE addNullEmbedFilters in readPlan
echo "Checking src/PostgREST/Plan.hs uses addNullEmbedFilters..."
if grep -q "addNullEmbedFilters =<<" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses addNullEmbedFilters"
else
    echo "✗ Plan.hs missing addNullEmbedFilters - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should HAVE addNullEmbedFilters function definition
echo "Checking src/PostgREST/Plan.hs defines addNullEmbedFilters function..."
if grep -q "addNullEmbedFilters ::" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs defines addNullEmbedFilters function"
else
    echo "✗ Plan.hs missing addNullEmbedFilters definition - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md - HEAD should HAVE entry about is.null/not.is.null feature
echo "Checking CHANGELOG.md mentions is.null/not.is.null feature..."
if grep -q "#2563.*is\.null.*not\.is\.null" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has is.null/not.is.null feature entry"
else
    echo "✗ CHANGELOG.md missing feature entry - fix not complete"
    test_status=1
fi

# Check RelatedQueriesSpec.hs - HEAD should HAVE tests for is.null filters
echo "Checking test/spec/Feature/Query/RelatedQueriesSpec.hs has is.null tests..."
if grep -q "clients=not\.is\.null" "test/spec/Feature/Query/RelatedQueriesSpec.hs" && \
   grep -q "clients=is\.null" "test/spec/Feature/Query/RelatedQueriesSpec.hs"; then
    echo "✓ RelatedQueriesSpec.hs has is.null filter tests"
else
    echo "✗ RelatedQueriesSpec.hs missing is.null tests - fix not complete"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should HAVE tests for explain with null filters
echo "Checking test/spec/Feature/Query/PlanSpec.hs has null filter tests..."
if grep -q "clients.*is\.null\|clients.*not\.is\.null" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has null filter tests"
else
    echo "✗ PlanSpec.hs missing null filter tests - fix not complete"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - is.null/not.is.null feature implemented successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
