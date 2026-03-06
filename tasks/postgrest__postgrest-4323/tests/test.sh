#!/bin/bash

cd /app/src

# Set CI flag for consistent test behavior
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Old error messages (reverted)
# In HEAD (fix applied): New improved error messages

test_status=0

echo "Verifying Haskell source code changes for schema error message improvements..."
echo ""

echo "Checking CHANGELOG.md for PR mentions..."
if grep -q "Improve the \`PGRST106\` error when the requested schema is invalid" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PGRST106 improvement - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention PGRST106 improvement - fix not applied"
    test_status=1
fi

if grep -q "Improve error details of \`PGRST301\` error" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PGRST301 improvement - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention PGRST301 improvement - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/ApiRequest.hs for UnacceptableSchema with schema parameter..."
if grep -q "UnacceptableSchema p \$ toList configDbSchemas" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes invalid schema to UnacceptableSchema - fix is applied!"
else
    echo "✗ ApiRequest.hs does not pass schema to UnacceptableSchema - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Error.hs for UnacceptableSchema definition..."
if grep -q "| UnacceptableSchema Text \[Text\]" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has UnacceptableSchema with Text parameter - fix is applied!"
else
    echo "✗ Error.hs UnacceptableSchema definition incorrect - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Error.hs for improved error message..."
if grep -q 'message (UnacceptableSchema sch _)   = "Invalid schema: " <> sch' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has improved error message with schema name - fix is applied!"
else
    echo "✗ Error.hs does not have improved error message - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Error.hs for hint field with exposed schemas..."
if grep -q 'hint (UnacceptableSchema _ schemas) = Just \$ JSON.String \$ "Only the following schemas are exposed: "  <> T.intercalate ", " schemas' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has hint field with exposed schemas list - fix is applied!"
else
    echo "✗ Error.hs does not have hint field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking test/spec/Feature/Query/MultipleSchemaSpec.hs for updated test expectations..."
if grep -q 'Invalid schema: unknown' "test/spec/Feature/Query/MultipleSchemaSpec.hs"; then
    echo "✓ MultipleSchemaSpec.hs has updated error message expectations - fix is applied!"
else
    echo "✗ MultipleSchemaSpec.hs does not have updated expectations - fix not applied"
    test_status=1
fi

if grep -q 'Only the following schemas are exposed:' "test/spec/Feature/Query/MultipleSchemaSpec.hs"; then
    echo "✓ MultipleSchemaSpec.hs expects hint with schema list - fix is applied!"
else
    echo "✗ MultipleSchemaSpec.hs does not expect hint field - fix not applied"
    test_status=1
fi

echo ""
echo "Checking test/io/test_io.py for removed JWT error details..."
if ! grep -q 'assert response.json\(\)\["details"\] == "None of the keys was able to decode the JWT"' "test/io/test_io.py"; then
    echo "✓ test_io.py has removed JWT error details check - fix is applied!"
else
    echo "✗ test_io.py still expects JWT error details - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
