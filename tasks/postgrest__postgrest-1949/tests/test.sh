#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/EmbedDisambiguationSpec.hs" "test/Feature/EmbedDisambiguationSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/EmbedInnerJoinSpec.hs" "test/Feature/EmbedInnerJoinSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test"
cp "/tests/SpecHelper.hs" "test/SpecHelper.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/data.sql" "test/fixtures/data.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/privileges.sql" "test/fixtures/privileges.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/aliases.config" "test/io-tests/configs/expected/aliases.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-numeric.config" "test/io-tests/configs/expected/boolean-numeric.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-string.config" "test/io-tests/configs/expected/boolean-string.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/defaults.config" "test/io-tests/configs/expected/defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db.config" "test/io-tests/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults.config" "test/io-tests/configs/expected/no-defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/types.config" "test/io-tests/configs/expected/types.config"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults-env.yaml" "test/io-tests/configs/no-defaults-env.yaml"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults.config" "test/io-tests/configs/no-defaults.config"
mkdir -p "test/io-tests"
cp "/tests/io-tests/fixtures.yaml" "test/io-tests/fixtures.yaml"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #1949 which adds support for inner joins on embedded resources
# HEAD state (41ef1cb8d925958715a53048b61842828e27d05b) = inner join feature present - FIXED
# BASE state (with bug.patch) = inner join feature removed - BUGGY
# ORACLE state (BASE + fix.patch) = inner join feature restored - FIXED

test_status=0

echo "Verifying source code matches HEAD state (inner join feature for embedded resources)..."
echo ""

echo "Checking that CHANGELOG mentions the inner join feature..."
if grep -q "#1075, Allow filtering top-level resource based on embedded resources filters" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions inner join feature - fix applied!"
else
    echo "✗ CHANGELOG missing inner join feature - fix not applied"
    test_status=1
fi

echo "Checking that CHANGELOG mentions !inner syntax..."
if grep -q "clients!inner" "CHANGELOG.md"; then
    echo "✓ CHANGELOG has !inner syntax example - fix applied!"
else
    echo "✗ CHANGELOG missing !inner syntax - fix not applied"
    test_status=1
fi

echo "Checking that CHANGELOG mentions db-embed-default-join config..."
if grep -q "db-embed-default-join='inner'" "CHANGELOG.md"; then
    echo "✓ CHANGELOG has db-embed-default-join config - fix applied!"
else
    echo "✗ CHANGELOG missing db-embed-default-join config - fix not applied"
    test_status=1
fi

echo "Checking that postgrest.cabal includes EmbedInnerJoinSpec..."
if grep -q "Feature.EmbedInnerJoinSpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has EmbedInnerJoinSpec - fix applied!"
else
    echo "✗ postgrest.cabal missing EmbedInnerJoinSpec - fix not applied"
    test_status=1
fi

echo "Checking that App.hs passes configDbEmbedDefaultJoin..."
if grep -q "ReqBuilder.readRequest qiSchema qiName configDbMaxRows configDbEmbedDefaultJoin" "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes configDbEmbedDefaultJoin parameter - fix applied!"
else
    echo "✗ App.hs missing configDbEmbedDefaultJoin parameter - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs imports JoinType..."
if grep -q "import PostgREST.Request.Types.*JoinType" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs imports JoinType - fix applied!"
else
    echo "✗ Config.hs missing JoinType import - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs has configDbEmbedDefaultJoin field..."
if grep -q "configDbEmbedDefaultJoin.*::.*JoinType" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configDbEmbedDefaultJoin field - fix applied!"
else
    echo "✗ Config.hs missing configDbEmbedDefaultJoin field - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs has parseEmbedDefaultJoin function..."
if grep -q "parseEmbedDefaultJoin" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has parseEmbedDefaultJoin function - fix applied!"
else
    echo "✗ Config.hs missing parseEmbedDefaultJoin function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
