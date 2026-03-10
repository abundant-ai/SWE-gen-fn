#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for superuser settings with impersonated role..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2896, Fix applying superuser settings for impersonated role' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has the fix for filtering role settings
echo "Checking src/PostgREST/Config/Database.hs for pg_settings join..."
if grep -q "join pg_settings ps on ps.name = kv.key and ps.context = 'user'" "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs has pg_settings filter for user context"
else
    echo "✗ Config/Database.hs missing pg_settings join - fix not applied"
    test_status=1
fi

# Check test fixture has the role with superuser settings
echo "Checking test/io/fixtures.sql for postgrest_test_w_superuser_settings role..."
if grep -q "CREATE ROLE postgrest_test_w_superuser_settings" "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql has postgrest_test_w_superuser_settings role"
else
    echo "✗ fixtures.sql missing postgrest_test_w_superuser_settings role - fix not applied"
    test_status=1
fi

# Check test fixture sets superuser settings on the role
echo "Checking test/io/fixtures.sql for log_min_duration_statement setting..."
if grep -q "alter role postgrest_test_w_superuser_settings set log_min_duration_statement" "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql sets log_min_duration_statement for test role"
else
    echo "✗ fixtures.sql missing log_min_duration_statement setting - fix not applied"
    test_status=1
fi

# Check test file has the test case
echo "Checking test/io/test_io.py for test_succeed_w_role_having_superuser_settings..."
if grep -q "def test_succeed_w_role_having_superuser_settings" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_succeed_w_role_having_superuser_settings test"
else
    echo "✗ test_io.py missing test_succeed_w_role_having_superuser_settings - fix not applied"
    test_status=1
fi

# Verify the test checks the role can access projects
echo "Checking test/io/test_io.py uses postgrest_test_w_superuser_settings role..."
if grep -q 'postgrest_test_w_superuser_settings' "test/io/test_io.py"; then
    echo "✓ test_io.py references postgrest_test_w_superuser_settings role"
else
    echo "✗ test_io.py missing postgrest_test_w_superuser_settings reference - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
