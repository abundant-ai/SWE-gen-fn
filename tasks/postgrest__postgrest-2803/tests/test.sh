#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-numeric.config" "test/io/configs/expected/boolean-numeric.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-string.config" "test/io/configs/expected/boolean-string.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/defaults.config" "test/io/configs/expected/defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for db-pre-config feature (#2803)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has db-pre-config entry..."
if grep -q "#2703, Add pre-config function" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has #2703 entry"
else
    echo "✗ CHANGELOG.md missing #2703 entry - fix not applied"
    test_status=1
fi

if grep -q 'New config option `db-pre-config`' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions db-pre-config option"
else
    echo "✗ CHANGELOG.md missing db-pre-config description - fix not applied"
    test_status=1
fi

# Check CLI.hs has the db-pre-config example
echo "Checking src/PostgREST/CLI.hs has db-pre-config example..."
if grep -q '## db-pre-config = "postgrest.pre_config"' "src/PostgREST/CLI.hs"; then
    echo "✓ src/PostgREST/CLI.hs has db-pre-config example"
else
    echo "✗ src/PostgREST/CLI.hs missing db-pre-config example - fix not applied"
    test_status=1
fi

# Check Config.hs has configDbPreConfig field
echo "Checking src/PostgREST/Config.hs has configDbPreConfig field..."
if grep -q "configDbPreConfig" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configDbPreConfig field"
else
    echo "✗ src/PostgREST/Config.hs missing configDbPreConfig field - fix not applied"
    test_status=1
fi

# Check Config.hs has db-pre-config in toText function
echo "Checking src/PostgREST/Config.hs toText has db-pre-config..."
if grep -q '"db-pre-config"' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs toText includes db-pre-config"
else
    echo "✗ src/PostgREST/Config.hs toText missing db-pre-config - fix not applied"
    test_status=1
fi

# Check Config.hs has db-pre-config parser
echo "Checking src/PostgREST/Config.hs has db-pre-config parser..."
if grep -q 'optString "db-pre-config"' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has db-pre-config parser"
else
    echo "✗ src/PostgREST/Config.hs missing db-pre-config parser - fix not applied"
    test_status=1
fi

# Check Config.hs removed the reloadableDbSetting logic (should use dbConf directly)
echo "Checking src/PostgREST/Config.hs uses dbConf pattern..."
if grep -q "case dbConf <|> M.lookup envVarName env of" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs uses dbConf pattern"
else
    echo "✗ src/PostgREST/Config.hs missing dbConf pattern - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has prefix and qc import
echo "Checking src/PostgREST/Config/Database.hs has prefix..."
if grep -q '^prefix :: Text' "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has prefix"
else
    echo "✗ src/PostgREST/Config/Database.hs missing prefix - fix not applied"
    test_status=1
fi

if grep -q 'prefix = "pgrst."' "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs prefix is correct"
else
    echo "✗ src/PostgREST/Config/Database.hs prefix value incorrect - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Config/Database.hs imports qc..."
if grep -q "import Text.InterpolatedString.Perl6 (q, qc)" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs imports qc"
else
    echo "✗ src/PostgREST/Config/Database.hs missing qc import - fix not applied"
    test_status=1
fi

# Check that test files are present (these were copied from /tests)
echo "Checking test files are present..."
if [ -f "test/io/configs/expected/no-defaults-with-db-other-authenticator.config" ]; then
    echo "✓ test/io/configs/expected/no-defaults-with-db-other-authenticator.config is present"
else
    echo "✗ test/io/configs/expected/no-defaults-with-db-other-authenticator.config missing"
    test_status=1
fi

if [ -f "test/spec/SpecHelper.hs" ]; then
    echo "✓ test/spec/SpecHelper.hs is present"
else
    echo "✗ test/spec/SpecHelper.hs missing"
    test_status=1
fi

# Verify the expected config file contains db-pre-config
echo "Checking test config file contains db-pre-config..."
if grep -q 'db-pre-config = "postgrest.pre_config"' "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"; then
    echo "✓ Expected config file has db-pre-config setting"
else
    echo "✗ Expected config file missing db-pre-config - test data incorrect"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
