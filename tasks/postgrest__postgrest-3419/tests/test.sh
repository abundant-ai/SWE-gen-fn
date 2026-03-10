#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that the O2O relationship case was added to OpenAPI.hs
echo "Checking that O2O relationship case exists in OpenAPI.hs..."
if grep -q 'Relationship{relCardinality=(O2O _ relColumns)}' "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ O2O relationship case found in OpenAPI.hs - fix applied!"
else
    echo "✗ O2O relationship case not found in OpenAPI.hs - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that O2O case checks relColumns..."
if grep -A 1 'Relationship{relCardinality=(O2O _ relColumns)}' "src/PostgREST/Response/OpenAPI.hs" | grep -q '\[colName col\] == (fst <\$> relColumns)'; then
    echo "✓ O2O case properly checks relColumns - fix applied!"
else
    echo "✗ O2O case does not properly check relColumns - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
