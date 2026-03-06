#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/config.py" "test/io/config.py"
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"

# Verify the fix by checking source code changes
# In BASE (bug.patch applied): --ready flag and PostgREST.Client module removed
# In HEAD (fix applied): --ready flag and PostgREST.Client module present

test_status=0

echo "Verifying source code changes for --ready flag implementation..."
echo ""

echo "Checking src/PostgREST/CLI.hs for --ready flag..."
if grep -q "import qualified PostgREST.Client" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs imports PostgREST.Client module - fix is applied!"
else
    echo "✗ CLI.hs does not import PostgREST.Client module - fix not applied"
    test_status=1
fi

if grep -q "readyFlag" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has readyFlag definition - fix is applied!"
else
    echo "✗ CLI.hs does not have readyFlag definition - fix not applied"
    test_status=1
fi

if grep -q "runClientCommand" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has runClientCommand function - fix is applied!"
else
    echo "✗ CLI.hs does not have runClientCommand function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking for PostgREST.Client module..."
if [ -f "src/PostgREST/Client.hs" ]; then
    echo "✓ PostgREST.Client module exists - fix is applied!"
else
    echo "✗ PostgREST.Client module does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking postgrest.cabal for http-client dependency..."
if grep -q "http-client" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes http-client dependency - fix is applied!"
else
    echo "✗ postgrest.cabal missing http-client dependency - fix not applied"
    test_status=1
fi

if grep -q "PostgREST.Client" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PostgREST.Client module - fix is applied!"
else
    echo "✗ postgrest.cabal missing PostgREST.Client module - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
