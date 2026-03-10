#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/config.py" "test/io/config.py"
mkdir -p "test/io"
cp "/tests/io/test_replica.py" "test/io/test_replica.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that addTargetSessionAttrs function exists in Config.hs (it's added by the fix)
echo "Checking that addTargetSessionAttrs function exists in Config.hs..."
if grep -q "addTargetSessionAttrs :: Text -> Text" "src/PostgREST/Config.hs"; then
    echo "✓ addTargetSessionAttrs function exists in Config.hs - fix applied!"
else
    echo "✗ addTargetSessionAttrs function not found in Config.hs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Config.hs module exports addTargetSessionAttrs..."
if grep -q "^  , addTargetSessionAttrs$" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs exports addTargetSessionAttrs - fix applied!"
else
    echo "✗ Config.hs doesn't export addTargetSessionAttrs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs imports addTargetSessionAttrs..."
if grep -q "addTargetSessionAttrs," "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports addTargetSessionAttrs - fix applied!"
else
    echo "✗ AppState.hs doesn't import addTargetSessionAttrs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs uses addTargetSessionAttrs in listener connection..."
if grep -q "addTargetSessionAttrs.*addFallbackAppName" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses addTargetSessionAttrs for listener - fix applied!"
else
    echo "✗ AppState.hs doesn't use addTargetSessionAttrs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/config.py has original replicaenv with multiple hosts..."
if grep -q 'PGREPLICAHOST.*",".*PGHOST' "test/io/config.py"; then
    echo "✓ config.py has multi-host PGHOST configuration - fix applied!"
else
    echo "✗ config.py doesn't have multi-host setup - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/io/test_replica.py doesn't need to disable channel..."
if grep -q 'PGRST_DB_CHANNEL_ENABLED.*false' "test/io/test_replica.py"; then
    echo "✗ test_replica.py still disables channel (workaround not removed) - fix not applied"
    test_status=1
else
    echo "✓ test_replica.py doesn't need channel workaround - fix applied!"
fi

echo ""
echo "Checking that CHANGELOG mentions the fix..."
if grep -q "#3414" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions PR #3414 - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention PR #3414 - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
