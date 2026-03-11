#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for resolved host logging in startup messages (PR #3560)..."
echo ""
echo "NOTE: This PR adds logging of resolved IP addresses in 'Listening on' messages"
echo "BASE (buggy) does not resolve or log host IP addresses"
echo "HEAD (fixed) resolves and logs the host IP address alongside host/port"
echo ""

# Check that the fix was applied to src/PostgREST/Network.hs (new file)
echo "Checking src/PostgREST/Network.hs exists with resolveHost function..."
if [ -f "src/PostgREST/Network.hs" ]; then
    echo "✓ PostgREST/Network.hs file exists"
else
    echo "✗ PostgREST/Network.hs file does not exist - fix not applied"
    test_status=1
fi

# Check that resolveHost function is present
if [ -f "src/PostgREST/Network.hs" ]; then
    echo "Checking PostgREST/Network.hs contains resolveHost function..."
    if grep -q "resolveHost" "src/PostgREST/Network.hs"; then
        echo "✓ resolveHost function is defined"
    else
        echo "✗ resolveHost function not found - fix not applied"
        test_status=1
    fi
fi

# Check that resolveHost uses getSocketName
if [ -f "src/PostgREST/Network.hs" ]; then
    echo "Checking resolveHost uses getSocketName..."
    if grep -q "getSocketName" "src/PostgREST/Network.hs"; then
        echo "✓ resolveHost uses getSocketName"
    else
        echo "✗ resolveHost does not use getSocketName - fix not applied"
        test_status=1
    fi
fi

# Check that App.hs imports PostgREST.Network
echo "Checking src/PostgREST/App.hs imports PostgREST.Network..."
if grep -q "import.*PostgREST.Network" "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports PostgREST.Network"
else
    echo "✗ App.hs does not import PostgREST.Network - fix not applied"
    test_status=1
fi

# Check that App.hs uses resolveHost
echo "Checking src/PostgREST/App.hs uses resolveHost..."
if grep -q "resolveHost" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses resolveHost"
else
    echo "✗ App.hs does not use resolveHost - fix not applied"
    test_status=1
fi

# Check that Admin.hs imports PostgREST.Network
echo "Checking src/PostgREST/Admin.hs imports PostgREST.Network..."
if grep -q "import.*PostgREST.Network" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs imports PostgREST.Network"
else
    echo "✗ Admin.hs does not import PostgREST.Network - fix not applied"
    test_status=1
fi

# Check that Admin.hs uses resolveHost
echo "Checking src/PostgREST/Admin.hs uses resolveHost..."
if grep -q "resolveHost" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs uses resolveHost"
else
    echo "✗ Admin.hs does not use resolveHost - fix not applied"
    test_status=1
fi

# Check that postgrest.cabal includes PostgREST.Network module
echo "Checking postgrest.cabal includes PostgREST.Network module..."
if grep -q "PostgREST.Network" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PostgREST.Network module"
else
    echo "✗ postgrest.cabal does not include PostgREST.Network - fix not applied"
    test_status=1
fi

# Check that postgrest.cabal includes iproute dependency
echo "Checking postgrest.cabal includes iproute dependency..."
if grep -q "iproute" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes iproute dependency"
else
    echo "✗ postgrest.cabal does not include iproute - fix not applied"
    test_status=1
fi

# Check that Observation.hs has updated AdminStartObs signature
echo "Checking src/PostgREST/Observation.hs has updated AdminStartObs signature..."
if grep -q "AdminStartObs.*Text" "src/PostgREST/Observation.hs"; then
    echo "✓ AdminStartObs has Text parameter for resolved host"
else
    echo "✗ AdminStartObs signature not updated - fix not applied"
    test_status=1
fi

# Check that Observation.hs has updated AppServerPortObs signature
echo "Checking src/PostgREST/Observation.hs has updated AppServerPortObs signature..."
if grep -q "AppServerPortObs.*Text" "src/PostgREST/Observation.hs"; then
    echo "✓ AppServerPortObs has Text parameter for resolved host"
else
    echo "✗ AppServerPortObs signature not updated - fix not applied"
    test_status=1
fi

# Check that CHANGELOG mentions the resolved host logging fix
echo "Checking CHANGELOG.md mentions resolved host logging fix..."
if grep -q "3560" "CHANGELOG.md" && grep -q "resolved host" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions resolved host logging fix"
else
    echo "✗ CHANGELOG does not mention fix - not documented"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - resolved host logging fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
