#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/ConcurrentSpec.hs" "test/spec/Feature/ConcurrentSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #3869 which adds PGRST205 error for non-existing tables
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the table not found fix..."
if grep -q "Handle queries on non-existing table gracefully" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions table not found fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions PGRST205 error..."
if grep -q "PGRST205" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PGRST205 error - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention PGRST205 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst documents PGRST205 error..."
if grep -q "pgrst205" "docs/references/errors.rst" && \
   grep -q "404" "docs/references/errors.rst" | grep -A2 -B2 "pgrst205" "docs/references/errors.rst" | grep -q "404"; then
    echo "✓ errors.rst documents PGRST205 error - fix applied!"
else
    echo "✗ errors.rst does not document PGRST205 properly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs includes TableNotFound error..."
if grep -q "TableNotFound Text Text \[Table\]" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs includes TableNotFound error - fix applied!"
else
    echo "✗ Error.hs missing TableNotFound error - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs includes SchemaCacheErrorCode05..."
if grep -q "SchemaCacheErrorCode05" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs includes SchemaCacheErrorCode05 - fix applied!"
else
    echo "✗ Error.hs missing SchemaCacheErrorCode05 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs includes tableNotFoundHint function..."
if grep -q "tableNotFoundHint" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs includes tableNotFoundHint function - fix applied!"
else
    echo "✗ Error.hs missing tableNotFoundHint function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs includes findTable function..."
if grep -q "findTable ::" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs includes findTable function - fix applied!"
else
    echo "✗ Plan.hs missing findTable function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs calls findTable in wrappedReadPlan..."
if grep -A3 "wrappedReadPlan.*identifier conf sCache apiRequest" "src/PostgREST/Plan.hs" | grep -q "findTable identifier"; then
    echo "✓ Plan.hs calls findTable in wrappedReadPlan - fix applied!"
else
    echo "✗ Plan.hs does not call findTable properly - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
