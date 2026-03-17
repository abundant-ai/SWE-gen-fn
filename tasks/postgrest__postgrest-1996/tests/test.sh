#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/RpcSpec.hs" "test/Feature/RpcSpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #1996 which adds fallback logic for single unnamed JSON parameters
# HEAD state (5cf9f379fadb31d29af9ed274433534aed7a1cd4) = fallback logic present (single unnamed params work)
# BASE state (with bug.patch) = fallback logic removed (returns 300 Multiple Choices) - BUGGY
# ORACLE state (BASE + fix.patch) = fallback logic restored (single unnamed params work) - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fallback logic for single unnamed JSON params)..."
echo ""

echo "Checking that CHANGELOG does NOT mention the overload resolution issue..."
if grep -q "#1927, Overloaded Functions: If there's a function \"my_func\" having a single unnamed json param and other overloaded pairs" "CHANGELOG.md"; then
    echo "✗ CHANGELOG mentions issue - fix not applied"
    test_status=1
else
    echo "✓ CHANGELOG clean - fix applied!"
fi

echo "Checking that ApiRequest.hs uses overloadedProcPartition function..."
if grep -q "overloadedProcPartition" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ overloadedProcPartition function present - fix applied!"
else
    echo "✗ overloadedProcPartition function missing - fix not applied"
    test_status=1
fi

echo "Checking that ApiRequest.hs has hasSingleUnnamedParam function..."
if grep -q "hasSingleUnnamedParam proc = isInvPost" "src/PostgREST/Request/ApiRequest.hs"; then
    echo "✓ hasSingleUnnamedParam function present - fix applied!"
else
    echo "✗ hasSingleUnnamedParam function missing - fix not applied"
    test_status=1
fi

echo "Checking that findProc uses partition with fallback..."
if grep -A 8 "case matchProc of" "src/PostgREST/Request/ApiRequest.hs" | grep -q "(\\[\\], \\[\\])"; then
    echo "✓ findProc uses partition pattern - fix applied!"
else
    echo "✗ findProc doesn't use partition pattern - fix not applied"
    test_status=1
fi

echo "Checking that findProc has fallback for single proc..."
if grep -A 8 "case matchProc of" "src/PostgREST/Request/ApiRequest.hs" | grep -q "(\\[\\], \\[proc\\])"; then
    echo "✓ findProc has single proc fallback - fix applied!"
else
    echo "✗ findProc missing single proc fallback - fix not applied"
    test_status=1
fi

echo "Checking that RpcSpec.hs expects overloaded_unnamed_param to work..."
if grep -q "should be able to resolve when a single unnamed json parameter exists and other overloaded functions are found" "test/Feature/RpcSpec.hs"; then
    echo "✓ RpcSpec expects resolution to work - fix applied!"
else
    echo "✗ RpcSpec doesn't expect resolution to work - fix not applied"
    test_status=1
fi

echo "Checking that RpcSpec.hs expects 200 response for empty JSON object..."
if grep -A 10 "should be able to resolve when a single unnamed json parameter exists and other overloaded functions are found" "test/Feature/RpcSpec.hs" | grep -q "matchStatus.*=.*200"; then
    echo "✓ RpcSpec expects 200 for empty object - fix applied!"
else
    echo "✗ RpcSpec doesn't expect 200 - fix not applied"
    test_status=1
fi

echo "Checking that schema.sql has multiple overloaded_unnamed_param variants..."
if grep -q "create or replace function test.overloaded_unnamed_param(bytea)" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has bytea overload - fix applied!"
else
    echo "✗ schema.sql missing bytea overload - fix not applied"
    test_status=1
fi

if grep -q "create or replace function test.overloaded_unnamed_param(text)" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has text overload - fix applied!"
else
    echo "✗ schema.sql missing text overload - fix not applied"
    test_status=1
fi

if grep -q "create or replace function test.overloaded_unnamed_param()" "test/fixtures/schema.sql"; then
    echo "✓ schema.sql has no-param overload - fix applied!"
else
    echo "✗ schema.sql missing no-param overload - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
