#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/create_test_db" "test/create_test_db"
mkdir -p "test/fixtures"
cp "/tests/fixtures/database.sql" "test/fixtures/database.sql"
mkdir -p "test"
cp "/tests/with_tmp_db" "test/with_tmp_db"

# Verify source code matches HEAD state (fix applied)
# This is PR #1827 which refactors test database setup and Nix configuration files
# HEAD state (acccd4968a7d9fe0355a0a7e3f043fc30183358f) = database setup in test/fixtures/database.sql, Nix files refactored - FIXED
# BASE state (with bug.patch) = database setup moved to test scripts, old Nix structure - BUGGY
# ORACLE state (BASE + fix.patch + test files from /tests) = matches HEAD - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for database setup refactoring)..."
echo ""

echo "Checking that test/create_test_db does NOT have pgcrypto setup block..."
if ! grep -q "CREATE EXTENSION IF NOT EXISTS pgcrypto" "test/create_test_db"; then
    echo "✓ test/create_test_db doesn't have pgcrypto extension setup - fix applied!"
else
    echo "✗ test/create_test_db still has pgcrypto extension setup - fix not applied"
    test_status=1
fi

echo "Checking that test/create_test_db does NOT set request.jwt.claim.id..."
if ! grep -q "ALTER DATABASE.*SET request.jwt.claim.id" "test/create_test_db"; then
    echo "✓ test/create_test_db doesn't set request.jwt.claim.id - fix applied!"
else
    echo "✗ test/create_test_db still sets request.jwt.claim.id - fix not applied"
    test_status=1
fi

echo "Checking that test/fixtures/database.sql HAS pgcrypto setup..."
if grep -q "CREATE EXTENSION IF NOT EXISTS pgcrypto" "test/fixtures/database.sql"; then
    echo "✓ test/fixtures/database.sql has pgcrypto setup - fix applied!"
else
    echo "✗ test/fixtures/database.sql doesn't have pgcrypto setup - fix not applied"
    test_status=1
fi

echo "Checking that test/fixtures/database.sql sets database config..."
if grep -q "ALTER DATABASE :DBNAME SET request.jwt.claim.id" "test/fixtures/database.sql"; then
    echo "✓ test/fixtures/database.sql sets database config - fix applied!"
else
    echo "✗ test/fixtures/database.sql doesn't set database config - fix not applied"
    test_status=1
fi

echo "Checking that test/with_tmp_db does NOT have inline fixture setup..."
if ! (grep -q "create extension pgcrypto" "test/with_tmp_db" && grep -q "alter database.*set request.jwt.claim.id" "test/with_tmp_db"); then
    echo "✓ test/with_tmp_db doesn't have inline fixture setup - fix applied!"
else
    echo "✗ test/with_tmp_db still has inline fixture setup - fix not applied"
    test_status=1
fi

echo "Checking that nix/tools/style.nix does NOT include test/with_tmp_db in shellcheck..."
if ! grep -q "shellcheck.*test/with_tmp_db" "nix/tools/style.nix"; then
    echo "✓ nix/tools/style.nix doesn't include test/with_tmp_db in shellcheck - fix applied!"
else
    echo "✗ nix/tools/style.nix still includes test/with_tmp_db in shellcheck - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
