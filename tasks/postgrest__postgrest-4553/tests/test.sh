#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #4553 which fixes hasSingleUnnamedParam incorrectly matching functions with named parameters

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "Fix \`hasSingleUnnamedParam\` incorrectly matching functions with named parameters" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Plan.hs has the fix (checks ppName == mempty)..."
if grep -q "ppName == mempty" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs checks ppName == mempty - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs missing ppName check - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that hasSingleUnnamedParam includes ppName in pattern match..."
if grep -q "hasSingleUnnamedParam Function{pdParams=\[RoutineParam{ppName, ppType}\]}" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs pattern matches ppName - fix applied!"
else
    echo "✗ src/PostgREST/Plan.hs does not pattern match ppName - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/RpcSpec.hs has the test for named param rejection..."
if grep -q "rejects json body when single param has a name" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs has named param test - fix applied!"
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs missing named param test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/Feature/Query/RpcSpec.hs tests for PGRST202 error code..."
if grep -q '"code":"PGRST202"' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs tests for PGRST202 - fix applied!"
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs does not test for PGRST202 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test/spec/fixtures/schema.sql defines named_json_param function..."
if grep -q "create or replace function test.named_json_param(data json)" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql defines named_json_param - fix applied!"
else
    echo "✗ test/spec/fixtures/schema.sql missing named_json_param - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
