#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Complex resolveHost function and separate log message types
# In HEAD (fix applied): Simplified resolveSocketToAddress function and unified log messages

test_status=0

echo "Verifying Haskell source code changes for network refactoring fix..."
echo ""

echo "Checking src/PostgREST/Network.hs for simplified resolveSocketToAddress function..."
if grep -q "resolveSocketToAddress :: NS.Socket -> IO Text" "src/PostgREST/Network.hs"; then
    echo "✓ Network.hs has simplified resolveSocketToAddress function - fix is applied!"
else
    echo "✗ Network.hs does not have simplified resolveSocketToAddress function - fix not applied"
    test_status=1
fi

if grep -q "showSocketAddr :: NS.SockAddr -> Text" "src/PostgREST/Network.hs"; then
    echo "✓ Network.hs has showSocketAddr helper function - fix is applied!"
else
    echo "✗ Network.hs does not have showSocketAddr helper function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Observation.hs for simplified log message types..."
if grep -q "AdminStartObs Text" "src/PostgREST/Observation.hs" && ! grep -q "AdminStartObs (Maybe Text) (Maybe Int)" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has simplified AdminStartObs with single Text parameter - fix is applied!"
else
    echo "✗ Observation.hs does not have simplified AdminStartObs - fix not applied"
    test_status=1
fi

if grep -q "AppServerAddressObs Text" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has unified AppServerAddressObs constructor - fix is applied!"
else
    echo "✗ Observation.hs does not have unified AppServerAddressObs constructor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Admin.hs imports..."
if grep -q "import PostgREST.Network.*resolveSocketToAddress" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs imports resolveSocketToAddress - fix is applied!"
else
    echo "✗ Admin.hs does not import resolveSocketToAddress - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/App.hs imports..."
if grep -q "import PostgREST.Network.*resolveSocketToAddress" "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports resolveSocketToAddress - fix is applied!"
else
    echo "✗ App.hs does not import resolveSocketToAddress - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
