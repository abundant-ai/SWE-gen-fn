#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot[dbRoutines].yaml"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md HAS the entry for #3340
echo "Checking that CHANGELOG.md has entry for #3340..."
if grep -q "#3340, Log when the LISTEN channel gets a notification" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3340"
else
    echo "✗ CHANGELOG.md missing entry for #3340 - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs has MultiWayIf language pragma
echo "Checking that src/PostgREST/AppState.hs has MultiWayIf pragma..."
if grep -q "{-# LANGUAGE MultiWayIf" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs has MultiWayIf pragma"
else
    echo "✗ src/PostgREST/AppState.hs missing MultiWayIf pragma - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs handleNotification uses 'if' with channel parameter
echo "Checking that src/PostgREST/AppState.hs handleNotification uses channel parameter..."
if grep -q "handleNotification channel msg =" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs handleNotification uses channel parameter"
else
    echo "✗ src/PostgREST/AppState.hs handleNotification incorrect - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs calls observer with DBListenerGotSCacheMsg
echo "Checking that src/PostgREST/AppState.hs calls observer (DBListenerGotSCacheMsg channel)..."
if grep -q "observer (DBListenerGotSCacheMsg channel)" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs calls observer (DBListenerGotSCacheMsg channel)"
else
    echo "✗ src/PostgREST/AppState.hs missing observer call - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs calls observer with DBListenerGotConfigMsg
echo "Checking that src/PostgREST/AppState.hs calls observer (DBListenerGotConfigMsg channel)..."
if grep -q "observer (DBListenerGotConfigMsg channel)" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs calls observer (DBListenerGotConfigMsg channel)"
else
    echo "✗ src/PostgREST/AppState.hs missing observer call - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs has DBListenerGotSCacheMsg constructor
echo "Checking that src/PostgREST/Observation.hs has DBListenerGotSCacheMsg..."
if grep -q "| DBListenerGotSCacheMsg ByteString" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has DBListenerGotSCacheMsg"
else
    echo "✗ src/PostgREST/Observation.hs missing DBListenerGotSCacheMsg - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs has DBListenerGotConfigMsg constructor
echo "Checking that src/PostgREST/Observation.hs has DBListenerGotConfigMsg..."
if grep -q "| DBListenerGotConfigMsg ByteString" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has DBListenerGotConfigMsg"
else
    echo "✗ src/PostgREST/Observation.hs missing DBListenerGotConfigMsg - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs has message for DBListenerGotSCacheMsg
echo "Checking that src/PostgREST/Observation.hs has message for DBListenerGotSCacheMsg..."
if grep -q '"Received a schema cache reload message on the " <> show channel <> " channel"' "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has message for DBListenerGotSCacheMsg"
else
    echo "✗ src/PostgREST/Observation.hs missing message for DBListenerGotSCacheMsg - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs has message for DBListenerGotConfigMsg
echo "Checking that src/PostgREST/Observation.hs has message for DBListenerGotConfigMsg..."
if grep -q '"Received a config reload message on the " <> show channel <> " channel"' "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has message for DBListenerGotConfigMsg"
else
    echo "✗ src/PostgREST/Observation.hs missing message for DBListenerGotConfigMsg - fix not applied"
    test_status=1
fi

# Check that test/io/fixtures.sql has notify_do_nothing function
echo "Checking that test/io/fixtures.sql has notify_do_nothing function..."
if grep -q "create function notify_do_nothing()" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has notify_do_nothing function"
else
    echo "✗ test/io/fixtures.sql missing notify_do_nothing function - fix not applied"
    test_status=1
fi

# Check that test/io/test_io.py checks for log message
echo "Checking that test/io/test_io.py checks for 'Received a config reload message'..."
if grep -q 'Received a config reload message on the "pgrst" channel' "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py checks for log message"
else
    echo "✗ test/io/test_io.py missing log message check - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
