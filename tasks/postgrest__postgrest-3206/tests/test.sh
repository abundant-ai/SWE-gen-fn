#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3205, Fix wrong subquery error returning a status of 400 Bad Request" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that Error.hs contains the cardinality_violation (21000) error handling
echo "Checking that Error.hs contains cardinality_violation error handling..."
if grep -q '"21000"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs contains cardinality_violation error code check"
else
    echo "✗ Error.hs missing cardinality_violation error code - fix not applied"
    test_status=1
fi

# Check that Error.hs has the pg-safeupdate check
echo "Checking that Error.hs has the pg-safeupdate special case handling..."
if grep -q 'BS.isSuffixOf "requires a WHERE clause" m' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs contains pg-safeupdate special case handling"
else
    echo "✗ Error.hs missing pg-safeupdate check - fix not applied"
    test_status=1
fi

# Check that Error.hs returns HTTP 400 for pg-safeupdate
echo "Checking that Error.hs returns HTTP 400 for pg-safeupdate..."
if grep -A 3 '"21000"' "src/PostgREST/Error.hs" | grep -q "HTTP.status400"; then
    echo "✓ Error.hs returns HTTP 400 for pg-safeupdate"
else
    echo "✗ Error.hs not returning HTTP 400 for pg-safeupdate - fix not applied"
    test_status=1
fi

# Check that Error.hs returns HTTP 500 for other cardinality violations
echo "Checking that Error.hs returns HTTP 500 for other cardinality violations..."
if grep -A 4 '"21000"' "src/PostgREST/Error.hs" | grep -q "HTTP.status500"; then
    echo "✓ Error.hs returns HTTP 500 for other cardinality violations"
else
    echo "✗ Error.hs not returning HTTP 500 for generic cardinality violations - fix not applied"
    test_status=1
fi

# Check that ErrorSpec.hs exports nonExistentSchema function (not spec)
echo "Checking that ErrorSpec.hs exports nonExistentSchema..."
if grep -q "nonExistentSchema :: SpecWith" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs exports nonExistentSchema"
else
    echo "✗ ErrorSpec.hs missing nonExistentSchema - fix not applied"
    test_status=1
fi

# Check that ErrorSpec.hs has pgErrorCodeMapping function
echo "Checking that ErrorSpec.hs has pgErrorCodeMapping function..."
if grep -q "pgErrorCodeMapping :: SpecWith" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs has pgErrorCodeMapping function"
else
    echo "✗ ErrorSpec.hs missing pgErrorCodeMapping - fix not applied"
    test_status=1
fi

# Check that ErrorSpec.hs tests cardinality_violation returns 500
echo "Checking that ErrorSpec.hs tests cardinality_violation error..."
if grep -q 'should return 500 for cardinality_violation' "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs tests cardinality_violation error"
else
    echo "✗ ErrorSpec.hs missing test for cardinality_violation - fix not applied"
    test_status=1
fi

# Check that ErrorSpec.hs tests /bad_subquery endpoint
echo "Checking that ErrorSpec.hs tests /bad_subquery endpoint..."
if grep -q 'get "/bad_subquery"' "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs tests /bad_subquery endpoint"
else
    echo "✗ ErrorSpec.hs missing /bad_subquery test - fix not applied"
    test_status=1
fi

# Check that Main.hs includes pgErrorCodeMapping in test suite
echo "Checking that Main.hs includes pgErrorCodeMapping in test suite..."
if grep -q 'Feature.Query.PgErrorCodeMappingSpec' "test/spec/Main.hs" || grep -q 'Feature.Query.ErrorSpec.pgErrorCodeMapping' "test/spec/Main.hs"; then
    echo "✓ Main.hs includes pgErrorCodeMapping in test suite"
else
    echo "✗ Main.hs missing pgErrorCodeMapping in test suite - fix not applied"
    test_status=1
fi

# Check that Main.hs calls nonExistentSchema (not spec)
echo "Checking that Main.hs references nonExistentSchema..."
if grep -q 'Feature.Query.ErrorSpec.nonExistentSchema' "test/spec/Main.hs"; then
    echo "✓ Main.hs references nonExistentSchema"
else
    echo "✗ Main.hs not referencing nonExistentSchema correctly - fix not applied"
    test_status=1
fi

# Check that schema.sql includes bad_subquery view
echo "Checking that schema.sql includes bad_subquery view..."
if grep -q 'create view bad_subquery' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes bad_subquery view"
else
    echo "✗ schema.sql missing bad_subquery view - fix not applied"
    test_status=1
fi

# Check that bad_subquery view has the problematic subquery
echo "Checking that bad_subquery view contains the problematic subquery..."
if grep -A 1 'create view bad_subquery' "test/spec/fixtures/schema.sql" | grep -q 'select \* from projects where id = (select id from projects)'; then
    echo "✓ bad_subquery view contains the problematic subquery"
else
    echo "✗ bad_subquery view definition incorrect - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
