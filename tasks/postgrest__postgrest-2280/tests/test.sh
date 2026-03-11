#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for self-referential relationships (PR #2280)..."
echo ""
echo "NOTE: This PR fixes handling of self-referential relationships in views"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking DbStructure.hs uses foreign schema in relationship map key..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "addKey rel = (relTable rel, qiSchema \$ relForeignTable rel, rel)" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs uses foreign schema in relationship map key"
else
    echo "✗ DbStructure.hs missing foreign schema in addKey"
    test_status=1
fi

echo "Checking DbStructure.hs filters by foreign schema in removeInternal..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "M.filterWithKey (\\\\(QualifiedIdentifier sch _, _) _ -> sch \`elem\` schemas )" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs filters by foreign schema"
else
    echo "✗ DbStructure.hs missing foreign schema filter"
    test_status=1
fi

echo "Checking DbStructure.hs decodes relIsSelf field..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "column HD.bool <\*>" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs decodes relIsSelf field"
else
    echo "✗ DbStructure.hs missing relIsSelf field decode"
    test_status=1
fi

echo "Checking DbStructure.hs SQL includes is_self column..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "(ns1.nspname, tab.relname) = (ns2.nspname, other.relname) AS is_self" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs SQL includes is_self column"
else
    echo "✗ DbStructure.hs SQL missing is_self column"
    test_status=1
fi

echo "Checking DbStructure.hs addViewM2ORels sets relIsSelf for self-references..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "vw1 = keyDepView vwTbl" "src/PostgREST/DbStructure.hs" && grep -q "(vw1 == vw2)" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs addViewM2ORels sets relIsSelf for self-references"
else
    echo "✗ DbStructure.hs addViewM2ORels missing relIsSelf for self-references"
    test_status=1
fi

echo "Checking DbStructure.hs addO2MRels includes isSelf parameter..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "Relationship ft t isSelf (O2M cons" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs addO2MRels includes isSelf"
else
    echo "✗ DbStructure.hs addO2MRels missing isSelf parameter"
    test_status=1
fi

echo "Checking DbStructure.hs addM2MRels computes isSelf..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "Relationship t ft (t == ft) (M2M" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs addM2MRels computes isSelf"
else
    echo "✗ DbStructure.hs addM2MRels missing isSelf computation"
    test_status=1
fi

echo "Checking Relationship.hs has relIsSelf field..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "relIsSelf       :: Bool" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs has relIsSelf field"
else
    echo "✗ Relationship.hs missing relIsSelf field"
    test_status=1
fi

echo "Checking Relationship.hs removes isSelfReference function..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && ! grep -q "isSelfReference :: Relationship -> Bool" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs removes old isSelfReference function"
else
    echo "✗ Relationship.hs still has old isSelfReference function"
    test_status=1
fi

echo "Checking Relationship.hs RelationshipsMap uses tuple key..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "type RelationshipsMap = M.HashMap (QualifiedIdentifier, Schema)" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs RelationshipsMap uses tuple key"
else
    echo "✗ Relationship.hs RelationshipsMap missing tuple key"
    test_status=1
fi

echo "Checking OpenAPI.hs uses foreign schema in lookup..."
if [ -f "src/PostgREST/OpenAPI.hs" ] && grep -q "M.lookup (QualifiedIdentifier (tableSchema tbl) (tableName tbl), tableSchema tbl) rels" "src/PostgREST/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs uses foreign schema in lookup"
else
    echo "✗ OpenAPI.hs missing foreign schema in lookup"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs removes self-reference special case..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && ! grep -q "Here we handle a self reference relationship to not cause a breaking" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs removes self-reference special case"
else
    echo "✗ DbRequestBuilder.hs still has old self-reference special case"
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
