#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for character and bit columns with fixed length not inserting/updating properly..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2861, Fix character and bit columns with fixed length not inserting/updating properly' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs has the proper data_type and nominal_data_type columns
echo "Checking src/PostgREST/SchemaCache.hs for proper format_type handling..."
if grep -q 'format_type(a.atttypid, a.atttypmod)::text AS nominal_data_type' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has nominal_data_type field"
else
    echo "✗ SchemaCache.hs missing nominal_data_type field - fix not applied"
    test_status=1
fi

# Check that the query uses nominal_data_type in the select
echo "Checking src/PostgREST/SchemaCache.hs for nominal_data_type in query..."
if grep -q 'info.nominal_data_type,' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs query uses nominal_data_type"
else
    echo "✗ SchemaCache.hs query missing nominal_data_type - fix not applied"
    test_status=1
fi

# Check that the test files have the bit and char tests
echo "Checking test/spec/Feature/Query/InsertSpec.hs for bit/char insert tests..."
if grep -q 'bit and char columns with length' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has bit/char column tests"
else
    echo "✗ InsertSpec.hs missing bit/char column tests - fix not applied"
    test_status=1
fi

if grep -q 'should insert to a bit column with length' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has bit insert test"
else
    echo "✗ InsertSpec.hs missing bit insert test - fix not applied"
    test_status=1
fi

if grep -q 'should insert to a char column with length' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has char insert test"
else
    echo "✗ InsertSpec.hs missing char insert test - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/UpdateSpec.hs for bit/char update tests..."
if grep -q 'bit and char columns with length' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has bit/char column tests"
else
    echo "✗ UpdateSpec.hs missing bit/char column tests - fix not applied"
    test_status=1
fi

if grep -q 'should update a bit column with length' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has bit update test"
else
    echo "✗ UpdateSpec.hs missing bit update test - fix not applied"
    test_status=1
fi

if grep -q 'should update a char column with length' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has char update test"
else
    echo "✗ UpdateSpec.hs missing char update test - fix not applied"
    test_status=1
fi

# Check schema.sql has the bitchar_with_length table
echo "Checking test/spec/fixtures/schema.sql for bitchar_with_length table..."
if grep -q 'CREATE TABLE bitchar_with_length' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bitchar_with_length table"
else
    echo "✗ schema.sql missing bitchar_with_length table - fix not applied"
    test_status=1
fi

if grep -q 'bit bit(5)' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has bit(5) column"
else
    echo "✗ schema.sql missing bit(5) column - fix not applied"
    test_status=1
fi

if grep -q 'char char(5)' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has char(5) column"
else
    echo "✗ schema.sql missing char(5) column - fix not applied"
    test_status=1
fi

# Check data.sql has the test data
echo "Checking test/spec/fixtures/data.sql for bitchar_with_length test data..."
if grep -q "TRUNCATE TABLE bitchar_with_length CASCADE" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has bitchar_with_length data"
else
    echo "✗ data.sql missing bitchar_with_length data - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
