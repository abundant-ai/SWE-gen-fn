#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4617 which adds actual host and port to the listener connection log message

test_status=0

echo "Verifying source code matches HEAD state (listener connection log with host and port)..."
echo ""

echo "Checking that CHANGELOG.md mentions PR #4617..."
if grep -q "Log the actual host and port of listener database connection by @mkleczek in #4617" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #4617 - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention #4617 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs imports Control.Arrow..."
if grep -q "Control.Arrow" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs imports Control.Arrow - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs missing Control.Arrow import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs imports Data.Bitraversable..."
if grep -q "Data.Bitraversable" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs imports Data.Bitraversable - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs missing Data.Bitraversable import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs imports LibPQ..."
if grep -q "Database.PostgreSQL.LibPQ" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs imports LibPQ - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs missing LibPQ import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs gets host and port from LibPQ..."
if grep -q "SQL.withLibPQConnection db" "src/PostgREST/Listener.hs" && \
   grep -q "bisequence" "src/PostgREST/Listener.hs" && \
   grep -q "LibPQ.host" "src/PostgREST/Listener.hs" && \
   grep -q "LibPQ.port" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs gets host and port from LibPQ - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs does not get host and port - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs passes host and port to DBListenStart..."
if grep -q "DBListenStart pqHost pqPort" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs passes host and port to DBListenStart - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs does not pass host and port - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs includes host and port in DBListenStart..."
if grep -q "DBListenStart (Maybe ByteString) (Maybe ByteString) Text" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has host and port in DBListenStart - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs missing host and port parameters - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs log message includes host and port..."
if grep -q 'DBListenStart host port channel' "src/PostgREST/Observation.hs" && \
   grep -q 'Listener connected to' "src/PostgREST/Observation.hs" && \
   grep -q 'show (fold \$ host <> fmap (":" <>) port)' "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs log message includes host and port - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs log message missing host and port - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_io.py has test_log_listener_connection_start test..."
if grep -q "def test_log_listener_connection_start(defaultenv):" "test/io/test_io.py" && \
   grep -q 'Listener connected to' "test/io/test_io.py"; then
    echo "✓ test_io.py has test_log_listener_connection_start test - fix applied!"
else
    echo "✗ test_io.py missing the new test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
