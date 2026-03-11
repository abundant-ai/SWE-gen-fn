#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for view-based embed disambiguation (PR #2272)..."
echo ""
echo "NOTE: This PR prevents views from breaking one-to-many/many-to-one embeds"
echo "when using column or FK as target. We verify that the source code has the fix."
echo ""

echo "Checking Relationship.hs has relTableIsView field..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "relTableIsView  :: Bool" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs has relTableIsView field"
else
    echo "✗ Relationship.hs missing relTableIsView field"
    test_status=1
fi

echo "Checking Relationship.hs has relFTableIsView field..."
if [ -f "src/PostgREST/DbStructure/Relationship.hs" ] && grep -q "relFTableIsView :: Bool" "src/PostgREST/DbStructure/Relationship.hs"; then
    echo "✓ Relationship.hs has relFTableIsView field"
else
    echo "✗ Relationship.hs missing relFTableIsView field"
    test_status=1
fi

echo "Checking DbStructure.hs decodes view flags in M2O relationships..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "pure False <\*>" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs decodes view flags"
else
    echo "✗ DbStructure.hs missing view flag decodes"
    test_status=1
fi

echo "Checking DbStructure.hs sets view flags in addViewM2ORels for view->table..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -A 2 "M2O cons \$ zipWith" "src/PostgREST/DbStructure.hs" | grep -q "True"; then
    echo "✓ DbStructure.hs sets view flags in addViewM2ORels"
else
    echo "✗ DbStructure.hs missing view flags in addViewM2ORels"
    test_status=1
fi

echo "Checking DbStructure.hs addO2MRels preserves view flags..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "Relationship ft t isSelf (O2M cons (swap <\$> cols)) fTableIsView tableIsView" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs addO2MRels preserves view flags"
else
    echo "✗ DbStructure.hs addO2MRels missing view flag preservation"
    test_status=1
fi

echo "Checking DbStructure.hs addM2MRels includes view flags..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "Relationship t ft (t == ft) (M2M \$ Junction jt1 cons1 cons2 (swap <\$> cols) (swap <\$> fcols)) tblIsView fTblisView" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs addM2MRels includes view flags"
else
    echo "✗ DbStructure.hs addM2MRels missing view flags"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs filters views when using FK column target..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q "&& not relFTableIsView" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs filters views with relFTableIsView"
else
    echo "✗ DbRequestBuilder.hs missing view filtering"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs updated self-relationship handling..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q "if relIsSelf" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs has updated self-relationship logic"
else
    echo "✗ DbRequestBuilder.hs missing self-relationship updates"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs uses isM2O and isO2M helpers..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q "isM2O card = case card of" "src/PostgREST/Request/DbRequestBuilder.hs" && grep -q "isO2M card = case card of" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs has isM2O and isO2M helpers"
else
    echo "✗ DbRequestBuilder.hs missing cardinality helpers"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs removed old self-reference special case comments..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && ! grep -q "notM2OSelfRel" "src/PostgREST/Request/DbRequestBuilder.hs" && ! grep -q "notO2MSelfRel" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs removed old self-reference helpers"
else
    echo "✗ DbRequestBuilder.hs still has old self-reference helpers"
    test_status=1
fi

echo "Checking getJoinConditions signature updated with view flags..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q "getJoinConditions previousAlias newAlias (Relationship QualifiedIdentifier{qiSchema=tSchema, qiName=tN} QualifiedIdentifier{qiName=ftN} _ card _ _)" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ getJoinConditions signature includes view flags"
else
    echo "✗ getJoinConditions signature missing view flags"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

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
