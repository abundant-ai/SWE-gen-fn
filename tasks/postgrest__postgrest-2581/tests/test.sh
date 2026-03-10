#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
cp "/tests/spec/Feature/Query/SpreadQueriesSpec.hs" "test/spec/Feature/Query/SpreadQueriesSpec.hs"

test_status=0

echo "Verifying fix for spread embed syntax change from ... to .. (PR #2581)..."
echo ""
echo "NOTE: This PR changes the spread embed syntax from three dots (...) to two dots (..)"
echo "HEAD (fixed) should use ... (three dots) for spread embeds"
echo "BASE (buggy) uses .. (two dots) for spread embeds"
echo ""

# Check CHANGELOG.md - HEAD should have ... syntax
echo "Checking CHANGELOG.md has ... syntax for spread embeds..."
if grep -q "select=\*,\.\.\." "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has ... (three dots) syntax"
else
    echo "✗ CHANGELOG.md missing ... syntax - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have ... in parser code
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has ... in parser..."
if grep -q 'name <- string "\.\.\." >> pFieldName' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs parser uses ... (three dots)"
else
    echo "✗ QueryParams.hs parser not using ... - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have ... in doctest comments
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has ... in doctests..."
if grep -q 'P.parse pSpreadRelationSelect "" "\.\.\.*rel(\*)"' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs doctests use ... (three dots)"
else
    echo "✗ QueryParams.hs doctests not using ... - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should expect ... in error messages
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs expects ... in error messages..."
if grep -q 'expecting "\.\.\."' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs error messages expect ... (three dots)"
else
    echo "✗ QueryParams.hs error messages not expecting ... - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have ... in pFieldForest doctest
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs pFieldForest doctest has ... syntax..."
if grep -q 'P.parse pFieldForest "" "\*,\.\.\.*client(\*),other(\*)"' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs pFieldForest doctest uses ... (three dots)"
else
    echo "✗ QueryParams.hs pFieldForest doctest not using ... - fix not applied"
    test_status=1
fi

# Check EmbedDisambiguationSpec.hs - HEAD should have ... in spread embed tests
echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has ... in spread embeds..."
if grep -q 'whatev_jobs!site_id_1(\.\.\.*whatev_projects!project_id_1(\*))' "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs uses ... (three dots) in spread embeds"
else
    echo "✗ EmbedDisambiguationSpec.hs not using ... in spread embeds - fix not applied"
    test_status=1
fi

# Check EmbedDisambiguationSpec.hs - HEAD should have ... in recursive m2m test
echo "Checking test/spec/Feature/Query/EmbedDisambiguationSpec.hs has ... in recursive m2m test..."
if grep -q 'subscriptions!subscribed(\.\.\.*posters!subscriber(\*))' "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs uses ... (three dots) in recursive m2m"
else
    echo "✗ EmbedDisambiguationSpec.hs not using ... in recursive m2m - fix not applied"
    test_status=1
fi

# Check SpreadQueriesSpec.hs - HEAD should have ... in spread query tests
echo "Checking test/spec/Feature/Query/SpreadQueriesSpec.hs has ... in spread queries..."
if grep -q 'select=id,\.\.\.*clients(client_name:name)' "test/spec/Feature/Query/SpreadQueriesSpec.hs"; then
    echo "✓ SpreadQueriesSpec.hs uses ... (three dots) in spread queries"
else
    echo "✗ SpreadQueriesSpec.hs not using ... in spread queries - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - spread embed syntax changed to ... successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
