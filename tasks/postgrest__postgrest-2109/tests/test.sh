#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

test_status=0

echo "Verifying fix for admin health check endpoints (PR #2109)..."
echo ""
echo "This PR adds /ready and /live admin endpoints that check the main app socket."
echo "The bug was that the admin server didn't verify the main app socket was reachable."
echo "The fix adds PostgREST.Admin module with socket connectivity checks."
echo ""

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#2109.*health check endpoint" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions PR #2109 (admin health endpoints)"
    else
        echo "✗ CHANGELOG.md does not mention PR #2109 (not documented)"
        test_status=1
    fi

    if grep -q "/ready.*endpoint.*checking.*internal state" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md describes /ready endpoint"
    else
        echo "✗ CHANGELOG.md does not describe /ready endpoint"
        test_status=1
    fi

    if grep -q "/live.*endpoint.*postgrest is alive" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md describes /live endpoint"
    else
        echo "✗ CHANGELOG.md does not describe /live endpoint"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking PostgREST.Admin module exists (fix applied)..."
if [ -f "src/PostgREST/Admin.hs" ]; then
    echo "✓ src/PostgREST/Admin.hs exists (module added)"

    if grep -q "postgrestAdmin.*AppState.*AppConfig.*Wai.Application" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin module has postgrestAdmin function"
    else
        echo "✗ postgrestAdmin function not found"
        test_status=1
    fi

    if grep -q '"ready"' "src/PostgREST/Admin.hs"; then
        echo "✓ Admin module handles /ready endpoint"
    else
        echo "✗ /ready endpoint handler not found"
        test_status=1
    fi

    if grep -q '"live"' "src/PostgREST/Admin.hs"; then
        echo "✓ Admin module handles /live endpoint"
    else
        echo "✗ /live endpoint handler not found"
        test_status=1
    fi

    if grep -q "reachMainApp" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin module has reachMainApp function (socket check)"
    else
        echo "✗ reachMainApp function not found"
        test_status=1
    fi

    if grep -q "isMainAppReachable" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin endpoints check main app reachability"
    else
        echo "✗ Main app reachability check not found"
        test_status=1
    fi

    if grep -q "SockAddrUnix" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin module handles Unix domain sockets"
    else
        echo "✗ Unix domain socket handling not found"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Admin.hs not found (module not added)"
    test_status=1
fi

echo ""
echo "Checking postgrest.cabal includes Admin module..."
if [ -f "postgrest.cabal" ]; then
    if grep -q "PostgREST.Admin" "postgrest.cabal"; then
        echo "✓ postgrest.cabal exposes PostgREST.Admin module"
    else
        echo "✗ PostgREST.Admin not in postgrest.cabal"
        test_status=1
    fi

    if grep -q "network.*>=.*2.6.*<.*3.2" "postgrest.cabal"; then
        echo "✓ postgrest.cabal includes network dependency"
    else
        echo "✗ network dependency not found in postgrest.cabal"
        test_status=1
    fi
else
    echo "✗ postgrest.cabal not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test file was copied correctly..."
if [ -f "test/io-tests/test_io.py" ]; then
    echo "✓ test/io-tests/test_io.py exists (HEAD version)"

    if grep -q "test_admin_ready_dependent_on_main_app" "test/io-tests/test_io.py"; then
        echo "✓ Test file has test_admin_ready_dependent_on_main_app test"
    else
        echo "✗ test_admin_ready_dependent_on_main_app test not found"
        test_status=1
    fi

    if grep -q "test_admin_live" "test/io-tests/test_io.py"; then
        echo "✓ Test file has test_admin_live tests"
    else
        echo "✗ test_admin_live tests not found"
        test_status=1
    fi
else
    echo "✗ test/io-tests/test_io.py not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
