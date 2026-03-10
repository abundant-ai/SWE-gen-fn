#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4618 which adds PostgreSQL version details to the listener connection log message

test_status=0

echo "Verifying source code matches HEAD state (listener connection log with PG version details)..."
echo ""

echo "Checking that CHANGELOG.md mentions both PR #4617 and #4618..."
if grep -q "Log host, port and pg version of listener database connection by @mkleczek in #4617 #4618" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions both #4617 and #4618 - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention both PRs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs imports queryPgVersion..."
if grep -q "PostgREST.Config.Database.*queryPgVersion" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs imports queryPgVersion - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs missing queryPgVersion import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs imports pgvFullName..."
if grep -q "PostgREST.Config.PgVersion.*pgvFullName" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs imports pgvFullName - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs missing pgvFullName import - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Listener.hs queries PG version before logging..."
if grep -q "pgFullName <- SQL.run (queryPgVersion False) db" "src/PostgREST/Listener.hs"; then
    echo "✓ src/PostgREST/Listener.hs queries PG version - fix applied!"
else
    echo "✗ src/PostgREST/Listener.hs does not query PG version - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs includes version string in DBListenStart..."
if grep -q "DBListenStart (Maybe ByteString) (Maybe ByteString) Text Text" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has version in DBListenStart - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs missing version parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs log message includes version..."
if grep -q 'DBListenStart host port fullName channel' "src/PostgREST/Observation.hs" && \
   grep -q '"Listener connected to " <> fullName <> " on "' "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs log message includes version - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs log message missing version - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_io.py updated to check for version in log..."
if grep -q 'output = postgrest.read_stdout(nlines=10)' "test/io/test_io.py" && \
   grep -q '# Do not check if pg version is displayed properly as it is tricky to test it' "test/io/test_io.py"; then
    echo "✓ test_io.py updated with comment about version check - fix applied!"
else
    echo "✗ test_io.py not properly updated - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
