#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check AppState.hs for log level comparison in usePool
echo "Checking AppState.hs for log level comparison..."
if grep -q 'when (configLogLevel > LogCrit)' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has log level comparison"
else
    echo "✗ AppState.hs missing log level comparison - fix not applied"
    test_status=1
fi

# Check AppState.hs for logPgrstError call for internal db errors
echo "Checking AppState.hs for logPgrstError call..."
if grep -A 7 'when (configLogLevel > LogCrit)' "src/PostgREST/AppState.hs" | grep -q 'logPgrstError appState error'; then
    echo "✓ AppState.hs has logPgrstError call"
else
    echo "✗ AppState.hs missing logPgrstError call - fix not applied"
    test_status=1
fi

# Check AppState.hs for AcquisitionTimeoutUsageError handling
echo "Checking AppState.hs for AcquisitionTimeoutUsageError handling..."
if grep -q 'SQL.AcquisitionTimeoutUsageError -> debounceLogAcquisitionTimeout' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has AcquisitionTimeoutUsageError handling"
else
    echo "✗ AppState.hs missing AcquisitionTimeoutUsageError handling - fix not applied"
    test_status=1
fi

# Check AppState.hs for HTTP status check
echo "Checking AppState.hs for HTTP status check..."
if grep -q 'Error.status (Error.PgError False error) >= HTTP.status500' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has HTTP status check"
else
    echo "✗ AppState.hs missing HTTP status check - fix not applied"
    test_status=1
fi

# Check AppState.hs has usePool with AppConfig parameter
echo "Checking AppState.hs usePool signature..."
if grep -q 'usePool :: AppState -> AppConfig -> SQL.Session a -> IO (Either SQL.UsageError a)' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has usePool with AppConfig parameter"
else
    echo "✗ AppState.hs missing usePool with AppConfig parameter - fix not applied"
    test_status=1
fi

# Check AppState.hs usePool implementation receives AppConfig
echo "Checking AppState.hs usePool implementation..."
if grep -q 'usePool appState@AppState{..} AppConfig{configLogLevel} x = do' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs usePool implementation receives AppConfig"
else
    echo "✗ AppState.hs usePool implementation missing AppConfig - fix not applied"
    test_status=1
fi

# Check Config.hs for LogLevel deriving Eq, Ord
echo "Checking Config.hs for LogLevel deriving Eq, Ord..."
if grep -A 1 'data LogLevel = LogCrit | LogError | LogWarn | LogInfo' "src/PostgREST/Config.hs" | grep -q 'deriving (Eq, Ord)'; then
    echo "✓ Config.hs has LogLevel deriving Eq, Ord"
else
    echo "✗ Config.hs missing LogLevel deriving Eq, Ord - fix not applied"
    test_status=1
fi

# Check Admin.hs for usePool with config parameter
echo "Checking Admin.hs for usePool with config parameter..."
if grep -q 'AppState.usePool appState appConfig' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs has usePool with config parameter"
else
    echo "✗ Admin.hs missing usePool with config parameter - fix not applied"
    test_status=1
fi

# Check App.hs for runDbHandler with config parameter
echo "Checking App.hs for runDbHandler with AppConfig parameter..."
if grep -q 'runDbHandler :: AppState.AppState -> AppConfig -> SQL.IsolationLevel -> SQL.Mode -> Bool -> Bool -> DbHandler b -> Handler IO b' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has runDbHandler with AppConfig parameter"
else
    echo "✗ App.hs missing runDbHandler with AppConfig parameter - fix not applied"
    test_status=1
fi

# Check App.hs for usePool call with config
echo "Checking App.hs for usePool call with config..."
if grep -q 'AppState.usePool appState config' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has usePool call with config"
else
    echo "✗ App.hs missing usePool call with config - fix not applied"
    test_status=1
fi

# Check Error.hs exports status function
echo "Checking Error.hs exports status function..."
if grep -q ', status' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs exports status function"
else
    echo "✗ Error.hs missing status function export - fix not applied"
    test_status=1
fi

# Check test_io.py has parametrized tests (these should match after copying HEAD version)
echo "Checking test_io.py for parametrized test_pool_acquisition_timeout..."
if grep -q '@pytest.mark.parametrize("level", \["crit", "error", "warn", "info"\])' "test/io/test_io.py" && \
   grep -q 'def test_pool_acquisition_timeout(level, defaultenv, metapostgrest):' "test/io/test_io.py"; then
    echo "✓ test_io.py has parametrized test_pool_acquisition_timeout"
else
    echo "✗ test_io.py missing parametrized test_pool_acquisition_timeout - fix not applied"
    test_status=1
fi

echo "Checking test_io.py for parametrized test_db_error_logging_to_stderr..."
if grep -q '@pytest.mark.parametrize("level", \["crit", "error", "warn", "info"\])' "test/io/test_io.py" && \
   grep -q 'def test_db_error_logging_to_stderr(level, defaultenv, metapostgrest):' "test/io/test_io.py"; then
    echo "✓ test_io.py has parametrized test_db_error_logging_to_stderr"
else
    echo "✗ test_io.py missing parametrized test_db_error_logging_to_stderr - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
