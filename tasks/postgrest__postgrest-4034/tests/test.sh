#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/load"
cp "/tests/load/fixtures.sql" "test/load/fixtures.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #4034 which adds JWT loadtest functionality
# HEAD state (c087d79f) = fix applied, has generate_targets.py and JWT loadtest support
# BASE state (with bug.patch) = no generate_targets.py, no JWT loadtest kind support
# ORACLE state (BASE + fix.patch) = has generate_targets.py and JWT loadtest support

test_status=0

echo "Verifying source code matches HEAD state (JWT loadtest addition)..."
echo ""

echo "Checking that generate_targets.py exists..."
if [ -f "nix/tools/generate_targets.py" ]; then
    echo "✓ generate_targets.py exists - fix applied!"
else
    echo "✗ generate_targets.py does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that generate_targets.py has JWT generation logic..."
if grep -q "def generate_jwt" "nix/tools/generate_targets.py" 2>/dev/null; then
    echo "✓ generate_targets.py has JWT generation - fix applied!"
else
    echo "✗ generate_targets.py does not have JWT generation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that generate_targets.py generates 50000 targets..."
if grep -q "TOTAL_TARGETS = 50000" "nix/tools/generate_targets.py" 2>/dev/null; then
    echo "✓ generate_targets.py generates 50000 targets - fix applied!"
else
    echo "✗ generate_targets.py does not generate 50000 targets - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that .gitignore has gen_targets.http..."
if grep -q "gen_targets.http" ".gitignore"; then
    echo "✓ .gitignore has gen_targets.http - fix applied!"
else
    echo "✗ .gitignore does not have gen_targets.http - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has JWT loadtest kind support..."
if grep -q 'ARG_OPTIONAL_SINGLE(\[kind\], \[k\], \[Kind of loadtest' "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has JWT loadtest kind support - fix applied!"
else
    echo "✗ loadtest.nix does not have JWT loadtest kind support - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has genTargets variable..."
if grep -q "genTargets = writers.writePython3" "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has genTargets variable - fix applied!"
else
    echo "✗ loadtest.nix does not have genTargets variable - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has jwt case statement..."
if grep -q "case.*_arg_kind.*in" "nix/tools/loadtest.nix" && grep -q "jwt)" "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has jwt case statement - fix applied!"
else
    echo "✗ loadtest.nix does not have jwt case statement - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix calls genTargets..."
if grep -q '\${genTargets}.*gen_targets.http' "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix calls genTargets - fix applied!"
else
    echo "✗ loadtest.nix does not call genTargets - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that fixtures.sql has postgrest_test_author role..."
if grep -q "CREATE ROLE postgrest_test_author" "test/load/fixtures.sql"; then
    echo "✓ fixtures.sql has postgrest_test_author role - fix applied!"
else
    echo "✗ fixtures.sql does not have postgrest_test_author role - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that fixtures.sql has authors_only table..."
if grep -q "CREATE TABLE test.authors_only" "test/load/fixtures.sql"; then
    echo "✓ fixtures.sql has authors_only table - fix applied!"
else
    echo "✗ fixtures.sql does not have authors_only table - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that fixtures.sql grants permissions to postgrest_test_author..."
if grep -q "GRANT ALL ON TABLE authors_only TO postgrest_test_author" "test/load/fixtures.sql"; then
    echo "✓ fixtures.sql grants permissions to postgrest_test_author - fix applied!"
else
    echo "✗ fixtures.sql does not grant permissions to postgrest_test_author - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
