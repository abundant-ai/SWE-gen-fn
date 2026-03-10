#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

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
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/CorsSpec.hs" "test/spec/Feature/CorsSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Check that Config.hs has the new configServerCorsAllowedOrigins field
echo "Checking Config.hs for configServerCorsAllowedOrigins field..."
if grep -q 'configServerCorsAllowedOrigins :: Maybe \[Text\]' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configServerCorsAllowedOrigins field"
else
    echo "✗ Config.hs missing configServerCorsAllowedOrigins field - fix not applied"
    test_status=1
fi

# Check that Config.hs parser includes the new config option
echo "Checking Config.hs for parser update..."
if grep -q 'splitOnCommas <\$> optValue "server-cors-allowed-origins"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs parser includes server-cors-allowed-origins"
else
    echo "✗ Config.hs parser missing server-cors-allowed-origins - fix not applied"
    test_status=1
fi

# Check that Cors.hs middleware now takes corsAllowedOrigins parameter
echo "Checking Cors.hs for middleware signature..."
if grep -q 'middleware :: Maybe \[Text\] -> Wai.Middleware' "src/PostgREST/Cors.hs"; then
    echo "✓ Cors.hs middleware signature updated"
else
    echo "✗ Cors.hs middleware signature not updated - fix not applied"
    test_status=1
fi

# Check that Cors.hs corsPolicy now uses corsAllowedOrigins
echo "Checking Cors.hs for corsPolicy implementation..."
if grep -q 'corsPolicy :: Maybe \[Text\] -> Wai.Request -> Maybe Wai.CorsResourcePolicy' "src/PostgREST/Cors.hs"; then
    echo "✓ Cors.hs corsPolicy signature updated"
else
    echo "✗ Cors.hs corsPolicy signature not updated - fix not applied"
    test_status=1
fi

# Check that Cors.hs uses the configurable origins
echo "Checking Cors.hs for origin configuration..."
if grep -q 'Wai.corsOrigins = (.*) \. map T.encodeUtf8 <\$> corsAllowedOrigins' "src/PostgREST/Cors.hs"; then
    echo "✓ Cors.hs uses corsAllowedOrigins for CORS origins"
else
    echo "✗ Cors.hs not using corsAllowedOrigins properly - fix not applied"
    test_status=1
fi

# Check that App.hs passes the config to CORS middleware
echo "Checking App.hs for middleware call..."
if grep -q 'Cors.middleware (configServerCorsAllowedOrigins conf)' "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes configServerCorsAllowedOrigins to middleware"
else
    echo "✗ App.hs not passing configServerCorsAllowedOrigins - fix not applied"
    test_status=1
fi

# Check that CLI.hs includes the new config in example
echo "Checking CLI.hs for config example..."
if grep -q 'server-cors-allowed-origins' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs includes server-cors-allowed-origins in example"
else
    echo "✗ CLI.hs missing server-cors-allowed-origins - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2441, Add config `server-cors-allowed-origins` to specify CORS origins' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
