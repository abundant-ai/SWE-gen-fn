#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for db-pool-acquisition-timeout logging to stderr..."
echo ""
echo "NOTE: This PR adds logging to stderr when connection pool acquisition times out"
echo "HEAD (fixed) should have debounceLogAcquisitionTimeout and logging logic."
echo "BASE (buggy) lacks the pool acquisition timeout logging functionality."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2667 entry
echo "Checking CHANGELOG.md has PR #2667 entry..."
if grep -q "#2667, Fix \`db-pool-acquisition-timeout\` not logging to stderr" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2667 entry"
else
    echo "✗ CHANGELOG.md missing PR #2667 entry - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should export debounceLogAcquisitionTimeout
echo "Checking src/PostgREST/AppState.hs exports debounceLogAcquisitionTimeout..."
if grep -q "debounceLogAcquisitionTimeout" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has debounceLogAcquisitionTimeout"
else
    echo "✗ AppState.hs missing debounceLogAcquisitionTimeout - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should have logPgrstError function
echo "Checking src/PostgREST/AppState.hs exports logPgrstError..."
if grep -q "logPgrstError" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has logPgrstError"
else
    echo "✗ AppState.hs missing logPgrstError - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should have debounceLogAcquisitionTimeout field in AppState
echo "Checking AppState.hs has debounceLogAcquisitionTimeout field in AppState data type..."
if grep -q "debounceLogAcquisitionTimeout :: IO ()" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has debounceLogAcquisitionTimeout field"
else
    echo "✗ AppState.hs missing debounceLogAcquisitionTimeout field - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should import Control.Debounce
echo "Checking AppState.hs imports Control.Debounce..."
if grep -q "Control.Debounce" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports Control.Debounce"
else
    echo "✗ AppState.hs missing Control.Debounce import - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should handle AcquisitionTimeoutUsageError with debouncing
echo "Checking src/PostgREST/App.hs handles AcquisitionTimeoutUsageError..."
if grep -q "AcquisitionTimeoutUsageError" "src/PostgREST/App.hs" && \
   grep -q "debounceLogAcquisitionTimeout" "src/PostgREST/App.hs"; then
    echo "✓ App.hs handles AcquisitionTimeoutUsageError with debouncing"
else
    echo "✗ App.hs missing AcquisitionTimeoutUsageError handling - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should have LambdaCase extension
echo "Checking App.hs has LambdaCase language extension..."
if grep -q "{-# LANGUAGE LambdaCase" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has LambdaCase extension"
else
    echo "✗ App.hs missing LambdaCase extension - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should use whenLeft for error handling
echo "Checking App.hs uses whenLeft for AcquisitionTimeoutUsageError..."
if grep -q "whenLeft" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses whenLeft"
else
    echo "✗ App.hs missing whenLeft usage - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have checkIsFatal accepting SQL.UsageError
echo "Checking src/PostgREST/Error.hs has checkIsFatal for SQL.UsageError..."
if grep -q "checkIsFatal :: SQL.UsageError -> Maybe Text" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has checkIsFatal with SQL.UsageError"
else
    echo "✗ Error.hs missing correct checkIsFatal signature - fix not applied"
    test_status=1
fi

# Check test file - HEAD should have the stderr logging assertion
echo "Checking test/io/test_io.py has stderr logging assertion..."
if grep -q "ensure the message appears on the logs as well" "test/io/test_io.py" && \
   grep -q "assert \"Timed out acquiring connection from connection pool.\" in output.decode()" "test/io/test_io.py"; then
    echo "✓ test_io.py has stderr logging assertion"
else
    echo "✗ test_io.py missing stderr logging assertion - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - db-pool-acquisition-timeout logging feature properly implemented"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
