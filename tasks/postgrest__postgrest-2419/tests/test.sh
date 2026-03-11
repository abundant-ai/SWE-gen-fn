#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for computed relationships feature (PR #2419)..."
echo ""
echo "NOTE: This PR adds computed relationships feature to PostgREST"
echo "BASE (buggy) does not have computed relationships code"
echo "HEAD (fixed) adds computed relationships with allComputedRels function and ComputedRelationship type"
echo ""

# Check CHANGELOG - HEAD should have computed relationships entry
echo "Checking CHANGELOG.md has computed relationships entry..."
if grep -q "#2144, Allow extending/overriding relationships for resource embedding - @steve-chavez" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has '#2144, Allow extending/overriding relationships' entry"
else
    echo "✗ CHANGELOG.md does not have computed relationships entry - fix not applied"
    test_status=1
fi

# Check that #2397 entry is in Fixed section, not in Added section (it should appear after #2410)
if grep -A 30 "^### Fixed" "CHANGELOG.md" | grep -q "#2397, Fix race conditions managing database connection helper"; then
    echo "✓ CHANGELOG.md has #2397 in Fixed section"
else
    echo "✗ CHANGELOG.md does not have #2397 in Fixed section - fix not applied"
    test_status=1
fi

# Check postgrest.cabal - HEAD should have ComputedRelsSpec test
echo "Checking postgrest.cabal includes ComputedRelsSpec test..."
if grep -q "Feature.Query.ComputedRelsSpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes Feature.Query.ComputedRelsSpec"
else
    echo "✗ postgrest.cabal does not include ComputedRelsSpec - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should have allComputedRels function
echo "Checking src/PostgREST/DbStructure.hs has allComputedRels function..."
if grep -q "allComputedRels :: Bool -> SQL.Statement () \[Relationship\]" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs has allComputedRels function signature"
else
    echo "✗ DbStructure.hs does not have allComputedRels function - fix not applied"
    test_status=1
fi

# Check that cRels is defined and used
if grep -q "cRels   <- SQL.statement mempty \$ allComputedRels prepared" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs queries computed relationships with cRels"
else
    echo "✗ DbStructure.hs does not query cRels - fix not applied"
    test_status=1
fi

# Check that getOverrideRelationshipsMap is used
if grep -q "getOverrideRelationshipsMap rels cRels" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs uses getOverrideRelationshipsMap"
else
    echo "✗ DbStructure.hs does not use getOverrideRelationshipsMap - fix not applied"
    test_status=1
fi

# Check that hasInternalJunction handles ComputedRelationship
if grep -q "hasInternalJunction ComputedRelationship{} = False" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs hasInternalJunction handles ComputedRelationship"
else
    echo "✗ DbStructure.hs does not handle ComputedRelationship in hasInternalJunction - fix not applied"
    test_status=1
fi

# Check DbStructure/Relationship.hs - HEAD should have ComputedRelationship type
echo "Checking src/PostgREST/DbStructure/Relationship.hs has ComputedRelationship type..."
if grep -q "| ComputedRelationship" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs has ComputedRelationship data constructor"
else
    echo "✗ Relationship.hs does not have ComputedRelationship type - fix not applied"
    test_status=1
fi

if grep -q "relFunction     :: QualifiedIdentifier" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs ComputedRelationship has relFunction field"
else
    echo "✗ Relationship.hs ComputedRelationship does not have relFunction field - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - computed relationships feature added successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
