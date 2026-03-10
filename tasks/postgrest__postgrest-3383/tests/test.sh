#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/roles.sql" "test/spec/fixtures/roles.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md has the entry for #3267
echo "Checking that CHANGELOG.md has the entry for #3267..."
if grep -q "#3267, Fix wrong \`503 Service Unavailable\` on pg error \`53400\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3267"
else
    echo "✗ CHANGELOG.md missing entry for #3267 - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs has the "53400" -> HTTP.status500 mapping
echo "Checking that src/PostgREST/Error.hs has the 53400 error handling..."
if grep -q '"53400".*->.*HTTP.status500.*-- config limit exceeded' "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has 53400 -> HTTP.status500 mapping"
else
    echo "✗ src/PostgREST/Error.hs missing 53400 error handling - fix not applied"
    test_status=1
fi

# Check that test/spec/Feature/Query/RpcSpec.hs has the temp_file_limit test
echo "Checking that test/spec/Feature/Query/RpcSpec.hs has the temp_file_limit test..."
if grep -q "test function temp_file_limit" "test/spec/Feature/Query/RpcSpec.hs" && \
   grep -q "should return http status 500" "test/spec/Feature/Query/RpcSpec.hs" && \
   grep -q "53400" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs has temp_file_limit test"
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs missing temp_file_limit test - fix not applied"
    test_status=1
fi

# Check that test/spec/fixtures/roles.sql has postgrest_test_superuser role
echo "Checking that test/spec/fixtures/roles.sql has postgrest_test_superuser role..."
if grep -q "CREATE ROLE postgrest_test_superuser WITH SUPERUSER" "test/spec/fixtures/roles.sql" && \
   grep -q "postgrest_test_superuser" "test/spec/fixtures/roles.sql"; then
    echo "✓ test/spec/fixtures/roles.sql has postgrest_test_superuser role"
else
    echo "✗ test/spec/fixtures/roles.sql missing postgrest_test_superuser role - fix not applied"
    test_status=1
fi

# Check that test/spec/fixtures/schema.sql has temp_file_limit function
echo "Checking that test/spec/fixtures/schema.sql has temp_file_limit function..."
if grep -q "create or replace function temp_file_limit()" "test/spec/fixtures/schema.sql" && \
   grep -q "temp_file_limit to '1kB'" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql has temp_file_limit function"
else
    echo "✗ test/spec/fixtures/schema.sql missing temp_file_limit function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
