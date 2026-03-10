#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for function parameters of type character and bit not ignoring length..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#1586, Fix function parameters of type character and bit not ignoring length' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that ppTypeMaxLength field was added to RoutineParam
echo "Checking src/PostgREST/SchemaCache/Routine.hs for ppTypeMaxLength field..."
if grep -q 'ppTypeMaxLength :: Text' "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ RoutineParam has ppTypeMaxLength field"
else
    echo "✗ RoutineParam missing ppTypeMaxLength field - fix not applied"
    test_status=1
fi

# Check that ppTypeMaxLength is used in QueryBuilder
echo "Checking src/PostgREST/Query/QueryBuilder.hs for ppTypeMaxLength usage..."
if grep -q 'ppTypeMaxLength p' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses ppTypeMaxLength"
else
    echo "✗ QueryBuilder.hs does not use ppTypeMaxLength - fix not applied"
    test_status=1
fi

# Check that RoutineParam constructor was updated in OpenAPI.hs
echo "Checking src/PostgREST/Response/OpenAPI.hs for updated RoutineParam pattern match..."
if grep -q 'makeProcProperty (RoutineParam n t _ _ _)' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has updated RoutineParam pattern match in makeProcProperty"
else
    echo "✗ OpenAPI.hs missing updated pattern match in makeProcProperty - fix not applied"
    test_status=1
fi

if grep -q 'makeProcGetParam (RoutineParam n t _ r v)' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has updated RoutineParam pattern match in makeProcGetParam"
else
    echo "✗ OpenAPI.hs missing updated pattern match in makeProcGetParam - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs was updated to decode the ppTypeMaxLength field
echo "Checking src/PostgREST/SchemaCache.hs for ppTypeMaxLength decoding..."
count=$(grep -A5 'RoutineParam' "src/PostgREST/SchemaCache.hs" | grep -c 'compositeField HD.text')
if [ "$count" -ge 3 ]; then
    echo "✓ SchemaCache.hs has correct number of text fields for RoutineParam"
else
    echo "✗ SchemaCache.hs missing ppTypeMaxLength field in decoder - fix not applied"
    test_status=1
fi

# Check that the SQL query was updated to include the type conversion CASE statement
echo "Checking src/PostgREST/SchemaCache.hs for type conversion CASE statement..."
if grep -q "WHEN 'character'::regtype THEN 'character varying'" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has character type conversion in SQL"
else
    echo "✗ SchemaCache.hs missing character type conversion in SQL - fix not applied"
    test_status=1
fi

if grep -q "WHEN 'bit'::regtype THEN 'bit varying'" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has bit type conversion in SQL"
else
    echo "✗ SchemaCache.hs missing bit type conversion in SQL - fix not applied"
    test_status=1
fi

# Check that the test file RpcSpec.hs was NOT updated to remove char/bit param tests
# (The bug.patch removes these tests, the fix.patch adds them back)
echo "Checking test/spec/Feature/Query/RpcSpec.hs for char/bit parameter tests..."
if grep -q 'char_param_select' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has char_param_select test"
else
    echo "✗ RpcSpec.hs missing char_param_select test - fix not applied"
    test_status=1
fi

if grep -q 'bit_param_select' "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has bit_param_select test"
else
    echo "✗ RpcSpec.hs missing bit_param_select test - fix not applied"
    test_status=1
fi

# Check that the test file UpdateSpec.hs does NOT have the select parameter (it was removed by the bug fix PR #2861)
# Note: The select parameter removal is unrelated to PR #2867, but the test file is copied from HEAD
echo "Checking test/spec/Feature/Query/UpdateSpec.hs for test format..."
if grep -q 'request methodPatch "/bitchar_with_length?char=eq.aaaaa"' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has expected test format"
else
    echo "Note: UpdateSpec.hs test format check (informational only)"
fi

# Check that schema.sql has the updated table definition with array columns
echo "Checking test/spec/fixtures/schema.sql for bitchar_with_length table with arrays..."
if grep -q 'bit_arr bit(5)\[\]' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bitchar_with_length table with bit_arr column"
else
    echo "✗ schema.sql missing bit_arr column in bitchar_with_length table - fix not applied"
    test_status=1
fi

if grep -q 'char_arr char(5)\[\]' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bitchar_with_length table with char_arr column"
else
    echo "✗ schema.sql missing char_arr column in bitchar_with_length table - fix not applied"
    test_status=1
fi

# Check that schema.sql has the char_param_select function
echo "Checking test/spec/fixtures/schema.sql for char_param_select function..."
if grep -q 'char_param_select' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has char_param_select function"
else
    echo "✗ schema.sql missing char_param_select function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
