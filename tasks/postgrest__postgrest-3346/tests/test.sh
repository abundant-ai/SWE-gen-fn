#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io"
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md HAS the entry for #3345
echo "Checking that CHANGELOG.md has entry for #3345..."
if grep -q "#3345, Fix in-database configuration values not loading for \`pgrst.server_trace_header\` and \`pgrst.server_cors_allowed_origins\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3345"
else
    echo "✗ CHANGELOG.md missing entry for #3345 - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/App.hs imports LogLevel
echo "Checking that src/PostgREST/App.hs imports LogLevel..."
if grep -q "import PostgREST.Config.*LogLevel" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs imports LogLevel"
else
    echo "✗ src/PostgREST/App.hs does not import LogLevel - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/App.hs does NOT have NamedFieldPuns pragma
echo "Checking that src/PostgREST/App.hs does NOT have NamedFieldPuns pragma..."
if grep -q "{-# LANGUAGE NamedFieldPuns" "src/PostgREST/App.hs"; then
    echo "✗ src/PostgREST/App.hs still has NamedFieldPuns pragma - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/App.hs does not have NamedFieldPuns pragma"
fi

# Check that src/PostgREST/App.hs has correct postgrest function signature
echo "Checking that src/PostgREST/App.hs has correct postgrest function signature..."
if grep -q "postgrest :: LogLevel -> AppState.AppState -> IO () -> (Observation -> IO ()) -> Wai.Application" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has correct postgrest function signature"
else
    echo "✗ src/PostgREST/App.hs has incorrect postgrest function signature - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/App.hs has traceHeaderMiddleware with AppState
echo "Checking that src/PostgREST/App.hs has traceHeaderMiddleware with AppState..."
if grep -q "traceHeaderMiddleware :: AppState -> Wai.Middleware" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has traceHeaderMiddleware with AppState"
else
    echo "✗ src/PostgREST/App.hs has incorrect traceHeaderMiddleware signature - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/App.hs calls traceHeaderMiddleware with appState
echo "Checking that src/PostgREST/App.hs calls traceHeaderMiddleware with appState..."
if grep -q "traceHeaderMiddleware appState" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs calls traceHeaderMiddleware with appState"
else
    echo "✗ src/PostgREST/App.hs does not call traceHeaderMiddleware with appState - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Config/Database.hs has server_cors_allowed_origins in dbSettingsNames
echo "Checking that src/PostgREST/Config/Database.hs has server_cors_allowed_origins..."
if grep -q '"server_cors_allowed_origins"' "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has server_cors_allowed_origins"
else
    echo "✗ src/PostgREST/Config/Database.hs missing server_cors_allowed_origins - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Cors.hs has middleware with AppState parameter
echo "Checking that src/PostgREST/Cors.hs has middleware with AppState parameter..."
if grep -q "middleware :: AppState -> Wai.Middleware" "src/PostgREST/Cors.hs"; then
    echo "✓ src/PostgREST/Cors.hs has middleware with AppState parameter"
else
    echo "✗ src/PostgREST/Cors.hs has incorrect middleware signature - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Cors.hs imports AppState and getConfig
echo "Checking that src/PostgREST/Cors.hs imports AppState and getConfig..."
if grep -q "import PostgREST.AppState (AppState, getConfig)" "src/PostgREST/Cors.hs"; then
    echo "✓ src/PostgREST/Cors.hs imports AppState and getConfig"
else
    echo "✗ src/PostgREST/Cors.hs does not import AppState and getConfig - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Cors.hs imports AppConfig
echo "Checking that src/PostgREST/Cors.hs imports AppConfig..."
if grep -q "import PostgREST.Config.*AppConfig" "src/PostgREST/Cors.hs"; then
    echo "✓ src/PostgREST/Cors.hs imports AppConfig"
else
    echo "✗ src/PostgREST/Cors.hs does not import AppConfig - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
