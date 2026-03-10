#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check CHANGELOG for the feature mention
echo "Checking CHANGELOG for #3045 entry..."
if grep -q '#3045.*Apply superuser settings on impersonated roles if they have PostgreSQL 15' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions #3045 feature"
else
    echo "✗ CHANGELOG missing #3045 entry - fix not applied"
    test_status=1
fi

# Check AppState.hs for pgVer variable
echo "Checking AppState.hs for pgVer usage..."
if grep -q 'pgVer <- getPgVersion appState' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs gets pgVer"
else
    echo "✗ AppState.hs missing pgVer - fix not applied"
    test_status=1
fi

# Check AppState.hs passes pgVer to queryRoleSettings
echo "Checking AppState.hs passes pgVer to queryRoleSettings..."
if grep -q 'queryRoleSettings pgVer configDbPreparedStatements' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs passes pgVer to queryRoleSettings"
else
    echo "✗ AppState.hs not passing pgVer - fix not applied"
    test_status=1
fi

# Check Config/Database.hs imports pgVersion150
echo "Checking Config/Database.hs for pgVersion150 import..."
if grep -q 'import PostgREST.Config.PgVersion (PgVersion (..), pgVersion150)' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs imports pgVersion150"
else
    echo "✗ Config/Database.hs missing pgVersion150 import - fix not applied"
    test_status=1
fi

# Check Config/Database.hs queryRoleSettings signature includes PgVersion
echo "Checking Config/Database.hs queryRoleSettings signature..."
if grep -q 'queryRoleSettings :: PgVersion -> Bool' "src/PostgREST/Config/Database.hs"; then
    echo "✓ queryRoleSettings has PgVersion parameter"
else
    echo "✗ queryRoleSettings missing PgVersion parameter - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has version check for PostgreSQL 15
echo "Checking Config/Database.hs for PostgreSQL 15 version check..."
if grep -q 'if pgVer >= pgVersion150' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs has pgVersion150 check"
else
    echo "✗ Config/Database.hs missing pgVersion150 check - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has has_parameter_privilege check
echo "Checking Config/Database.hs for has_parameter_privilege..."
if grep -q 'has_parameter_privilege(current_user::regrole::oid, ps.name' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs uses has_parameter_privilege"
else
    echo "✗ Config/Database.hs missing has_parameter_privilege - fix not applied"
    test_status=1
fi

# Check Config/PgVersion.hs exports pgVersion150
echo "Checking Config/PgVersion.hs exports pgVersion150..."
if grep -q ', pgVersion150' "src/PostgREST/Config/PgVersion.hs"; then
    echo "✓ Config/PgVersion.hs exports pgVersion150"
else
    echo "✗ Config/PgVersion.hs not exporting pgVersion150 - fix not applied"
    test_status=1
fi

# Check Config/PgVersion.hs defines pgVersion150
echo "Checking Config/PgVersion.hs for pgVersion150 definition..."
if grep -q 'pgVersion150 = PgVersion 150000' "src/PostgREST/Config/PgVersion.hs"; then
    echo "✓ Config/PgVersion.hs defines pgVersion150"
else
    echo "✗ Config/PgVersion.hs missing pgVersion150 definition - fix not applied"
    test_status=1
fi

# Check Query.hs for comment about GRANT SET
echo "Checking Query.hs for GRANT SET comment..."
if grep -q 'GRANT SET ON PARAMETER' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has GRANT SET comment"
else
    echo "✗ Query.hs missing GRANT SET comment - fix not applied"
    test_status=1
fi

# Check Query.hs has roleSettingsSql before roleSql
echo "Checking Query.hs for correct ordering (roleSettingsSql before roleSql)..."
if grep -q 'searchPathSql : roleSettingsSql ++ roleSql' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has roleSettingsSql before roleSql"
else
    echo "✗ Query.hs incorrect ordering - fix not applied"
    test_status=1
fi

# Check fixtures.sql has the DO block for PostgreSQL 15
echo "Checking fixtures.sql for PostgreSQL 15 DO block..."
if grep -q 'GRANT SET ON PARAMETER log_min_duration_sample to postgrest_test_authenticator' "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql has GRANT SET statement"
else
    echo "✗ fixtures.sql missing GRANT SET - fix not applied"
    test_status=1
fi

# Check fixtures.sql has get_postgres_version function
echo "Checking fixtures.sql for get_postgres_version function..."
if grep -q 'create function get_postgres_version()' "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql has get_postgres_version function"
else
    echo "✗ fixtures.sql missing get_postgres_version - fix not applied"
    test_status=1
fi

# Check test_io.py has test_get_granted_superuser_setting test
echo "Checking test_io.py for test_get_granted_superuser_setting..."
if grep -q 'def test_get_granted_superuser_setting' "test/io/test_io.py"; then
    echo "✓ test_io.py has test_get_granted_superuser_setting"
else
    echo "✗ test_io.py missing test_get_granted_superuser_setting - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
