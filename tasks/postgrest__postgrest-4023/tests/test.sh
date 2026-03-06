#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/load"
cp "/tests/load/fixtures.sql" "test/load/fixtures.sql"
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"

# Verify source code matches HEAD state (fix applied)
# This is PR #4023 which adds JWT loadtest support and fixes loadtest report generation
# HEAD state (6a926e38) = fix applied, has JWT loadtest feature
# BASE state (with bug.patch) = no JWT loadtest feature, simplified code
# ORACLE state (BASE + fix.patch) = has JWT loadtest feature and updated test files

test_status=0

echo "Verifying source code matches HEAD state (JWT loadtest feature)..."
echo ""

echo "Checking that .gitignore has gen_targets.http entry..."
if grep -q "test/load/gen_targets.http" ".gitignore"; then
    echo "✓ .gitignore has gen_targets.http entry - fix applied!"
else
    echo "✗ .gitignore does not have gen_targets.http entry - fix not applied"
    test_status=1
fi

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
if grep -q "def generate_jwt() -> str:" "nix/tools/generate_targets.py" 2>/dev/null; then
    echo "✓ generate_targets.py has JWT generation - fix applied!"
else
    echo "✗ generate_targets.py does not have JWT generation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has kind parameter support..."
if grep -q 'ARG_OPTIONAL_SINGLE(\[kind\], \[k\]' "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has kind parameter - fix applied!"
else
    echo "✗ loadtest.nix does not have kind parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has jwt case in switch..."
if grep -q "jwt)" "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has jwt case - fix applied!"
else
    echo "✗ loadtest.nix does not have jwt case - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix has genTargets reference..."
if grep -q 'genTargets = writers.writePython3' "nix/tools/loadtest.nix"; then
    echo "✓ loadtest.nix has genTargets - fix applied!"
else
    echo "✗ loadtest.nix does not have genTargets - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that loadtest.nix does NOT have -duration 60s in runner definition..."
if ! grep -A 2 "runner =" "nix/tools/loadtest.nix" | grep -q -- "-duration 60s"; then
    echo "✓ loadtest.nix removed -duration from runner - fix applied!"
else
    echo "✗ loadtest.nix still has -duration in runner - fix not applied"
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
echo "Checking that memory-tests.sh has correct 10M PATCH threshold (50M not 32M)..."
if grep -q 'jsonKeyTest "10M" "PATCH" "/leak?id=eq.1&columns=blob" "50M"' "test/memory/memory-tests.sh"; then
    echo "✓ memory-tests.sh has 50M threshold for 10M PATCH - fix applied!"
else
    echo "✗ memory-tests.sh does not have 50M threshold - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
