#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/OpenApiSpec.hs" "test/spec/Feature/OpenApi/OpenApiSpec.hs"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): No null check for enum, no CHANGELOG entry, no test case
# In HEAD (fix applied): Null check for enum, CHANGELOG entry added, test case added

test_status=0

echo "Verifying Haskell source code changes for empty enum fix..."
echo ""

echo "Checking CHANGELOG.md for PR mention..."
if grep -q "Fix empty enum in \`preferParams\` OpenAPI parameter by @laurenceisla in #4292" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions empty enum fix - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention empty enum fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Response/OpenAPI.hs for null check on enum..."
if grep -q "& enum_ .~ if null enu then Nothing else JSON.decode (JSON.encode enu))" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs has null check for enum - fix is applied!"
else
    echo "✗ OpenAPI.hs does not have null check for enum - fix not applied"
    test_status=1
fi

if grep -q "enu = foldl (<>) \[\] (val <\$> ts)" "src/PostgREST/Response/OpenAPI.hs"; then
    echo "✓ OpenAPI.hs defines enu in where clause - fix is applied!"
else
    echo "✗ OpenAPI.hs does not define enu in where clause - fix not applied"
    test_status=1
fi

echo ""
echo "Checking test/spec/Feature/OpenApi/OpenApiSpec.hs for test case..."
if grep -q "it \"does not include empty enum in the preferParams parameter\" \$ do" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs has test case for empty enum - fix is applied!"
else
    echo "✗ OpenApiSpec.hs does not have test case for empty enum - fix not applied"
    test_status=1
fi

if grep -q "preferParams \`shouldBe\` Nothing" "test/spec/Feature/OpenApi/OpenApiSpec.hs"; then
    echo "✓ OpenApiSpec.hs test expects preferParams to be Nothing - fix is applied!"
else
    echo "✗ OpenApiSpec.hs test does not check for Nothing - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
