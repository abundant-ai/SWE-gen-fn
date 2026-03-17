#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #1872 which adds timestamps to log messages
# HEAD state (1a6e5d3d03350f50f25676d280995306cd3a72c6) = has timestamp logging - FIXED
# BASE state (with bug.patch) = no timestamp logging - BUGGY
# ORACLE state (BASE + fix.patch) = has timestamp logging - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for timestamp logging)..."
echo ""

echo "Checking that AppState.hs exports logWithZTime..."
if grep -q 'logWithZTime' "src/PostgREST/AppState.hs" && grep -q '^  , logWithZTime$' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs exports logWithZTime - fix applied!"
else
    echo "✗ AppState.hs doesn't export logWithZTime - fix not applied"
    test_status=1
fi

echo "Checking that AppState.hs imports Data.Time..."
if grep -q 'import Data.Time' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports Data.Time - fix applied!"
else
    echo "✗ AppState.hs missing Data.Time import - fix not applied"
    test_status=1
fi

echo "Checking that AppState has stateGetZTime field..."
if grep -q 'stateGetZTime.*::.*IO ZonedTime' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState has stateGetZTime field - fix applied!"
else
    echo "✗ AppState missing stateGetZTime field - fix not applied"
    test_status=1
fi

echo "Checking that AppState.hs defines logWithZTime function..."
if grep -q 'logWithZTime :: AppState -> Text -> IO ()' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs defines logWithZTime function - fix applied!"
else
    echo "✗ AppState.hs doesn't define logWithZTime function - fix not applied"
    test_status=1
fi

echo "Checking that main/Main.hs uses LineBuffering for stderr..."
if grep -q 'hSetBuffering stderr LineBuffering' "main/Main.hs"; then
    echo "✓ main/Main.hs uses LineBuffering for stderr - fix applied!"
else
    echo "✗ main/Main.hs doesn't use LineBuffering for stderr - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses logWithZTime for port logging..."
if grep -q 'AppState.logWithZTime appState.*Listening on port' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses logWithZTime for port logging - fix applied!"
else
    echo "✗ App.hs doesn't use logWithZTime for port logging - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses logWithZTime for socket logging..."
if grep -q 'AppState.logWithZTime appState.*Listening on unix socket' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses logWithZTime for socket logging - fix applied!"
else
    echo "✗ App.hs doesn't use logWithZTime for socket logging - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses logWithZTime for connection messages..."
if grep -q 'AppState.logWithZTime appState.*Attempting to connect to the database' "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs uses logWithZTime for connection messages - fix applied!"
else
    echo "✗ Workers.hs doesn't use logWithZTime for connection messages - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses logWithZTime for 'Connection successful'..."
if grep -q 'AppState.logWithZTime appState.*Connection successful' "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs uses logWithZTime for 'Connection successful' - fix applied!"
else
    echo "✗ Workers.hs doesn't use logWithZTime for 'Connection successful' - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses logWithZTime for reconnect messages..."
if grep -Pzo 'AppState.logWithZTime appState.*\$\s+"Attempting to reconnect to the database' "src/PostgREST/Workers.hs" > /dev/null; then
    echo "✓ Workers.hs uses logWithZTime for reconnect messages - fix applied!"
else
    echo "✗ Workers.hs doesn't use logWithZTime for reconnect messages - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses logWithZTime for 'Schema cache loaded'..."
if grep -q 'AppState.logWithZTime appState.*Schema cache loaded' "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs uses logWithZTime for 'Schema cache loaded' - fix applied!"
else
    echo "✗ Workers.hs doesn't use logWithZTime for 'Schema cache loaded' - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses logWithZTime for 'Config re-loaded'..."
if grep -q 'AppState.logWithZTime appState.*Config re-loaded' "src/PostgREST/Workers.hs"; then
    echo "✓ Workers.hs uses logWithZTime for 'Config re-loaded' - fix applied!"
else
    echo "✗ Workers.hs doesn't use logWithZTime for 'Config re-loaded' - fix not applied"
    test_status=1
fi

echo "Checking that Config/Database.hs returns Either for queryDbSettings..."
if grep -q 'queryDbSettings :: P.Pool -> IO (Either P.UsageError \[(Text, Text)\])' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs has correct queryDbSettings signature - fix applied!"
else
    echo "✗ Config/Database.hs has wrong queryDbSettings signature - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
