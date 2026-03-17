#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/EmbedInnerJoinSpec.hs" "test/Feature/EmbedInnerJoinSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test"
cp "/tests/SpecHelper.hs" "test/SpecHelper.hs"
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
cp "/tests/io-tests/configs/no-defaults.config" "test/io-tests/configs/no-defaults.config"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

test_status=0

echo "Verifying fix for removing db-embed-default-join configuration option (PR #2034)..."
echo ""
echo "This PR removes the 'db-embed-default-join' configuration option from PostgREST."
echo "The bug was that this configuration option was still present and functional."
echo "The fix removes it from the config parser, documentation, and all references in the codebase."
echo ""

echo "Checking CHANGELOG.md doesn't mention db-embed-default-join config..."
if [ -f "CHANGELOG.md" ]; then
    echo "✓ CHANGELOG.md exists"

    # After fix: should NOT have the db-embed-default-join config option documentation
    if grep -q "db-embed-default-join='inner'" "CHANGELOG.md"; then
        echo "✗ CHANGELOG.md still mentions db-embed-default-join config option (fix not applied)"
        test_status=1
    else
        echo "✓ CHANGELOG.md doesn't mention db-embed-default-join config option (fix applied)"
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/CLI.hs doesn't have db-embed-default-join in example config..."
if [ -f "src/PostgREST/CLI.hs" ]; then
    echo "✓ src/PostgREST/CLI.hs exists"

    # After fix: should NOT have db-embed-default-join in example config
    if grep -q "db-embed-default-join" "src/PostgREST/CLI.hs"; then
        echo "✗ src/PostgREST/CLI.hs still has db-embed-default-join in example config (fix not applied)"
        test_status=1
    else
        echo "✓ src/PostgREST/CLI.hs doesn't have db-embed-default-join (fix applied)"
    fi
else
    echo "✗ src/PostgREST/CLI.hs not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Config.hs doesn't have configDbEmbedDefaultJoin..."
if [ -f "src/PostgREST/Config.hs" ]; then
    echo "✓ src/PostgREST/Config.hs exists"

    # After fix: should NOT have configDbEmbedDefaultJoin field in AppConfig
    if grep -q "configDbEmbedDefaultJoin" "src/PostgREST/Config.hs"; then
        echo "✗ src/PostgREST/Config.hs still has configDbEmbedDefaultJoin (fix not applied)"
        test_status=1
    else
        echo "✓ src/PostgREST/Config.hs doesn't have configDbEmbedDefaultJoin (fix applied)"
    fi

    # After fix: should NOT import JoinType from Request.Types
    if grep -q "import PostgREST.Request.Types.*JoinType" "src/PostgREST/Config.hs"; then
        echo "✗ src/PostgREST/Config.hs still imports JoinType (fix not applied)"
        test_status=1
    else
        echo "✓ src/PostgREST/Config.hs doesn't import JoinType (fix applied)"
    fi

    # After fix: should NOT have parseEmbedDefaultJoin parser
    if grep -q "parseEmbedDefaultJoin" "src/PostgREST/Config.hs"; then
        echo "✗ src/PostgREST/Config.hs still has parseEmbedDefaultJoin parser (fix not applied)"
        test_status=1
    else
        echo "✓ src/PostgREST/Config.hs doesn't have parseEmbedDefaultJoin (fix applied)"
    fi
else
    echo "✗ src/PostgREST/Config.hs not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/App.hs doesn't pass configDbEmbedDefaultJoin..."
if [ -f "src/PostgREST/App.hs" ]; then
    echo "✓ src/PostgREST/App.hs exists"

    # After fix: readRequest should NOT pass configDbEmbedDefaultJoin to ReqBuilder.readRequest
    if grep -q "configDbEmbedDefaultJoin" "src/PostgREST/App.hs"; then
        echo "✗ src/PostgREST/App.hs still uses configDbEmbedDefaultJoin (fix not applied)"
        test_status=1
    else
        echo "✓ src/PostgREST/App.hs doesn't use configDbEmbedDefaultJoin (fix applied)"
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Request/DbRequestBuilder.hs signature..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ]; then
    echo "✓ src/PostgREST/Request/DbRequestBuilder.hs exists"

    # After fix: readRequest function should NOT take JoinType parameter
    # Look for the function signature without the joinType parameter
    if grep -q "readRequest.*JoinType" "src/PostgREST/Request/DbRequestBuilder.hs"; then
        echo "✗ DbRequestBuilder.readRequest still takes JoinType parameter (fix not applied)"
        test_status=1
    else
        echo "✓ DbRequestBuilder.readRequest doesn't take JoinType parameter (fix applied)"
    fi
else
    echo "✗ src/PostgREST/Request/DbRequestBuilder.hs not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Query/QueryBuilder.hs uses Maybe JoinType..."
if [ -f "src/PostgREST/Query/QueryBuilder.hs" ]; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs exists"

    # After fix: joinType should be Maybe JoinType and compared with Just JTInner
    if grep -q "Just JTInner" "src/PostgREST/Query/QueryBuilder.hs"; then
        echo "✓ QueryBuilder.hs correctly uses Maybe JoinType pattern (fix applied)"
    else
        echo "✗ QueryBuilder.hs doesn't use Maybe JoinType pattern correctly (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs not found"
    test_status=1
fi

echo ""
echo "Checking test config files don't include db-embed-default-join..."
config_files=(
    "test/io-tests/configs/expected/aliases.config"
    "test/io-tests/configs/expected/boolean-numeric.config"
    "test/io-tests/configs/expected/boolean-string.config"
    "test/io-tests/configs/expected/defaults.config"
    "test/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config"
    "test/io-tests/configs/expected/no-defaults-with-db.config"
    "test/io-tests/configs/expected/no-defaults.config"
    "test/io-tests/configs/expected/types.config"
)

for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        if grep -q "db-embed-default-join" "$config_file"; then
            echo "✗ $config_file still contains db-embed-default-join (fix not applied)"
            test_status=1
        else
            echo "✓ $config_file doesn't contain db-embed-default-join (fix applied)"
        fi
    else
        echo "✗ $config_file not found"
        test_status=1
    fi
done

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
