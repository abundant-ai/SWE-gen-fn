#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4089 which improves the PGRST106 error message for invalid schemas
# HEAD state (98e750c14150) = fix applied
# BASE state (with bug.patch) = old error format (lists schemas in message field)
# ORACLE state (BASE + fix.patch) = new error format (invalid schema in message, valid schemas in hint)

test_status=0

echo "Verifying source code matches HEAD state (improved PGRST106 error message)..."
echo ""

echo "Checking that UnacceptableSchema error type includes the invalid schema parameter..."
if grep -q 'UnacceptableSchema Text \[Text\]' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has UnacceptableSchema with invalid schema parameter - fix applied!"
else
    echo "✗ Error.hs missing invalid schema parameter in UnacceptableSchema - fix not applied"
    test_status=1
fi

echo "Checking that error message shows the invalid schema..."
if grep -q 'message (UnacceptableSchema sch _)   = "Invalid schema: " <> sch' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs error message shows invalid schema - fix applied!"
else
    echo "✗ Error.hs error message not showing invalid schema - fix not applied"
    test_status=1
fi

echo "Checking that hint shows the exposed schemas..."
if grep -q 'hint (UnacceptableSchema _ schemas) = Just \$ JSON.String \$ "Only the following schemas are exposed: "  <> T.intercalate ", " schemas' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs hint shows exposed schemas - fix applied!"
else
    echo "✗ Error.hs hint not showing exposed schemas - fix not applied"
    test_status=1
fi

echo "Checking that ApiRequest passes the invalid schema to UnacceptableSchema..."
if grep -q 'Just p | p `notElem` configDbSchemas -> Left \$ UnacceptableSchema p \$ toList configDbSchemas' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes invalid schema to error - fix applied!"
else
    echo "✗ ApiRequest.hs not passing invalid schema to error - fix not applied"
    test_status=1
fi

echo "Checking that test file includes updated error message format..."
if grep -q '"message":"Invalid schema: unknown"' "test/spec/Feature/Query/MultipleSchemaSpec.hs" && \
   grep -q '"hint":"Only the following schemas are exposed: v1, v2, SPECIAL \\"@/\\\\#~_-"' "test/spec/Feature/Query/MultipleSchemaSpec.hs"; then
    echo "✓ MultipleSchemaSpec.hs includes updated error message format - test from HEAD!"
else
    echo "✗ MultipleSchemaSpec.hs does not include updated error message format - test not from HEAD"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the improved error message..."
if grep -q "Improve the \`PGRST106\` error when the requested schema is invalid" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions improved error message - fix applied!"
else
    echo "✗ CHANGELOG does not mention improved error message - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
