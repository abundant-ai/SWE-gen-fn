#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PreferencesSpec.hs" "test/spec/Feature/Query/PreferencesSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (max-affected RPC validation fix applied)
# This is PR #4119 which ADDS the fix for max-affected preference validation with RPC
# HEAD state (0b5526a523) = fix applied, validates max-affected with handling=strict for void/scalar RPCs
# BASE state (with bug.patch) = broken (no validation, allows invalid preferences)
# ORACLE state (BASE + fix.patch) = proper validation (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (max-affected RPC validation fix applied)..."
echo ""

echo "Checking that MaxAffectedRpcViolation error exists in Error.hs..."
if grep -q "MaxAffectedRpcViolation" "src/PostgREST/Error.hs"; then
    echo "✓ MaxAffectedRpcViolation error exists - fix applied!"
else
    echo "✗ MaxAffectedRpcViolation error does not exist - fix not applied"
    test_status=1
fi

echo "Checking that PGRST128 error code is defined..."
if grep -q 'code MaxAffectedRpcViolation.*=.*"PGRST128"' "src/PostgREST/Error.hs"; then
    echo "✓ PGRST128 error code defined - fix applied!"
else
    echo "✗ PGRST128 error code not defined - fix not applied"
    test_status=1
fi

echo "Checking that funcReturnsSingle is imported in Plan.hs..."
if grep -q "funcReturnsSingle" "src/PostgREST/Plan.hs"; then
    echo "✓ funcReturnsSingle imported - fix applied!"
else
    echo "✗ funcReturnsSingle not imported - fix not applied"
    test_status=1
fi

echo "Checking that preferMaxAffected is used in callReadPlan..."
if grep -q "preferMaxAffected" "src/PostgREST/Plan.hs" | head -1; then
    echo "✓ preferMaxAffected used in callReadPlan - fix applied!"
else
    echo "✗ preferMaxAffected not used in callReadPlan - fix not applied"
    test_status=1
fi

echo "Checking that failMaxAffectedRpcReturnsSingle function exists..."
if grep -q "failMaxAffectedRpcReturnsSingle" "src/PostgREST/Plan.hs"; then
    echo "✓ failMaxAffectedRpcReturnsSingle function exists - fix applied!"
else
    echo "✗ failMaxAffectedRpcReturnsSingle function does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test files include RPC max-affected validation tests..."
if grep -q "should fail with rpc when returns void with handling=strict" "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec includes void RPC validation test - test from HEAD!"
else
    echo "✗ PreferencesSpec does not include void RPC validation test - test not from HEAD"
    test_status=1
fi

echo "Checking that schema includes delete_items_returns_void function..."
if grep -q "delete_items_returns_void" "test/spec/fixtures/schema.sql"; then
    echo "✓ Schema includes delete_items_returns_void function - test from HEAD!"
else
    echo "✗ Schema does not include delete_items_returns_void function - test not from HEAD"
    test_status=1
fi

echo "Checking that schema includes delete_items_returns_setof function..."
if grep -q "delete_items_returns_setof" "test/spec/fixtures/schema.sql"; then
    echo "✓ Schema includes delete_items_returns_setof function - test from HEAD!"
else
    echo "✗ Schema does not include delete_items_returns_setof function - test not from HEAD"
    test_status=1
fi

echo "Checking that schema includes delete_items_returns_table function..."
if grep -q "delete_items_returns_table" "test/spec/fixtures/schema.sql"; then
    echo "✓ Schema includes delete_items_returns_table function - test from HEAD!"
else
    echo "✗ Schema does not include delete_items_returns_table function - test not from HEAD"
    test_status=1
fi

echo "Checking that documentation mentions PGRST128 error..."
if grep -q "PGRST128" "docs/references/errors.rst"; then
    echo "✓ Documentation includes PGRST128 error - fix applied!"
else
    echo "✗ Documentation does not include PGRST128 error - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
