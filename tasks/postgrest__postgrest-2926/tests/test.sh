#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ServerTimingSpec.hs" "test/spec/Feature/Query/ServerTimingSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpsertSpec.hs" "test/spec/Feature/Query/UpsertSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/RollbackSpec.hs" "test/spec/Feature/RollbackSpec.hs"

test_status=0

echo "Verifying upsert HTTP status code fix implementation..."
echo ""

# Check that CHANGELOG has the fix documented
echo "Checking CHANGELOG.md has upsert status code fix entry..."
if grep -q '#1070, Fix HTTP status responses for upserts' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has upsert fix entry"
else
    echo "✗ CHANGELOG.md missing upsert fix entry - fix not applied"
    test_status=1
fi

if grep -q 'PUT.*returns.*201.*instead of.*200.*when rows are inserted' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PUT status code description"
else
    echo "✗ CHANGELOG.md missing PUT status code description - fix not applied"
    test_status=1
fi

# Check that PreferResolution has deriving Eq
echo "Checking ApiRequest/Preferences.hs has deriving Eq for PreferResolution..."
if grep -A3 'data PreferResolution' "src/PostgREST/ApiRequest/Preferences.hs" | grep -q 'deriving Eq'; then
    echo "✓ PreferResolution has deriving Eq"
else
    echo "✗ PreferResolution missing deriving Eq - fix not applied"
    test_status=1
fi

# Check that Query.hs has isPut variable
echo "Checking Query.hs has isPut variable in writeQuery..."
if grep -q 'isPut.*isInsert.*pkCols.*=.*case mrMutatePlan' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has isPut variable"
else
    echo "✗ Query.hs missing isPut variable - fix not applied"
    test_status=1
fi

# Check that Query.hs passes isPut and preferResolution
echo "Checking Query.hs passes isPut and preferResolution to prepareWrite..."
if grep -q 'isPut' "src/PostgREST/Query.hs" && grep -q 'preferResolution' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs passes isPut and preferResolution"
else
    echo "✗ Query.hs not passing isPut or preferResolution - fix not applied"
    test_status=1
fi

# Check that SqlFragment.hs exports addConfigPgrstInserted
echo "Checking SqlFragment.hs exports addConfigPgrstInserted..."
if grep -q 'addConfigPgrstInserted' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports addConfigPgrstInserted"
else
    echo "✗ SqlFragment.hs missing addConfigPgrstInserted - fix not applied"
    test_status=1
fi

# Check that SqlFragment.hs has currentSettingF export
echo "Checking SqlFragment.hs exports currentSettingF..."
if grep -q 'currentSettingF' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports currentSettingF"
else
    echo "✗ SqlFragment.hs missing currentSettingF - fix not applied"
    test_status=1
fi

# Check that Statements.hs has rsInserted field
echo "Checking Statements.hs has rsInserted field in ResultSet..."
if grep -q 'rsInserted.*::.*Maybe Int64' "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs has rsInserted field"
else
    echo "✗ Statements.hs missing rsInserted field - fix not applied"
    test_status=1
fi

# Check that Statements.hs prepareWrite has isPut and resolution parameters
echo "Checking Statements.hs prepareWrite has isPut and resolution parameters..."
if grep -q 'prepareWrite.*::.*Bool.*->.*Bool.*->.*MediaType' "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs prepareWrite has additional Bool parameters"
else
    echo "✗ Statements.hs prepareWrite missing parameters - fix not applied"
    test_status=1
fi

# Check that Response.hs imports PreferResolution
echo "Checking Response.hs imports PreferResolution..."
if grep -q 'PreferResolution' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs imports PreferResolution"
else
    echo "✗ Response.hs missing PreferResolution import - fix not applied"
    test_status=1
fi

# Check that Response.hs has isInsertIfGTZero function in createResponse
echo "Checking Response.hs has status code logic based on rsInserted..."
if grep -q 'isInsertIfGTZero' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has isInsertIfGTZero logic"
else
    echo "✗ Response.hs missing isInsertIfGTZero logic - fix not applied"
    test_status=1
fi

# Check that Response.hs uses rsInserted for status determination
echo "Checking Response.hs uses rsInserted for status determination..."
if grep -q 'rsInserted' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses rsInserted"
else
    echo "✗ Response.hs not using rsInserted - fix not applied"
    test_status=1
fi

# Check that QueryBuilder.hs has addConfigPgrstInserted calls
echo "Checking QueryBuilder.hs uses addConfigPgrstInserted..."
if grep -q 'addConfigPgrstInserted' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses addConfigPgrstInserted"
else
    echo "✗ QueryBuilder.hs missing addConfigPgrstInserted calls - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
