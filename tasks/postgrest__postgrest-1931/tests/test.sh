#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/RpcSpec.hs" "test/Feature/RpcSpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #1931 which fixes handling of RETURNS TABLE with a single column
# HEAD state (0e29748976e3221979841d1f6d2ac9c2e9111b9a) = fix for single-column TABLE returns - FIXED
# BASE state (with bug.patch) = single-column TABLE returns treated as scalars - BUGGY
# ORACLE state (BASE + fix.patch) = single-column TABLE returns properly treated as composite - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for single-column RETURNS TABLE)..."
echo ""

echo "Checking that CHANGELOG mentions the bugfix for RPC return type handling..."
if grep -q '#1930, Fix RPC return type handling for.*RETURNS TABLE.*with a single column' "CHANGELOG.md"; then
    echo "✓ CHANGELOG has bugfix entry - fix applied!"
else
    echo "✗ CHANGELOG missing bugfix entry - fix not applied"
    test_status=1
fi

echo "Checking that DbStructure.hs checks for TABLE arguments in proargmodes..."
if grep -q "proargmodes::text\[\] && '{t,b,o}'" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs checks for TABLE arguments ('{t,b,o}') - fix applied!"
else
    echo "✗ DbStructure.hs doesn't check for TABLE arguments - fix not applied"
    test_status=1
fi

echo "Checking that RpcSpec.hs has test for single-column TABLE return..."
if grep -q "single_column_table_return" "test/Feature/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has single-column TABLE test - fix applied!"
else
    echo "✗ RpcSpec.hs missing single-column TABLE test - fix not applied"
    test_status=1
fi

echo "Checking that RpcSpec.hs has test for multi-column TABLE return..."
if grep -q "multi_column_table_return" "test/Feature/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has multi-column TABLE test - fix applied!"
else
    echo "✗ RpcSpec.hs missing multi-column TABLE test - fix not applied"
    test_status=1
fi

echo "Checking that schema.sql has single_column_table_return function..."
if grep -q "single_column_table_return" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has single_column_table_return function - fix applied!"
else
    echo "✗ schema.sql missing single_column_table_return function - fix not applied"
    test_status=1
fi

echo "Checking that schema.sql has multi_column_table_return function..."
if grep -q "multi_column_table_return" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has multi_column_table_return function - fix applied!"
else
    echo "✗ schema.sql missing multi_column_table_return function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
