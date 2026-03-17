#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

test_status=0

echo "Verifying fix for socket initialization moved from AppState to main server startup (PR #4713)..."
echo ""
echo "This PR fixes the initialization flow so that listening socket creation/management is owned"
echo "by the main server startup logic rather than the application state. Sockets are created only"
echo "when starting the actual HTTP services."
echo ""

echo "Checking App.hs has initSockets function restored..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'initSockets :: AppConfig -> IO AppSockets' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has initSockets function (fix applied)"
else
    echo "✗ App.hs does not have initSockets function (not fixed)"
    test_status=1
fi

echo "Checking App.hs calls initSockets after schemaCacheLoader..."
if [ -f "src/PostgREST/App.hs" ] && grep -q '(mainSocket, adminSocket) <- initSockets conf' "src/PostgREST/App.hs"; then
    echo "✓ App.hs calls initSockets correctly (fix applied)"
else
    echo "✗ App.hs does not call initSockets (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs receives sockets as parameters..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q 'runAdmin :: AppState -> Maybe NS.Socket -> NS.Socket -> Warp.Settings -> IO ()' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs receives sockets as parameters (fix applied)"
else
    echo "✗ Admin.hs does not receive sockets as parameters (not fixed)"
    test_status=1
fi

echo "Checking AppState.hs no longer exports getSocketREST and getSocketAdmin..."
if [ -f "src/PostgREST/AppState.hs" ] && ! grep -q 'getSocketREST' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs does not export getSocketREST (fix applied)"
else
    echo "✗ AppState.hs still exports getSocketREST (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test file exists..."
if [ -f "test/spec/Main.hs" ]; then
    echo "✓ test/spec/Main.hs exists (HEAD version)"
else
    echo "✗ test/spec/Main.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
