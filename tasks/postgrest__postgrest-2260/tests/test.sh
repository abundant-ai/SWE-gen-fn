#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

test_status=0

echo "Verifying fix for schema introspection optimization (PR #2260)..."
echo ""
echo "NOTE: This PR merges columns into Table struct (tableColumns field) instead of separate dbColumns"
echo "We verify that the source code has the fix."
echo ""

echo "Checking DbStructure.hs does NOT have separate dbColumns field..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "dbColumns" "src/PostgREST/DbStructure.hs"; then
    echo "✗ DbStructure.hs still has dbColumns field (not fixed)"
    test_status=1
else
    echo "✓ DbStructure.hs does not have dbColumns field"
fi

echo "Checking DbStructure.hs does NOT export tableCols function..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "tableCols" "src/PostgREST/DbStructure.hs"; then
    echo "✗ DbStructure.hs still has tableCols function (not fixed)"
    test_status=1
else
    echo "✓ DbStructure.hs does not have tableCols function"
fi

echo "Checking Table.hs has tableColumns field..."
if [ -f "src/PostgREST/DbStructure/Table.hs" ] && grep -q "tableColumns.*::.*\[Column\]" "src/PostgREST/DbStructure/Table.hs"; then
    echo "✓ Table.hs has tableColumns field"
else
    echo "✗ Table.hs missing tableColumns field"
    test_status=1
fi

echo "Checking Table.hs Column does NOT have colTable field..."
if [ -f "src/PostgREST/DbStructure/Table.hs" ] && grep -q "colTable.*::.*Table" "src/PostgREST/DbStructure/Table.hs"; then
    echo "✗ Table.hs Column still has colTable field (not fixed)"
    test_status=1
else
    echo "✓ Table.hs Column does not have colTable field"
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking memory-tests.sh was copied..."
if [ -f "test/memory/memory-tests.sh" ]; then
    echo "✓ memory-tests.sh exists (HEAD version)"
else
    echo "✗ memory-tests.sh not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking OpenApiSpec.hs was copied..."
if [ -f "test/spec/Feature/OpenApi/OpenApiSpec.hs" ]; then
    echo "✓ OpenApiSpec.hs exists (HEAD version)"
else
    echo "✗ OpenApiSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
