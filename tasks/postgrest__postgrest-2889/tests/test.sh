#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for RECORD and SET OF RECORD return types..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2881, Fix error when a function returns `RECORD` or `SET OF RECORD`' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs has the correct SELECT statement for scalar returns
echo "Checking src/PostgREST/Query/QueryBuilder.hs for correct SELECT statement..."
if grep -q 'if returnsScalar || returnsSetOfScalar then "pgrst_call\.pgrst_scalar"' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has correct SELECT pgrst_call.pgrst_scalar"
else
    echo "✗ QueryBuilder.hs missing correct SELECT statement - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs has the callIt clause for scalar returns
echo "Checking src/PostgREST/Query/QueryBuilder.hs for callIt scalar clause..."
if grep -q 'returnsScalar || returnsSetOfScalar.*SELECT.*pgrst_scalar.*pgrst_call' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has callIt scalar clause"
else
    echo "✗ QueryBuilder.hs missing callIt scalar clause - fix not applied"
    test_status=1
fi

# Check test file HAS the test cases (they should be present after fix is applied)
echo "Checking test/spec/Feature/Query/RpcSpec.hs for test cases..."
if grep -q 'returns a record type' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has test cases"
else
    echo "✗ RpcSpec.hs missing test cases - fix not applied"
    test_status=1
fi

if grep -q 'returns a setof record type' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has setof record test cases"
else
    echo "✗ RpcSpec.hs missing setof record test cases - fix not applied"
    test_status=1
fi

# Check schema.sql HAS the functions (they should be present after fix is applied)
echo "Checking test/spec/fixtures/schema.sql for functions..."
if grep -q 'returns_record()' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has returns_record function"
else
    echo "✗ schema.sql missing returns_record function - fix not applied"
    test_status=1
fi

if grep -q 'returns_setof_record()' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has returns_setof_record function"
else
    echo "✗ schema.sql missing returns_setof_record function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
