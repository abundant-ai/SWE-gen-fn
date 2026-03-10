#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that the SchemaCache.hs has the simplified pks_uniques_cols CTE
echo "Checking that SchemaCache.hs uses simplified array_agg(key order by key)..."
if grep -q "array_agg(key order by key) as cols" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses simplified array_agg - fix applied!"
else
    echo "✗ SchemaCache.hs missing simplified array_agg - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs uses simple LATERAL unnest..."
if grep -q "LATERAL unnest(conkey) AS _(key)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses LATERAL unnest - fix applied!"
else
    echo "✗ SchemaCache.hs doesn't use LATERAL unnest - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that one_to_one detection uses simplified subquery..."
if grep -q "column_info.cols IN (SELECT cols FROM pks_uniques_cols WHERE conrelid = traint.conrelid)" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses simplified subquery for one_to_one detection - fix applied!"
else
    echo "✗ SchemaCache.hs doesn't use simplified subquery - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that the foreign key column order is fixed in schema.sql..."
if grep -q "foreign key (code, id) references test.students(code, id)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has correct foreign key column order - fix applied!"
else
    echo "✗ schema.sql has wrong foreign key column order - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
