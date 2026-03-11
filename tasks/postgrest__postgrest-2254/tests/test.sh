#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"

test_status=0

echo "Verifying fix for primary key inference on views (PR #2254)..."
echo ""
echo "NOTE: This PR removes standalone tablePKCols function and moves PK columns to Table structure"
echo "We verify that the source code has the fix."
echo ""

echo "Checking DbStructure.hs does NOT export standalone tablePKCols function..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q "^  , tablePKCols" "src/PostgREST/DbStructure.hs"; then
    echo "✗ DbStructure.hs still exports tablePKCols function (not fixed)"
    test_status=1
else
    echo "✓ DbStructure.hs does not export tablePKCols function"
fi

echo "Checking App.hs does NOT import tablePKCols from DbStructure..."
if [ -f "src/PostgREST/App.hs" ] && grep -q "findIfView, tablePKCols" "src/PostgREST/App.hs"; then
    echo "✗ App.hs still imports tablePKCols (not fixed)"
    test_status=1
else
    echo "✓ App.hs does not import tablePKCols from DbStructure"
fi

echo "Checking App.hs uses tablePKCols from Table structure (not as standalone function)..."
if [ -f "src/PostgREST/App.hs" ] && grep -q "maybe mempty tablePKCols.*M.lookup identifier" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses tablePKCols from Table structure"
else
    echo "✗ App.hs does not use tablePKCols from Table structure (not fixed)"
    test_status=1
fi

echo "Checking DbStructure.hs does NOT have dbPrimaryKeys field..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q ", dbPrimaryKeys" "src/PostgREST/DbStructure.hs"; then
    echo "✗ DbStructure.hs still has dbPrimaryKeys field (not fixed)"
    test_status=1
else
    echo "✓ DbStructure.hs does not have dbPrimaryKeys field"
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking RootSpec.hs was copied..."
if [ -f "test/spec/Feature/OpenApi/RootSpec.hs" ]; then
    echo "✓ RootSpec.hs exists (HEAD version)"
else
    echo "✗ RootSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking InsertSpec.hs was copied..."
if [ -f "test/spec/Feature/Query/InsertSpec.hs" ]; then
    echo "✓ InsertSpec.hs exists (HEAD version)"
else
    echo "✗ InsertSpec.hs not found - HEAD file not copied!"
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
