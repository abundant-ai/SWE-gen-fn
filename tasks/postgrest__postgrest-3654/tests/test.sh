#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that App.hs uses schemaCacheLoader (the fixed version with backoff)
echo "Checking that App.hs uses schemaCacheLoader instead of connectionWorker..."
if grep -q "AppState.schemaCacheLoader appState" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses schemaCacheLoader - fix applied!"
else
    echo "✗ App.hs uses connectionWorker - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs defines schemaCacheLoader..."
if grep -q "schemaCacheLoader :: AppState -> IO ()" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs defines schemaCacheLoader - fix applied!"
else
    echo "✗ AppState.hs missing schemaCacheLoader definition - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs uses readInDbConfig (not reReadConfig)..."
if grep -q "readInDbConfig" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has readInDbConfig - fix applied!"
else
    echo "✗ AppState.hs missing readInDbConfig - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Observation.hs has QueryPgVersionError (not ConnectionPgVersionErrorObs)..."
if grep -q "QueryPgVersionError SQL.UsageError" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has QueryPgVersionError - fix applied!"
else
    echo "✗ Observation.hs missing QueryPgVersionError - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Observation.hs does NOT have DBConnectAttemptObs..."
if ! grep -q "DBConnectAttemptObs" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs doesn't have DBConnectAttemptObs - fix applied!"
else
    echo "✗ Observation.hs has DBConnectAttemptObs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has correct metrics assertion..."
if grep -q "assert metrics == 1.0" "test/io/test_io.py"; then
    echo "✓ test_io.py expects single failure (metrics == 1.0) - fix applied!"
else
    echo "✗ test_io.py has wrong assertion - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions the schema cache retry fix..."
if grep -q "#3523, Fix schema cache loading retry without backoff" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md missing entry for fix - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
