#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for removing bulk RPC call with Prefer: params=multiple-objects..."
echo ""

# Check CHANGELOG.md has the change entry
echo "Checking CHANGELOG.md has change entry for #2733..."
if grep -q "#2733, Remove bulk RPC call with the" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has #2733 entry"
else
    echo "✗ CHANGELOG.md missing #2733 entry - fix not applied"
    test_status=1
fi

# Check Preferences.hs removed MultipleObjects from parsePrefs
echo "Checking src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects..."
if grep -q "parsePrefs \[SingleObject\]" "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q "parsePrefs \[SingleObject, MultipleObjects\]" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects from parsePrefs"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has MultipleObjects - fix not applied"
    test_status=1
fi

# Check Preferences.hs removed MultipleObjects data constructor
echo "Checking src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects data constructor..."
if ! grep -q "| MultipleObjects -- ^ Pass an array of json objects" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects constructor"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has MultipleObjects constructor - fix not applied"
    test_status=1
fi

# Check Preferences.hs removed MultipleObjects toHeaderValue
echo "Checking src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects toHeaderValue..."
if ! grep -q 'toHeaderValue MultipleObjects = "params=multiple-objects"' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs removed MultipleObjects toHeaderValue"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has MultipleObjects toHeaderValue - fix not applied"
    test_status=1
fi

# Check Preferences.hs removed deprecation TODO comment
echo "Checking src/PostgREST/ApiRequest/Preferences.hs removed deprecation TODO..."
if ! grep -q "TODO: Deprecate params=multiple-objects" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs removed deprecation TODO"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has deprecation TODO - fix not applied"
    test_status=1
fi

# Check Plan.hs imports procReturnsSetOfScalar
echo "Checking src/PostgREST/Plan.hs imports procReturnsSetOfScalar..."
if grep -q "procReturnsSetOfScalar" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs imports procReturnsSetOfScalar"
else
    echo "✗ src/PostgREST/Plan.hs missing procReturnsSetOfScalar import - fix not applied"
    test_status=1
fi

# Check Plan.hs replaced funCMultipleCall with funCSetOfScalar
echo "Checking src/PostgREST/Plan.hs replaced funCMultipleCall with funCSetOfScalar..."
if grep -q "funCSetOfScalar = procReturnsSetOfScalar proc" "src/PostgREST/Plan.hs" && \
   ! grep -q "funCMultipleCall = preferParameters == Just MultipleObjects" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs replaced funCMultipleCall with funCSetOfScalar"
else
    echo "✗ src/PostgREST/Plan.hs not updated correctly - fix not applied"
    test_status=1
fi

# Check Plan.hs binaryField checks procReturnsSetOfScalar
echo "Checking src/PostgREST/Plan.hs binaryField checks procReturnsSetOfScalar..."
if grep -q "(procReturnsSetOfScalar <\$> proc) == Just True" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs binaryField checks procReturnsSetOfScalar"
else
    echo "✗ src/PostgREST/Plan.hs binaryField not updated - fix not applied"
    test_status=1
fi

# Check CallPlan.hs replaced funCMultipleCall with funCSetOfScalar
echo "Checking src/PostgREST/Plan/CallPlan.hs replaced funCMultipleCall with funCSetOfScalar..."
if grep -q "funCSetOfScalar :: Bool" "src/PostgREST/Plan/CallPlan.hs" && \
   ! grep -q "funCMultipleCall :: Bool" "src/PostgREST/Plan/CallPlan.hs"; then
    echo "✓ src/PostgREST/Plan/CallPlan.hs replaced funCMultipleCall with funCSetOfScalar"
else
    echo "✗ src/PostgREST/Plan/CallPlan.hs not updated - fix not applied"
    test_status=1
fi

# Check Query.hs removed PreferParameters import and usage
echo "Checking src/PostgREST/Query.hs removed PreferParameters..."
if ! grep -q "PreferParameters" "src/PostgREST/Query.hs" && \
   grep -q "procReturnsSetOfScalar proc" "src/PostgREST/Query.hs" && \
   grep -q "procReturnsSingleComposite proc" "src/PostgREST/Query.hs"; then
    echo "✓ src/PostgREST/Query.hs removed PreferParameters and uses procReturnsSetOfScalar"
else
    echo "✗ src/PostgREST/Query.hs not updated - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs updated callPlanToQuery signature and implementation
echo "Checking src/PostgREST/Query/QueryBuilder.hs updated callPlanToQuery..."
if grep -q "callPlanToQuery (FunctionCall qi params args returnsScalar returnsSetOfScalar returnings)" "src/PostgREST/Query/QueryBuilder.hs" && \
   grep -q "if returnsScalar || returnsSetOfScalar then" "src/PostgREST/Query/QueryBuilder.hs" && \
   ! grep -q "multipleCall" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs replaced funCMultipleCall with funCSetOfScalar"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs not updated - fix not applied"
    test_status=1
fi

# Check SchemaCache/Proc.hs exports procReturnsSetOfScalar
echo "Checking src/PostgREST/SchemaCache/Proc.hs exports procReturnsSetOfScalar..."
if grep -q "procReturnsSetOfScalar" "src/PostgREST/SchemaCache/Proc.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Proc.hs exports procReturnsSetOfScalar"
else
    echo "✗ src/PostgREST/SchemaCache/Proc.hs not exporting procReturnsSetOfScalar - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
