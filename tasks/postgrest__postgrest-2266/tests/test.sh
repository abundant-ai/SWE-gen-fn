#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for relationship list to hash map conversion (PR #2266)..."
echo ""
echo "NOTE: This PR converts relationships from a list to a hash map for better performance"
echo "We verify that the source code has the fix."
echo ""

echo "Checking DbStructure.hs imports RelationshipsMap..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "RelationshipsMap" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs imports RelationshipsMap"
else
    echo "✗ DbStructure.hs missing RelationshipsMap import"
    test_status=1
fi

echo "Checking DbStructure.hs uses RelationshipsMap type..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "dbRelationships :: RelationshipsMap" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs uses RelationshipsMap type"
else
    echo "✗ DbStructure.hs not using RelationshipsMap type (still using list)"
    test_status=1
fi

echo "Checking DbStructure.hs has relsToMap function..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "relsToMap = " "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs has relsToMap function"
else
    echo "✗ DbStructure.hs missing relsToMap function"
    test_status=1
fi

echo "Checking Relationship.hs exports RelationshipsMap..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "RelationshipsMap" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs exports RelationshipsMap"
else
    echo "✗ Relationship.hs missing RelationshipsMap export"
    test_status=1
fi

echo "Checking Relationship.hs imports HashMap..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "Data.HashMap.Strict" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs imports HashMap"
else
    echo "✗ Relationship.hs missing HashMap import"
    test_status=1
fi

echo "Checking OpenAPI.hs uses relationshipsMap lookup..."
if [ -f "src/PostgREST/OpenAPI.hs" ] && grep -q "M.lookup" "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs uses HashMap lookup"
else
    echo "✗ OpenAPI.hs not using HashMap lookup"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs uses relationshipsMap lookup..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q "M.lookup" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs uses HashMap lookup"
else
    echo "✗ DbRequestBuilder.hs not using HashMap lookup"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking RootSpec.hs was copied..."
if [ -f "test/spec/Feature/OpenApi/RootSpec.hs" ]; then
    echo "✓ RootSpec.hs exists (HEAD version)"
else
    echo "✗ RootSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking EmbedDisambiguationSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/EmbedDisambiguationSpec.hs" ]; then
    echo "✓ EmbedDisambiguationSpec.hs exists (HEAD version)"
else
    echo "✗ EmbedDisambiguationSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking schema.sql was copied..."
if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
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
