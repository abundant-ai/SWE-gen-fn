#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for limited UPDATE/DELETE with limit/offset (PR #2195)..."
echo ""
echo "This PR adds support for limit/offset on UPDATE/DELETE operations."
echo ""

echo "Checking CHANGELOG.md has limit/offset feature documented..."
if [ -f "CHANGELOG.md" ] && grep -q 'Allow applying.*limit/offset.*to UPDATE/DELETE' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md documents limit/offset feature (fix applied)"
else
    echo "✗ CHANGELOG.md does not document limit/offset feature (not fixed)"
    test_status=1
fi

echo "Checking App.hs imports findIfView and findTable..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'findIfView, findTable' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports findIfView and findTable (fix applied)"
else
    echo "✗ App.hs does not import findIfView and findTable (not fixed)"
    test_status=1
fi

echo "Checking App.hs handleUpdate checks for views with limit/offset..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'findIfView identifier.*dbTables' "src/PostgREST/App.hs" && grep -A 2 'handleUpdate' "src/PostgREST/App.hs" | grep -q 'NotImplemented'; then
    echo "✓ App.hs handleUpdate checks for views (fix applied)"
else
    echo "✗ App.hs handleUpdate does not check for views (not fixed)"
    test_status=1
fi

echo "Checking App.hs handleDelete checks for views with limit/offset..."
if [ -f "src/PostgREST/App.hs" ] && grep -A 2 'handleDelete' "src/PostgREST/App.hs" | grep -q 'findIfView'; then
    echo "✓ App.hs handleDelete checks for views (fix applied)"
else
    echo "✗ App.hs handleDelete does not check for views (not fixed)"
    test_status=1
fi

echo "Checking DbStructure.hs exports findIfView and findTable..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q 'findIfView' "src/PostgREST/DbStructure.hs" && grep -q 'findTable' "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs exports findIfView and findTable (fix applied)"
else
    echo "✗ DbStructure.hs does not export findIfView and findTable (not fixed)"
    test_status=1
fi

echo "Checking DbStructure/Table.hs defines tableIsView field..."
if [ -f "src/PostgREST/DbStructure/Table.hs" ] && grep -q 'tableIsView.*Bool' "src/PostgREST/DbStructure/Table.hs"; then
    echo "✓ Table.hs defines tableIsView field (fix applied)"
else
    echo "✗ Table.hs does not define tableIsView field (not fixed)"
    test_status=1
fi

echo "Checking Error.hs defines NotImplemented error..."
if [ -f "src/PostgREST/Error.hs" ] && grep -q 'NotImplemented Text' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines NotImplemented error (fix applied)"
else
    echo "✗ Error.hs does not define NotImplemented error (not fixed)"
    test_status=1
fi

echo "Checking Error.hs defines GeneralErrorCode07..."
if [ -f "src/PostgREST/Error.hs" ] && grep -q 'GeneralErrorCode07' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines GeneralErrorCode07 (fix applied)"
else
    echo "✗ Error.hs does not define GeneralErrorCode07 (not fixed)"
    test_status=1
fi

echo "Checking QueryBuilder.hs Update mutation includes range parameter..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ] && grep -q 'Update.*range.*rangeId' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs Update handles range (fix applied)"
else
    echo "✗ QueryBuilder.hs Update does not handle range (not fixed)"
    test_status=1
fi

echo "Checking QueryBuilder.hs Delete mutation includes range parameter..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ] && grep -q 'Delete.*range.*rangeId' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs Delete handles range (fix applied)"
else
    echo "✗ QueryBuilder.hs Delete does not handle range (not fixed)"
    test_status=1
fi

echo "Checking SqlFragment.hs exports mutRangeF function..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ] && grep -q 'mutRangeF' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports mutRangeF (fix applied)"
else
    echo "✗ SqlFragment.hs does not export mutRangeF (not fixed)"
    test_status=1
fi

echo "Checking Request/Types.hs Update has mutRange field..."
if [ -f "src/PostgREST/Request/Types.hs" ] && grep -A 20 'data MutateQuery' "src/PostgREST/Request/Types.hs" | grep -q 'mutRange'; then
    echo "✓ Types.hs Update/Delete has mutRange field (fix applied)"
else
    echo "✗ Types.hs Update/Delete does not have mutRange field (not fixed)"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs passes mutRange to Update mutation..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q 'MutationUpdate.*iTopLevelRange.*pkCols' "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs passes mutRange to Update (fix applied)"
else
    echo "✗ DbRequestBuilder.hs does not pass mutRange to Update (not fixed)"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs passes mutRange to Delete mutation..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q 'MutationDelete.*iTopLevelRange.*pkCols' "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs passes mutRange to Delete (fix applied)"
else
    echo "✗ DbRequestBuilder.hs does not pass mutRange to Delete (not fixed)"
    test_status=1
fi

echo "Checking DbRequestBuilder.hs treeRestrictRange ignores mutations..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ] && grep -q 'treeRestrictRange.*Action' "src/PostgREST/Request/DbRequestBuilder.hs" && grep -q 'ActionMutate.*Right request' "src/PostgREST/Request/DbRequestBuilder.hs"; then
    echo "✓ DbRequestBuilder.hs treeRestrictRange ignores mutations (fix applied)"
else
    echo "✗ DbRequestBuilder.hs treeRestrictRange does not ignore mutations (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test files exist..."
for file in "test/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/QueryLimitedSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs" "test/spec/fixtures/data.sql" "test/spec/fixtures/privileges.sql" "test/spec/fixtures/schema.sql"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists (HEAD version)"
    else
        echo "✗ $file not found - HEAD file not copied!"
        test_status=1
    fi
done

echo "Checking UpdateSpec.hs has limited update tests..."
if [ -f "test/spec/Feature/Query/UpdateSpec.hs" ] && grep -q 'limited update' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs contains limited update tests (HEAD version)"
else
    echo "✗ UpdateSpec.hs does not contain limited update tests - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking DeleteSpec.hs has limited delete tests..."
if [ -f "test/spec/Feature/Query/DeleteSpec.hs" ] && grep -q 'limited delete' "test/spec/Feature/Query/DeleteSpec.hs"; then
    echo "✓ DeleteSpec.hs contains limited delete tests (HEAD version)"
else
    echo "✗ DeleteSpec.hs does not contain limited delete tests - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking QueryLimitedSpec.hs has max-rows mutation tests..."
if [ -f "test/spec/Feature/Query/QueryLimitedSpec.hs" ] && grep -q 'max-rows.*mutations' "test/spec/Feature/Query/QueryLimitedSpec.hs"; then
    echo "✓ QueryLimitedSpec.hs contains max-rows mutation tests (HEAD version)"
else
    echo "✗ QueryLimitedSpec.hs does not contain max-rows mutation tests - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking schema.sql has limited_update_items tables..."
if [ -f "test/spec/fixtures/schema.sql" ] && grep -q 'limited_update_items' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql contains limited_update_items tables (HEAD version)"
else
    echo "✗ schema.sql does not contain limited_update_items tables - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking data.sql has limited_update_items data..."
if [ -f "test/spec/fixtures/data.sql" ] && grep -q 'limited_update_items' "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql contains limited_update_items data (HEAD version)"
else
    echo "✗ data.sql does not contain limited_update_items data - HEAD file not properly copied!"
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
