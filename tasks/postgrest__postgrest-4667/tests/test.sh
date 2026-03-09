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
cp "/tests/io/configs/expected/jwt-role-claim-key1.config" "test/io/configs/expected/jwt-role-claim-key1.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key2.config" "test/io/configs/expected/jwt-role-claim-key2.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key3.config" "test/io/configs/expected/jwt-role-claim-key3.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key4.config" "test/io/configs/expected/jwt-role-claim-key4.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key5.config" "test/io/configs/expected/jwt-role-claim-key5.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/utf-8.config" "test/io/configs/expected/utf-8.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/db_config.sql" "test/io/fixtures/db_config.sql"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4667 which adds client-error-verbosity configuration
# HEAD state (3f001c88e0ee539015fd59853729e52fcb662830) = fix applied, has Verbosity type and configClientErrorVerbosity
# BASE state (with bug.patch) = old state without client-error-verbosity feature

test_status=0

echo "Verifying source code matches HEAD state (client-error-verbosity feature added)..."
echo ""

echo "Checking that src/PostgREST/Config.hs has Verbosity data type..."
if grep -q "data Verbosity" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has Verbosity data type - fix applied!"
else
    echo "✗ src/PostgREST/Config.hs does not have Verbosity data type - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Config.hs has configClientErrorVerbosity field..."
if grep -q "configClientErrorVerbosity" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configClientErrorVerbosity field - fix applied!"
else
    echo "✗ src/PostgREST/Config.hs does not have configClientErrorVerbosity field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs has errorResponseFor function taking Verbosity..."
if grep -q "Verbosity -> a -> Response" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has errorResponseFor with Verbosity parameter - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not have errorResponseFor with Verbosity parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/App.hs uses configClientErrorVerbosity..."
if grep -q "configClientErrorVerbosity" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs uses configClientErrorVerbosity - fix applied!"
else
    echo "✗ src/PostgREST/App.hs does not use configClientErrorVerbosity - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test config files include client-error-verbosity..."
if grep -q "client-error-verbosity" "test/io/configs/expected/defaults.config"; then
    echo "✓ test/io/configs/expected/defaults.config includes client-error-verbosity - fix applied!"
else
    echo "✗ test/io/configs/expected/defaults.config does not include client-error-verbosity - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SpecHelper.hs imports Verbosity type..."
if grep -q "Verbosity" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs imports Verbosity type - fix applied!"
else
    echo "✗ test/spec/SpecHelper.hs does not import Verbosity type - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
