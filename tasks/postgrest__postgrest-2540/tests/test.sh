#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for computed relationships without SETOF (PR #2540)..."
echo ""
echo "NOTE: This PR fixes an issue where PostgREST didn't properly handle computed"
echo "relationships defined without SETOF (returning scalar row type instead)."
echo "HEAD (fixed) should treat non-SETOF functions as M2O/O2O relationships"
echo "BASE (buggy) only recognizes SETOF functions with ROWS 1 as single-row"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for computed relationships SETOF fix
echo "Checking CHANGELOG.md mentions computed relationships SETOF fix..."
if grep -q "#2481, Treat computed relationships not marked SETOF as M2O/O2O relationship" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions computed relationships fix"
else
    echo "✗ CHANGELOG.md missing computed relationships fix entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs - HEAD should include the fixed single_row logic
echo "Checking src/PostgREST/SchemaCache.hs includes correct single_row calculation..."
# Looking for "not p.proretset or p.prorows = 1 as single_row" (may have varied spacing)
if grep "as single_row" "src/PostgREST/SchemaCache.hs" | grep -q "not p.proretset or p.prorows = 1"; then
    echo "✓ SchemaCache.hs includes correct single_row calculation (not p.proretset or p.prorows = 1)"
else
    echo "✗ SchemaCache.hs missing correct single_row calculation - fix not applied"
    test_status=1
fi

# Check ComputedRelsSpec.hs - HEAD should HAVE the test case for computed_designers_noset
echo "Checking test/spec/Feature/Query/ComputedRelsSpec.hs has computed_designers_noset test..."
if grep -q "can define a many-to-one relationship without SETOF and embed" "test/spec/Feature/Query/ComputedRelsSpec.hs"; then
    echo "✓ ComputedRelsSpec.hs has computed_designers_noset test case"
else
    echo "✗ ComputedRelsSpec.hs missing computed_designers_noset test case - fix not applied"
    test_status=1
fi

# Check that the test uses computed_designers_noset endpoint
echo "Checking ComputedRelsSpec.hs test uses computed_designers_noset..."
if grep -q 'get "/videogames?select=name,designer:computed_designers_noset(name)"' "test/spec/Feature/Query/ComputedRelsSpec.hs"; then
    echo "✓ ComputedRelsSpec.hs test uses computed_designers_noset endpoint"
else
    echo "✗ ComputedRelsSpec.hs test doesn't use computed_designers_noset - fix not applied"
    test_status=1
fi

# Check that the test expects the correct JSON response with designer field
echo "Checking ComputedRelsSpec.hs test expects correct JSON with designer field..."
if grep -A 5 'get "/videogames?select=name,designer:computed_designers_noset(name)"' "test/spec/Feature/Query/ComputedRelsSpec.hs" | grep -q '{"name":"Civilization I","designer":{"name":"Sid Meier"}}'; then
    echo "✓ ComputedRelsSpec.hs test expects correct JSON response"
else
    echo "✗ ComputedRelsSpec.hs test doesn't expect correct response - fix not applied"
    test_status=1
fi

# Check the !inner join test case with computed_designers_noset
echo "Checking ComputedRelsSpec.hs has !inner join test with computed_designers_noset..."
if grep "computed_designers_noset!inner" "test/spec/Feature/Query/ComputedRelsSpec.hs" | grep -q "designer.name=like"; then
    echo "✓ ComputedRelsSpec.hs has !inner join test case"
else
    echo "✗ ComputedRelsSpec.hs missing !inner join test case - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should HAVE the computed_designers_noset function
echo "Checking test/spec/fixtures/schema.sql has computed_designers_noset function..."
if grep -q "CREATE FUNCTION test.computed_designers_noset(test.videogames) RETURNS test.designers" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has computed_designers_noset function"
else
    echo "✗ schema.sql missing computed_designers_noset function - fix not applied"
    test_status=1
fi

# Check that the function doesn't use SETOF (scalar return type)
echo "Checking computed_designers_noset uses scalar return type (not SETOF)..."
if grep -A 2 "CREATE FUNCTION test.computed_designers_noset(test.videogames) RETURNS test.designers" "test/spec/fixtures/schema.sql" | grep -q "SETOF"; then
    echo "✗ computed_designers_noset incorrectly uses SETOF - should be scalar return"
    test_status=1
else
    echo "✓ computed_designers_noset uses scalar return type"
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - computed relationships SETOF fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
