#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RelatedQueriesSpec.hs" "test/spec/Feature/Query/RelatedQueriesSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SpreadQueriesSpec.hs" "test/spec/Feature/Query/SpreadQueriesSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

test_status=0

echo "Verifying fix for spreading embedded resources (PR #2564)..."
echo ""
echo "NOTE: This PR adds spread queries to unnest JSON objects in M2O/O2O relationships"
echo "HEAD (fixed) should have SpreadRelation, SpreadQueriesSpec, and spread query parser"
echo "BASE (buggy) lacks spread queries feature entirely"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for spreading embedded resources
echo "Checking CHANGELOG.md mentions spreading embedded resources..."
if grep -q "#1233, Allow spreading embedded resources" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions spreading embedded resources"
else
    echo "✗ CHANGELOG.md missing spread queries entry - fix not applied"
    test_status=1
fi

# Check postgrest.cabal - HEAD should include SpreadQueriesSpec module
echo "Checking postgrest.cabal includes SpreadQueriesSpec module..."
if grep -q "Feature.Query.SpreadQueriesSpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes SpreadQueriesSpec module"
else
    echo "✗ postgrest.cabal missing SpreadQueriesSpec - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have example for spread queries
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has spread query example..."
if grep -q '\*,\.\.client(\*)' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has spread query example"
else
    echo "✗ QueryParams.hs missing spread query example - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have pSpreadRelationSelect parser
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pSpreadRelationSelect parser..."
if grep -q "pSpreadRelationSelect :: Parser SelectItem" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has pSpreadRelationSelect parser"
else
    echo "✗ QueryParams.hs missing pSpreadRelationSelect parser - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should use pSpreadRelationSelect in pFieldTree
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs uses pSpreadRelationSelect in parser..."
if grep "pFieldTree" "src/PostgREST/ApiRequest/QueryParams.hs" | grep -q "pSpreadRelationSelect"; then
    echo "✓ QueryParams.hs uses pSpreadRelationSelect in parser"
else
    echo "✗ QueryParams.hs not using pSpreadRelationSelect - fix not applied"
    test_status=1
fi

# Check Types.hs - HEAD should have SpreadRelation data constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has SpreadRelation..."
if grep -q "| SpreadRelation" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has SpreadRelation data constructor"
else
    echo "✗ Types.hs missing SpreadRelation - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should handle SpreadNotToOne errors
echo "Checking src/PostgREST/Error.hs handles SpreadNotToOne errors..."
if grep -q "SpreadNotToOne" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs handles SpreadNotToOne errors"
else
    echo "✗ Error.hs missing SpreadNotToOne handling - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should validate spread embeds on to-one relationships
echo "Checking src/PostgREST/Plan.hs validates spread embeds..."
if grep -q "spread embeds are only done on to-one relationships" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs validates spread embeds"
else
    echo "✗ Plan.hs missing spread embed validation - fix not applied"
    test_status=1
fi

# Check SpreadQueriesSpec.hs - HEAD should HAVE the test file
echo "Checking test/spec/Feature/Query/SpreadQueriesSpec.hs exists..."
if [ -f "test/spec/Feature/Query/SpreadQueriesSpec.hs" ]; then
    echo "✓ SpreadQueriesSpec.hs exists"
else
    echo "✗ SpreadQueriesSpec.hs missing - fix not applied"
    test_status=1
fi

# Check Main.hs - HEAD should import SpreadQueriesSpec
echo "Checking test/spec/Main.hs imports SpreadQueriesSpec..."
if grep -q "Feature.Query.SpreadQueriesSpec" "test/spec/Main.hs"; then
    echo "✓ Main.hs imports SpreadQueriesSpec"
else
    echo "✗ Main.hs missing SpreadQueriesSpec import - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - spread queries feature applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
