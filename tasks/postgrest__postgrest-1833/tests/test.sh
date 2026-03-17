#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #1833 which refactors DbStructure to remove pgVersion and support multiple foreign keys
# HEAD state (549707ad08a8a6be500801edcf1869a4eded7b1e) = pgVersion removed from DbStructure, stored in AppState - FIXED
# BASE state (with bug.patch) = pgVersion inside DbStructure - BUGGY
# ORACLE state (BASE + fix.patch) = pgVersion removed from DbStructure - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for pgVersion and FK refactor)..."
echo ""

echo "Checking that App.hs imports PgVersion..."
if grep -q "^import PostgREST.DbStructure.PgVersion" "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports PgVersion - fix applied!"
else
    echo "✗ App.hs doesn't import PgVersion - fix not applied"
    test_status=1
fi

echo "Checking that RequestContext has ctxPgVersion field..."
if grep -q "ctxPgVersion.*::.*PgVersion" "src/PostgREST/App.hs"; then
    echo "✓ RequestContext has ctxPgVersion - fix applied!"
else
    echo "✗ RequestContext doesn't have ctxPgVersion - fix not applied"
    test_status=1
fi

echo "Checking that DbStructure doesn't have pgVersion field..."
if ! grep -q "pgVersion.*::.*PgVersion" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure doesn't have pgVersion field - fix applied!"
else
    echo "✗ DbStructure still has pgVersion field - fix not applied"
    test_status=1
fi

echo "Checking that AppState exports getPgVersion..."
if grep -q "getPgVersion" "src/PostgREST/AppState.hs" && grep -q "putPgVersion" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState exports getPgVersion/putPgVersion - fix applied!"
else
    echo "✗ AppState missing getPgVersion/putPgVersion - fix not applied"
    test_status=1
fi

echo "Checking that Column doesn't have colFK field..."
if ! grep -q "colFK.*::.*Maybe ForeignKey" "src/PostgREST/DbStructure/Table.hs"; then
    echo "✓ Column doesn't have colFK field - fix applied!"
else
    echo "✗ Column still has colFK field - fix not applied"
    test_status=1
fi

echo "Checking that ForeignKey newtype doesn't exist..."
if ! grep -q "newtype ForeignKey" "src/PostgREST/DbStructure/Table.hs"; then
    echo "✓ ForeignKey newtype removed - fix applied!"
else
    echo "✗ ForeignKey newtype still exists - fix not applied"
    test_status=1
fi

echo "Checking that test/Main.hs uses AppState.putPgVersion..."
if grep -q "AppState.putPgVersion" "test/Main.hs"; then
    echo "✓ test/Main.hs uses AppState.putPgVersion - fix applied!"
else
    echo "✗ test/Main.hs doesn't use AppState.putPgVersion - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
