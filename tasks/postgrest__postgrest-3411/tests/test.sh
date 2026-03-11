#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying LogLevel refactoring in logging subsystem (PR #3411)..."
echo ""
echo "NOTE: This PR refactors the logging subsystem to use LogLevel type consistently"
echo "BASE (buggy) removes observer from AppState and uses it from config"
echo "HEAD (fixed) stores observer in AppState with logger state"
echo ""

# Check that AppState.hs exports getObserver
echo "Checking src/PostgREST/AppState.hs exports getObserver..."
if grep -q "getObserver" "src/PostgREST/AppState.hs" | head -30; then
    echo "✓ AppState exports getObserver"
else
    echo "✗ AppState does not export getObserver - fix not applied"
    test_status=1
fi

# Check that AppState has stateLogger field
echo "Checking src/PostgREST/AppState.hs has stateLogger field..."
if grep -q "stateLogger" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState has stateLogger field"
else
    echo "✗ AppState does not have stateLogger field - fix not applied"
    test_status=1
fi

# Check that AppState has stateObserver field
echo "Checking src/PostgREST/AppState.hs has stateObserver field..."
if grep -q "stateObserver" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState has stateObserver field"
else
    echo "✗ AppState does not have stateObserver field - fix not applied"
    test_status=1
fi

# Check that AppState imports Logger
echo "Checking src/PostgREST/AppState.hs imports PostgREST.Logger..."
if grep -q "import.*PostgREST.Logger" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState imports PostgREST.Logger"
else
    echo "✗ AppState does not import PostgREST.Logger - fix not applied"
    test_status=1
fi

# Check that AppState.init uses Logger.init
echo "Checking src/PostgREST/AppState.hs init function uses Logger.init..."
if grep -q "Logger.init" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.init uses Logger.init"
else
    echo "✗ AppState.init does not use Logger.init - fix not applied"
    test_status=1
fi

# Check that AppState.init uses Logger.observationLogger
echo "Checking src/PostgREST/AppState.hs init function uses Logger.observationLogger..."
if grep -q "Logger.observationLogger" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.init uses Logger.observationLogger with configLogLevel"
else
    echo "✗ AppState.init does not use Logger.observationLogger - fix not applied"
    test_status=1
fi

# Check that usePool signature changed (no longer takes AppConfig)
echo "Checking src/PostgREST/AppState.hs usePool signature..."
if grep -q "usePool :: AppState -> SQL.Session" "src/PostgREST/AppState.hs"; then
    echo "✓ usePool has simplified signature (AppState -> SQL.Session)"
else
    echo "✗ usePool signature not updated - fix not applied"
    test_status=1
fi

# Check that App.hs uses getObserver
echo "Checking src/PostgREST/App.hs uses AppState.getObserver..."
if grep -q "getObserver appState" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses AppState.getObserver"
else
    echo "✗ App.hs does not use AppState.getObserver - fix not applied"
    test_status=1
fi

# Check that Logger.middleware has Auth.getRole parameter
echo "Checking src/PostgREST/App.hs Logger.middleware has Auth.getRole parameter..."
if grep -q "Logger.middleware logLevel Auth.getRole" "src/PostgREST/App.hs"; then
    echo "✓ Logger.middleware uses Auth.getRole parameter"
else
    echo "✗ Logger.middleware does not have Auth.getRole parameter - fix not applied"
    test_status=1
fi

# Check that Admin.hs uses getObserver from AppState
echo "Checking src/PostgREST/Admin.hs uses getObserver from AppState..."
if grep -q "observer = AppState.getObserver appState" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs gets observer from AppState"
else
    echo "✗ Admin.hs does not get observer from AppState - fix not applied"
    test_status=1
fi

# Check that Admin.hs usePool call simplified
echo "Checking src/PostgREST/Admin.hs usePool call simplified..."
if grep -q "AppState.usePool appState (SQL.sql" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs usePool call simplified (no AppConfig parameter)"
else
    echo "✗ Admin.hs usePool still has AppConfig parameter - fix not applied"
    test_status=1
fi

# Check that initWithPool signature includes LoggerState and ObservationHandler
echo "Checking src/PostgREST/AppState.hs initWithPool signature..."
if grep -q "initWithPool.*Logger.LoggerState.*ObservationHandler" "src/PostgREST/AppState.hs"; then
    echo "✓ initWithPool has LoggerState and ObservationHandler parameters"
else
    echo "✗ initWithPool signature not updated - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - LogLevel refactoring applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
