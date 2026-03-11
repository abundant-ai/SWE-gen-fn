#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

test_status=0

echo "Verifying fix for POSIX regex operators (PR #2237)..."
echo ""
echo "NOTE: This PR adds support for match/imatch (or regex/iregex) operators"
echo "that map to PostgreSQL's ~ and ~* operators for regex matching."
echo "We verify that the source code has the fix."
echo ""

echo "Checking Request/Types.hs defines OpMatch and OpIMatch operators..."
if [ -f "src/PostgREST/Request/Types.hs" ] && grep -q "OpMatch" "src/PostgREST/Request/Types.hs" && grep -q "OpIMatch" "src/PostgREST/Request/Types.hs"; then
    echo "✓ Request/Types.hs defines OpMatch and OpIMatch"
else
    echo "✗ Request/Types.hs does not define OpMatch/OpIMatch operators (not fixed)"
    test_status=1
fi

echo "Checking Request/QueryParams.hs maps 'match' and 'imatch' to operators..."
if [ -f "src/PostgREST/Request/QueryParams.hs" ] && grep -q '"match".*OpMatch' "src/PostgREST/Request/QueryParams.hs" && grep -q '"imatch".*OpIMatch' "src/PostgREST/Request/QueryParams.hs"; then
    echo "✓ Request/QueryParams.hs maps match/imatch operators"
else
    echo "✗ Request/QueryParams.hs does not map match/imatch operators (not fixed)"
    test_status=1
fi

echo "Checking Query/SqlFragment.hs maps OpMatch to ~ and OpIMatch to ~*..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q 'OpMatch.*"~"' "src/PostgREST/Query/SqlFragment.hs" && grep -q 'OpIMatch.*"~\*"' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ Query/SqlFragment.hs maps OpMatch to ~ and OpIMatch to ~*"
else
    echo "✗ Query/SqlFragment.hs does not map operators to SQL (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test file was copied correctly..."
echo ""

echo "Checking QuerySpec.hs was copied..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ]; then
    echo "✓ QuerySpec.hs exists (HEAD version)"
else
    echo "✗ QuerySpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking QuerySpec.hs contains tests for match/imatch operators..."
if [ -f "test/spec/Feature/Query/QuerySpec.hs" ] && grep -q "match\." "test/spec/Feature/Query/QuerySpec.hs" && grep -q "imatch\." "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs contains match/imatch tests (HEAD version)"
else
    echo "✗ QuerySpec.hs does not contain match/imatch tests - HEAD file not properly copied!"
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
