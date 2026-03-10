#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PgSafeUpdateSpec.hs" "test/spec/Feature/Query/PgSafeUpdateSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for bulk update revert (PR #2424)..."
echo ""
echo "NOTE: This PR reverts the bulk update patch feature"
echo "BASE (buggy) has bulk update references in CHANGELOG and pkFilters in code"
echo "HEAD (fixed) removes bulk update references and simplifies update logic"
echo ""

# Check CHANGELOG - HEAD should NOT have bulk update references
echo "Checking CHANGELOG.md does not have bulk update references..."
if ! grep -q "Bulk update with PATCH" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md does not have 'Bulk update with PATCH' line"
else
    echo "✗ CHANGELOG.md still has 'Bulk update with PATCH' - fix not applied"
    test_status=1
fi

if ! grep -q "accidental full table PATCH(without filters) is not possible anymore" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md does not have 'accidental full table PATCH' line"
else
    echo "✗ CHANGELOG.md still has 'accidental full table PATCH' reference - fix not applied"
    test_status=1
fi

if ! grep -q "A full table PATCH(without filters) is now restricted" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md does not have 'full table PATCH is now restricted' line"
else
    echo "✗ CHANGELOG.md still has 'full table PATCH is now restricted' reference - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should have simplified handleUpdate function
echo "Checking src/PostgREST/App.hs handleUpdate function..."
if grep -A2 "^handleUpdate :: QualifiedIdentifier -> RequestContext -> DbHandler Wai.Response" "src/PostgREST/App.hs" | grep -q "handleUpdate identifier context@(RequestContext _ _ ApiRequest{..} _) = do"; then
    echo "✓ App.hs handleUpdate uses pattern matching in function signature"
else
    echo "✗ App.hs handleUpdate does not use pattern matching - fix not applied"
    test_status=1
fi

if grep -A4 "^handleUpdate :: QualifiedIdentifier -> RequestContext -> DbHandler Wai.Response" "src/PostgREST/App.hs" | grep -q "writeQuery MutationUpdate identifier False mempty context"; then
    echo "✓ App.hs handleUpdate passes mempty instead of pkCols to writeQuery"
else
    echo "✗ App.hs handleUpdate does not pass mempty to writeQuery - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should not have pkFlts parameter
echo "Checking src/PostgREST/Query/QueryBuilder.hs does not use pkFlts..."
if ! grep -q "mutateRequestToQuery (Update mainQi uCols body logicForest pkFlts range" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs Update pattern does not have pkFlts parameter"
else
    echo "✗ QueryBuilder.hs Update pattern still has pkFlts parameter - fix not applied"
    test_status=1
fi

# Check that the allRange branch uses _ instead of pgrst_update_body for the table alias
if grep -A3 "range == allRange" "src/PostgREST/Query/QueryBuilder.hs" | grep -q ")) _ "; then
    echo "✓ QueryBuilder.hs allRange branch uses _ instead of pgrst_update_body"
else
    echo "✗ QueryBuilder.hs allRange branch does not use _ table alias - fix not applied"
    test_status=1
fi

# Check MutateQuery.hs - HEAD should not have pkFilters field
echo "Checking src/PostgREST/Request/MutateQuery.hs Update does not have pkFilters field..."
if ! grep -q ", pkFilters" "src/PostgREST/Request/MutateQuery.hs"; then
    echo "✓ MutateQuery.hs Update record does not have pkFilters field"
else
    echo "✗ MutateQuery.hs Update record still has pkFilters field - fix not applied"
    test_status=1
fi

# Check DbRequestBuilder.hs - HEAD should not pass pkCols to Update constructor
echo "Checking src/PostgREST/Request/DbRequestBuilder.hs does not pass pkCols to Update..."
if grep -q "Right \$ Update qi iColumns body combinedLogic iTopLevelRange rootOrder returnings" "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs Update constructor does not include pkCols"
else
    echo "✗ DbRequestBuilder.hs Update constructor still includes pkCols - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - bulk update feature reverted successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
