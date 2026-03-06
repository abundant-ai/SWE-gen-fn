#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4019 which fixes JWT cache invalidation on config reload
# HEAD state (369fb28c) = fix applied, has JWT cache purging logic
# BASE state (with bug.patch) = no JWT cache purging, uses AppConfig{..} pattern
# ORACLE state (BASE + fix.patch) = has JWT cache purging logic and updated test file

test_status=0

echo "Verifying source code matches HEAD state (JWT cache purging on config reload)..."
echo ""

echo "Checking that CHANGELOG.md has JWT cache fix entry..."
if grep -q "#4014, Fix JWT cache allows old tokens after the jwt-secret is changed in a config reload" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has JWT cache fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have JWT cache fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs uses 'conf <- getConfig appState' pattern..."
if grep -q "conf <- getConfig appState" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses conf binding - fix applied!"
else
    echo "✗ AppState.hs does not use conf binding - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs has JWT cache purging logic..."
if grep -q "C.purge (getJwtCache appState)" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has JWT cache purging - fix applied!"
else
    echo "✗ AppState.hs does not have JWT cache purging - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs compares old and new jwt-secret..."
if grep -q "if configJwtSecret conf == configJwtSecret newConf then" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs compares jwt-secret before purging cache - fix applied!"
else
    echo "✗ AppState.hs does not compare jwt-secret - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs has comment about jwt-secret changing..."
if grep -q "After the config has reloaded, jwt-secret might have changed" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs has explanatory comment - fix applied!"
else
    echo "✗ AppState.hs does not have explanatory comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has test_invalidate_jwt_cache_when_secret_changes test..."
if grep -q "def test_invalidate_jwt_cache_when_secret_changes" "test/io/test_io.py"; then
    echo "✓ test_io.py has JWT cache invalidation test - fix applied!"
else
    echo "✗ test_io.py does not have JWT cache invalidation test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that JWT cache test verifies cache emptying..."
if grep -q "JWT cache should be emptied after jwt-secret is changed in a config reload" "test/io/test_io.py"; then
    echo "✓ test_io.py has correct test description - fix applied!"
else
    echo "✗ test_io.py does not have correct test description - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
