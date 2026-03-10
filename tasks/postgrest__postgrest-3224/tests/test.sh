#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for PR #3160
echo "Checking that CHANGELOG.md includes the fix entry for #3160..."
if grep -q "#3160, Fix using select= query parameter for custom media type handlers" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry for #3160"
else
    echo "✗ CHANGELOG.md missing the fix entry for #3160 - fix not applied"
    test_status=1
fi

# Check that hasDefaultSelect function exists in src/PostgREST/Plan.hs
echo "Checking that hasDefaultSelect function exists in src/PostgREST/Plan.hs..."
if grep -q "hasDefaultSelect :: ReadPlanTree -> Bool" "src/PostgREST/Plan.hs"; then
    echo "✓ hasDefaultSelect function exists in src/PostgREST/Plan.hs"
else
    echo "✗ hasDefaultSelect function missing in src/PostgREST/Plan.hs - fix not applied"
    test_status=1
fi

# Check that negotiateContent function signature includes Bool parameter
echo "Checking that negotiateContent has correct signature with Bool parameter..."
if grep -q "negotiateContent :: AppConfig -> ApiRequest -> QualifiedIdentifier -> \[MediaType\] -> MediaHandlerMap -> Bool -> Either ApiRequestError ResolvedHandler" "src/PostgREST/Plan.hs"; then
    echo "✓ negotiateContent has correct signature with Bool parameter"
else
    echo "✗ negotiateContent missing Bool parameter - fix not applied"
    test_status=1
fi

# Check that wrappedReadPlan calls negotiateContent with hasDefaultSelect
echo "Checking that wrappedReadPlan passes hasDefaultSelect to negotiateContent..."
if grep -q "negotiateContent conf apiRequest identifier iAcceptMediaType (dbMediaHandlers sCache) (hasDefaultSelect rPlan)" "src/PostgREST/Plan.hs"; then
    echo "✓ wrappedReadPlan passes hasDefaultSelect to negotiateContent"
else
    echo "✗ wrappedReadPlan not passing hasDefaultSelect - fix not applied"
    test_status=1
fi

# Check that WrappedReadPlan, MutateReadPlan, and CallReadPlan no longer have wrIdent/mrIdent/crIdent fields
echo "Checking that plan types no longer have *Ident fields..."
if ! grep -q "wrIdent.*::.*QualifiedIdentifier" "src/PostgREST/Plan.hs"; then
    echo "✓ WrappedReadPlan no longer has wrIdent field"
else
    echo "✗ WrappedReadPlan still has wrIdent field - fix not applied"
    test_status=1
fi

if ! grep -q "mrIdent.*::.*QualifiedIdentifier" "src/PostgREST/Plan.hs"; then
    echo "✓ MutateReadPlan no longer has mrIdent field"
else
    echo "✗ MutateReadPlan still has mrIdent field - fix not applied"
    test_status=1
fi

if ! grep -q "crIdent.*::.*QualifiedIdentifier" "src/PostgREST/Plan.hs"; then
    echo "✓ CallReadPlan no longer has crIdent field"
else
    echo "✗ CallReadPlan still has crIdent field - fix not applied"
    test_status=1
fi

# Check that customFuncF has new signature with RelIdentifier
echo "Checking that customFuncF has new signature with RelIdentifier..."
if grep -q "customFuncF :: Maybe Routine -> QualifiedIdentifier -> RelIdentifier -> SQL.Snippet" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ customFuncF has new signature with RelIdentifier"
else
    echo "✗ customFuncF missing RelIdentifier parameter - fix not applied"
    test_status=1
fi

# Check that handlerF has simplified signature without QualifiedIdentifier
echo "Checking that handlerF has simplified signature..."
if grep -q "handlerF :: Maybe Routine -> MediaHandler -> SQL.Snippet" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ handlerF has simplified signature"
else
    echo "✗ handlerF still has old signature - fix not applied"
    test_status=1
fi

# Check that when' helper function is defined in negotiateContent
echo "Checking that when' helper function is defined..."
if grep -A 2 "when' :: Bool -> Maybe a -> Maybe a" "src/PostgREST/Plan.hs" | grep -q "when' True (Just a) = Just a"; then
    echo "✓ when' helper function is defined correctly"
else
    echo "✗ when' helper function missing or incorrect - fix not applied"
    test_status=1
fi

# Check that prepareRead no longer takes QualifiedIdentifier parameter
echo "Checking that Statements.prepareRead calls are updated..."
if grep -B 2 -A 2 "Statements.prepareRead" "src/PostgREST/Query.hs" | grep -v "wrIdent" | grep -q "Statements.prepareRead"; then
    echo "✓ Statements.prepareRead calls updated (no wrIdent parameter)"
else
    echo "✗ Statements.prepareRead still has wrIdent parameter - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
