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
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying db-pool-automatic-recovery configuration option was added..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for db-pool-automatic-recovery entry..."
if grep -q '#1614, Add `db-pool-automatic-recovery` configuration to disable connection retrying' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has db-pool-automatic-recovery entry"
else
    echo "✗ CHANGELOG.md missing db-pool-automatic-recovery entry - fix not applied"
    test_status=1
fi

# Check Config.hs has the new field
echo "Checking Config.hs for configDbPoolAutomaticRecovery field..."
if grep -q 'configDbPoolAutomaticRecovery  :: Bool' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configDbPoolAutomaticRecovery field"
else
    echo "✗ Config.hs missing configDbPoolAutomaticRecovery field - fix not applied"
    test_status=1
fi

# Check Config.hs has the parser for the option
echo "Checking Config.hs for db-pool-automatic-recovery parser..."
if grep -q 'optBool "db-pool-automatic-recovery"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has db-pool-automatic-recovery parser"
else
    echo "✗ Config.hs missing db-pool-automatic-recovery parser - fix not applied"
    test_status=1
fi

# Check Config.hs includes it in toText output
echo "Checking Config.hs for db-pool-automatic-recovery in output..."
if grep -q '"db-pool-automatic-recovery"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs includes db-pool-automatic-recovery in output"
else
    echo "✗ Config.hs missing db-pool-automatic-recovery in output - fix not applied"
    test_status=1
fi

# Check AppState.hs uses the config option
echo "Checking AppState.hs for configDbPoolAutomaticRecovery usage..."
if grep -q 'configDbPoolAutomaticRecovery' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses configDbPoolAutomaticRecovery"
else
    echo "✗ AppState.hs missing configDbPoolAutomaticRecovery usage - fix not applied"
    test_status=1
fi

# Check CLI.hs has the example config
echo "Checking CLI.hs for db-pool-automatic-recovery example..."
if grep -q 'db-pool-automatic-recovery' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has db-pool-automatic-recovery example"
else
    echo "✗ CLI.hs missing db-pool-automatic-recovery example - fix not applied"
    test_status=1
fi

# Check test config files have the option
echo "Checking test/io/configs/expected/aliases.config..."
if grep -q 'db-pool-automatic-recovery = true' "test/io/configs/expected/aliases.config"; then
    echo "✓ aliases.config has db-pool-automatic-recovery"
else
    echo "✗ aliases.config missing db-pool-automatic-recovery - fix not applied"
    test_status=1
fi

echo "Checking test/io/configs/expected/no-defaults.config..."
if grep -q 'db-pool-automatic-recovery = false' "test/io/configs/expected/no-defaults.config"; then
    echo "✓ no-defaults.config has db-pool-automatic-recovery = false"
else
    echo "✗ no-defaults.config missing db-pool-automatic-recovery - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs has the field
echo "Checking test/spec/SpecHelper.hs for configDbPoolAutomaticRecovery..."
if grep -q 'configDbPoolAutomaticRecovery = True' "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs has configDbPoolAutomaticRecovery = True"
else
    echo "✗ SpecHelper.hs missing configDbPoolAutomaticRecovery - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
