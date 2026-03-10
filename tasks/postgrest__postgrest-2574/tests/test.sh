#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

test_status=0

echo "Verifying fix for empty embed support (PR #2574)..."
echo ""
echo "NOTE: This PR adds support for empty embeds like 'clients()' and empty root selects"
echo "HEAD (fixed) should HAVE empty embed parsing and handling logic"
echo "BASE (buggy) does NOT support empty embeds - they cause errors"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for empty embed support
echo "Checking CHANGELOG.md mentions empty embed support..."
if grep -q "Allow embedding without selecting any column" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions empty embed support"
else
    echo "✗ CHANGELOG.md missing empty embed entry - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should import sepBy (in addition to sepBy1)
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs imports sepBy..."
if grep "import.*ParserCombinators.Parsec" -A10 "src/PostgREST/ApiRequest/QueryParams.hs" | grep -q "sepBy,"; then
    echo "✓ QueryParams.hs imports sepBy"
else
    echo "✗ QueryParams.hs does not import sepBy - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should use sepBy in pFieldForest (allows empty list)
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs pFieldForest uses sepBy..."
if grep -A2 "pFieldForest :: Parser" "src/PostgREST/ApiRequest/QueryParams.hs" | grep -q 'sepBy.*char.*,'; then
    echo "✓ pFieldForest uses sepBy (allows empty)"
else
    echo "✗ pFieldForest does not use sepBy - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have updated doctest showing empty select is allowed
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has doctest for empty select..."
if grep -q 'P.parse pFieldForest "" ""' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has doctest for empty select"
else
    echo "✗ QueryParams.hs missing doctest for empty select - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should HAVE isRoot parameter (added back)
echo "Checking src/PostgREST/Query/QueryBuilder.hs readPlanToQuery signature..."
if grep -q "readPlanToQuery :: Bool -> ReadPlanTree" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ readPlanToQuery has Bool parameter"
else
    echo "✗ readPlanToQuery missing Bool parameter - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should HAVE defRootSelect (added back)
echo "Checking src/PostgREST/Query/QueryBuilder.hs has defRootSelect..."
if grep -q "defRootSelect" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has defRootSelect"
else
    echo "✗ QueryBuilder.hs missing defRootSelect - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should check "null select && null forest" (added back)
echo "Checking src/PostgREST/Query/QueryBuilder.hs getSelectsJoins checks null select..."
if grep -q "null select && null forest" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs checks null select && null forest"
else
    echo "✗ QueryBuilder.hs missing null select check - fix not applied"
    test_status=1
fi

# Check Query.hs - HEAD should call readPlanToQuery WITH True parameter
echo "Checking src/PostgREST/Query.hs calls readPlanToQuery with Bool..."
if grep -q "readPlanToQuery True" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs calls readPlanToQuery with Bool parameter"
else
    echo "✗ Query.hs missing Bool parameter - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should HAVE empty embed tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has empty embed tests..."
if grep -q "empty embed" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has empty embed tests"
else
    echo "✗ QuerySpec.hs missing empty embed tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should test "clients()" empty embed syntax
echo "Checking test/spec/Feature/Query/QuerySpec.hs tests clients() syntax..."
if grep -q "clients()" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs tests empty embed syntax"
else
    echo "✗ QuerySpec.hs missing empty embed syntax tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should test "clients!inner()" with filtering
echo "Checking test/spec/Feature/Query/QuerySpec.hs tests inner join with empty embed..."
if grep -q "clients!inner()" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs tests inner join with empty embed"
else
    echo "✗ QuerySpec.hs missing inner join empty embed tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs - HEAD should test "select=" empty root select
echo "Checking test/spec/Feature/Query/QuerySpec.hs tests empty root select..."
if grep -q "empty root select" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs tests empty root select"
else
    echo "✗ QuerySpec.hs missing empty root select tests - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - empty embed support added successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
