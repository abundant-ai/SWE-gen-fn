#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for prepared statements bug (#2742)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has prepared statements fix entry..."
if grep -q "#2742" "CHANGELOG.md" && grep -q "Fix db settings and pg version queries not getting prepared" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has prepared statements fix entry"
else
    echo "✗ CHANGELOG.md missing prepared statements fix entry - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has prepared parameter in pgVersionStatement
echo "Checking src/PostgREST/Config/Database.hs has prepared parameter in pgVersionStatement..."
if grep -q "pgVersionStatement :: Bool -> SQL.Statement () PgVersion" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has prepared parameter in pgVersionStatement"
else
    echo "✗ src/PostgREST/Config/Database.hs missing prepared parameter in pgVersionStatement - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has prepared parameter in dbSettingsStatement
echo "Checking src/PostgREST/Config/Database.hs has prepared parameter in dbSettingsStatement..."
if grep -q "dbSettingsStatement :: Bool -> SQL.Statement () \[(Text, Text)\]" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has prepared parameter in dbSettingsStatement"
else
    echo "✗ src/PostgREST/Config/Database.hs missing prepared parameter in dbSettingsStatement - fix not applied"
    test_status=1
fi

# Check Config/Database.hs queryPgVersion takes prepared parameter
echo "Checking src/PostgREST/Config/Database.hs queryPgVersion takes prepared parameter..."
if grep -q "queryPgVersion :: Bool -> Session PgVersion" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs queryPgVersion takes prepared parameter"
else
    echo "✗ src/PostgREST/Config/Database.hs queryPgVersion missing prepared parameter - fix not applied"
    test_status=1
fi

# Check Config/Database.hs queryPgVersion calls pgVersionStatement with prepared
echo "Checking src/PostgREST/Config/Database.hs queryPgVersion passes prepared parameter..."
if grep -q "queryPgVersion prepared = statement mempty \$ pgVersionStatement prepared" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs queryPgVersion passes prepared parameter"
else
    echo "✗ src/PostgREST/Config/Database.hs queryPgVersion not passing prepared parameter - fix not applied"
    test_status=1
fi

# Check Config/Database.hs dbSettingsStatement is called with prepared
echo "Checking src/PostgREST/Config/Database.hs queryDbSettings passes prepared parameter..."
if grep -q "transaction SQL.ReadCommitted SQL.Read \$ SQL.statement mempty \$ dbSettingsStatement prepared" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs queryDbSettings passes prepared parameter"
else
    echo "✗ src/PostgREST/Config/Database.hs queryDbSettings not passing prepared parameter - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs calls pgVersionStatement with prepared
echo "Checking src/PostgREST/SchemaCache.hs passes prepared parameter to pgVersionStatement..."
if grep -q "pgVer.*SQL.statement mempty \$ pgVersionStatement prepared" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs passes prepared parameter to pgVersionStatement"
else
    echo "✗ src/PostgREST/SchemaCache.hs not passing prepared parameter to pgVersionStatement - fix not applied"
    test_status=1
fi

# Check Workers.hs calls queryPgVersion with False for initial connection
echo "Checking src/PostgREST/Workers.hs calls queryPgVersion with False..."
if grep -q "queryPgVersion False" "src/PostgREST/Workers.hs"; then
    echo "✓ src/PostgREST/Workers.hs calls queryPgVersion with False"
else
    echo "✗ src/PostgREST/Workers.hs not calling queryPgVersion with False - fix not applied"
    test_status=1
fi

# Check Config.hs has RoleSettings import
echo "Checking src/PostgREST/Config.hs imports RoleSettings..."
if grep -q "import PostgREST.Config.Database.*RoleSettings" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs imports RoleSettings"
else
    echo "✗ src/PostgREST/Config.hs missing RoleSettings import - fix not applied"
    test_status=1
fi

# Check Config.hs has configRoleSettings field
echo "Checking src/PostgREST/Config.hs has configRoleSettings field..."
if grep -q "configRoleSettings.*RoleSettings" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configRoleSettings field"
else
    echo "✗ src/PostgREST/Config.hs missing configRoleSettings field - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has RoleSettings type definition
echo "Checking src/PostgREST/Config/Database.hs has RoleSettings type..."
if grep -q "type RoleSettings = (HM.HashMap ByteString \[(ByteString, ByteString)\])" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has RoleSettings type"
else
    echo "✗ src/PostgREST/Config/Database.hs missing RoleSettings type - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has queryRoleSettings function
echo "Checking src/PostgREST/Config/Database.hs has queryRoleSettings function..."
if grep -q "queryRoleSettings :: Bool -> Session RoleSettings" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has queryRoleSettings function"
else
    echo "✗ src/PostgREST/Config/Database.hs missing queryRoleSettings function - fix not applied"
    test_status=1
fi

# Check Workers.hs imports queryRoleSettings
echo "Checking src/PostgREST/Workers.hs imports queryRoleSettings..."
if grep -q "queryRoleSettings" "src/PostgREST/Workers.hs"; then
    echo "✓ src/PostgREST/Workers.hs imports queryRoleSettings"
else
    echo "✗ src/PostgREST/Workers.hs missing queryRoleSettings import - fix not applied"
    test_status=1
fi

# Check Workers.hs calls queryRoleSettings in reReadConfig
echo "Checking src/PostgREST/Workers.hs calls queryRoleSettings..."
if grep -q "queryRoleSettings configDbPreparedStatements" "src/PostgREST/Workers.hs"; then
    echo "✓ src/PostgREST/Workers.hs calls queryRoleSettings"
else
    echo "✗ src/PostgREST/Workers.hs not calling queryRoleSettings - fix not applied"
    test_status=1
fi

# Check test fixtures have role settings tests
echo "Checking test/io/fixtures.sql has role settings..."
if grep -q "alter role postgrest_test_anonymous set statement_timeout" "test/io/fixtures.sql" && \
   grep -q "alter role postgrest_test_author set statement_timeout" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has role settings"
else
    echo "✗ test/io/fixtures.sql missing role settings - fix not applied"
    test_status=1
fi

# Check test/io/test_io.py has test_role_settings test
echo "Checking test/io/test_io.py has test_role_settings test..."
if grep -q "def test_role_settings" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has test_role_settings test"
else
    echo "✗ test/io/test_io.py missing test_role_settings test - fix not applied"
    test_status=1
fi

# Check test/spec/Main.hs calls queryPgVersion with False
echo "Checking test/spec/Main.hs calls queryPgVersion with False..."
if grep -q "queryPgVersion False" "test/spec/Main.hs"; then
    echo "✓ test/spec/Main.hs calls queryPgVersion with False"
else
    echo "✗ test/spec/Main.hs not calling queryPgVersion with False - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs has configRoleSettings field
echo "Checking test/spec/SpecHelper.hs has configRoleSettings field..."
if grep -q "configRoleSettings.*mempty" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs has configRoleSettings field"
else
    echo "✗ test/spec/SpecHelper.hs missing configRoleSettings field - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
