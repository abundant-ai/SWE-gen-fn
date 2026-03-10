#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check CHANGELOG for the fix mention
echo "Checking CHANGELOG for #2420 entry..."
if grep -q '#2420.*Fix bogus message when listening on port 0' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions #2420 fix"
else
    echo "✗ CHANGELOG missing #2420 entry - fix not applied"
    test_status=1
fi

# Check main/Main.hs has been simplified (removed CPP and platform-specific code)
echo "Checking main/Main.hs for simplified code..."
if ! grep -q '{-# LANGUAGE CPP #-}' "main/Main.hs"; then
    echo "✓ main/Main.hs removed CPP pragma"
else
    echo "✗ main/Main.hs still has CPP pragma - fix not applied"
    test_status=1
fi

if ! grep -q 'installSignalHandlers' "main/Main.hs"; then
    echo "✓ main/Main.hs removed installSignalHandlers"
else
    echo "✗ main/Main.hs still has installSignalHandlers - fix not applied"
    test_status=1
fi

if ! grep -q 'runAppInSocket' "main/Main.hs"; then
    echo "✓ main/Main.hs removed runAppInSocket"
else
    echo "✗ main/Main.hs still has runAppInSocket - fix not applied"
    test_status=1
fi

# Check postgrest.cabal has PostgREST.Unix in library exposed-modules
echo "Checking postgrest.cabal for PostgREST.Unix in library..."
if grep -q 'PostgREST.Unix' "postgrest.cabal" | head -1; then
    echo "✓ postgrest.cabal has PostgREST.Unix in library"
else
    echo "✗ postgrest.cabal missing PostgREST.Unix - fix not applied"
    test_status=1
fi

# Check postgrest.cabal has new dependencies (directory, streaming-commons, unix-compat)
echo "Checking postgrest.cabal for new dependencies..."
if grep -q 'directory' "postgrest.cabal" && grep -q 'streaming-commons' "postgrest.cabal" && grep -q 'unix-compat' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has new dependencies"
else
    echo "✗ postgrest.cabal missing new dependencies - fix not applied"
    test_status=1
fi

# Check Admin.hs uses getSocketAdmin
echo "Checking Admin.hs for getSocketAdmin..."
if grep -q 'AppState.getSocketAdmin appState' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs uses getSocketAdmin"
else
    echo "✗ Admin.hs not using getSocketAdmin - fix not applied"
    test_status=1
fi

# Check Admin.hs uses runSettingsSocket
echo "Checking Admin.hs for runSettingsSocket..."
if grep -q 'Warp.runSettingsSocket settings adminSocket' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs uses runSettingsSocket"
else
    echo "✗ Admin.hs not using runSettingsSocket - fix not applied"
    test_status=1
fi

# Check Admin.hs reachMainApp signature change
echo "Checking Admin.hs reachMainApp signature..."
if grep -q 'reachMainApp (AppState.getSocketREST appState)' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs reachMainApp uses getSocketREST"
else
    echo "✗ Admin.hs reachMainApp not updated - fix not applied"
    test_status=1
fi

# Check App.hs has been updated (removed SignalHandlerInstaller and SocketRunner)
echo "Checking App.hs for module export changes..."
if ! grep -q 'SignalHandlerInstaller' "src/PostgREST/App.hs"; then
    echo "✓ App.hs removed SignalHandlerInstaller from exports"
else
    echo "✗ App.hs still has SignalHandlerInstaller - fix not applied"
    test_status=1
fi

if ! grep -q 'SocketRunner' "src/PostgREST/App.hs"; then
    echo "✓ App.hs removed SocketRunner from exports"
else
    echo "✗ App.hs still has SocketRunner - fix not applied"
    test_status=1
fi

# Check AppState.hs has socket management functions
echo "Checking AppState.hs for socket management..."
if grep -q 'getSocketREST' "src/PostgREST/AppState.hs" && grep -q 'getSocketAdmin' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has socket getters"
else
    echo "✗ AppState.hs missing socket getters - fix not applied"
    test_status=1
fi

if grep -q 'initSockets' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has initSockets"
else
    echo "✗ AppState.hs missing initSockets - fix not applied"
    test_status=1
fi

# Check CLI.hs has been simplified
echo "Checking CLI.hs for simplified signature..."
if grep -q 'main :: CLI -> IO ()' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs main has simplified signature"
else
    echo "✗ CLI.hs main signature not simplified - fix not applied"
    test_status=1
fi

# Check Unix.hs exists and has key functionality
echo "Checking Unix.hs module exists..."
if [ -f "src/PostgREST/Unix.hs" ]; then
    echo "✓ Unix.hs module exists"

    # Check for key functions in Unix.hs
    if grep -q 'installSignalHandlers' "src/PostgREST/Unix.hs"; then
        echo "✓ Unix.hs has installSignalHandlers"
    else
        echo "✗ Unix.hs missing installSignalHandlers - fix not applied"
        test_status=1
    fi

    if grep -q 'createAndBindDomainSocket' "src/PostgREST/Unix.hs"; then
        echo "✓ Unix.hs has createAndBindDomainSocket"
    else
        echo "✗ Unix.hs missing createAndBindDomainSocket - fix not applied"
        test_status=1
    fi
else
    echo "✗ Unix.hs module not found - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
