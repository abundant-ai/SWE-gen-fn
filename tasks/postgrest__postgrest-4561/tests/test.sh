#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for hasSingleUnnamedParam matching functions with named parameters (PR #4561)..."
echo ""
echo "NOTE: This PR fixes hasSingleUnnamedParam to correctly check if parameter is unnamed"
echo "BASE (buggy) incorrectly matches functions with named params (e.g., named_json_param(data json))"
echo "HEAD (fixed) only matches truly unnamed params, returning clean PGRST202 error for named params"
echo ""

# Check that hasSingleUnnamedParam requires ppName == mempty (parameter name is empty)
echo "Checking src/PostgREST/Plan.hs includes ppName check in hasSingleUnnamedParam..."
if grep -A 8 "hasSingleUnnamedParam Function{pdParams=\[RoutineParam{" "src/PostgREST/Plan.hs" | grep "ppName" | grep -q "== mempty"; then
    echo "✓ hasSingleUnnamedParam checks ppName == mempty"
else
    echo "✗ hasSingleUnnamedParam does not check ppName - fix not applied"
    test_status=1
fi

# Check that ppName is included in the pattern match
echo "Checking hasSingleUnnamedParam pattern includes ppName..."
if grep "hasSingleUnnamedParam Function{pdParams=\[RoutineParam{" "src/PostgREST/Plan.hs" | grep -q "ppName"; then
    echo "✓ hasSingleUnnamedParam pattern includes ppName"
else
    echo "✗ hasSingleUnnamedParam pattern does not include ppName - fix not applied"
    test_status=1
fi

# Check that CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the hasSingleUnnamedParam fix..."
if grep -q "#4553" "CHANGELOG.md" && grep -q "hasSingleUnnamedParam" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the hasSingleUnnamedParam fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

# Check that CHANGELOG explains the fix for named parameters
echo "Checking CHANGELOG explains fix for named parameters..."
if grep -A 2 "hasSingleUnnamedParam" "CHANGELOG.md" | grep -q "named parameter"; then
    echo "✓ CHANGELOG explains the named parameter fix"
else
    echo "✗ CHANGELOG does not explain named parameter fix - fix not applied"
    test_status=1
fi

# Check that test includes named_json_param test case
echo "Checking test/spec/Feature/Query/RpcSpec.hs includes named_json_param test..."
if grep -q "named_json_param" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec includes named_json_param test"
else
    echo "✗ RpcSpec does not include named_json_param test - fix not applied"
    test_status=1
fi

# Check that test expects PGRST202 error for named param
echo "Checking test expects PGRST202 error for named json parameter..."
if grep -A 5 "named_json_param" "test/spec/Feature/Query/RpcSpec.hs" | grep -q "PGRST202"; then
    echo "✓ Test expects PGRST202 error for named parameter"
else
    echo "✗ Test does not expect PGRST202 error - fix not applied"
    test_status=1
fi

# Check that schema.sql defines named_json_param function
echo "Checking test/spec/fixtures/schema.sql defines named_json_param function..."
if grep -q "named_json_param(data json)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql defines named_json_param function"
else
    echo "✗ schema.sql does not define named_json_param function - fix not applied"
    test_status=1
fi

# Check that unnamed_json_param still exists (should not be removed)
echo "Checking schema.sql still has unnamed_json_param function..."
if grep -q "unnamed_json_param(json)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql still has unnamed_json_param function"
else
    echo "✗ schema.sql missing unnamed_json_param function - incorrect change"
    test_status=1
fi

# Check that test description mentions rejects for named param
echo "Checking test describes rejection of named parameter..."
if grep -B 1 "named_json_param" "test/spec/Feature/Query/RpcSpec.hs" | grep -qi "reject.*name\|name.*param"; then
    echo "✓ Test description mentions rejection of named parameter"
else
    echo "✗ Test description does not mention rejection - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - hasSingleUnnamedParam fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
