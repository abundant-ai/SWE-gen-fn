#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/RollbackSpec.hs" "test/spec/Feature/RollbackSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4518 which fixes Content-Length header on empty HTTP 201 responses
# The HEAD (ac6451fc) is after a refactor that simplifies to use only LBS.ByteString

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the Content-Length fix..."
if grep -q "Fix not returning \`Content-Length\` on empty HTTP \`201\` responses" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions Content-Length fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention Content-Length fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Response.hs defines contentLengthHeader with LBS.ByteString..."
if grep -q "contentLengthHeader :: LBS.ByteString -> HTTP.Header" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs defines contentLengthHeader correctly - fix applied!"
else
    echo "✗ Response.hs does not define contentLengthHeader correctly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that contentLengthHeader uses LBS.length..."
if grep -q 'contentLengthHeader body = ("Content-Length", show (LBS.length body))' "src/PostgREST/Response.hs"; then
    echo "✓ contentLengthHeader implementation correct - fix applied!"
else
    echo "✗ contentLengthHeader implementation incorrect - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MutationCreate adds contentLengthHeader to overrideStatusHeaders..."
if grep -q "overrideStatusHeaders rsGucStatus rsGucHeaders status.*contentLengthHeader bod:headers'" "src/PostgREST/Response.hs"; then
    echo "✓ MutationCreate adds contentLengthHeader to headers - fix applied!"
else
    echo "✗ MutationCreate does not add contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MutationCreate does NOT include separate contentLengthHeaderStrict in catMaybes..."
if ! grep -q "Just.*contentLengthHeaderStrict rsBody" "src/PostgREST/Response.hs"; then
    echo "✓ MutationCreate does not duplicate Content-Length - fix applied!"
else
    echo "✗ MutationCreate still has incorrect duplicate - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MutationUpdate uses lbsBody with contentLengthHeader..."
if grep -q "lbsBody = LBS.fromStrict rsBody" "src/PostgREST/Response.hs" && \
   grep -q "contentLengthHeader lbsBody" "src/PostgREST/Response.hs"; then
    echo "✓ MutationUpdate uses lbsBody with contentLengthHeader - fix applied!"
else
    echo "✗ MutationUpdate does not use lbsBody correctly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MutationSingleUpsert uses contentLengthHeader..."
if grep -q "cLHeader = \[contentLengthHeader lbsBody\]" "src/PostgREST/Response.hs"; then
    echo "✓ MutationSingleUpsert uses contentLengthHeader - fix applied!"
else
    echo "✗ MutationSingleUpsert does not use contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MutationDelete uses contentLengthHeader..."
if grep -q "headers.*contentLengthHeader lbsBody.*contentTypeHeaders" "src/PostgREST/Response.hs"; then
    echo "✓ MutationDelete uses contentLengthHeader - fix applied!"
else
    echo "✗ MutationDelete does not use contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CallReadPlan uses contentLengthHeader..."
if grep -q "cLHeader = if isHeadMethod then mempty else \[contentLengthHeader" "src/PostgREST/Response.hs"; then
    echo "✓ CallReadPlan uses contentLengthHeader - fix applied!"
else
    echo "✗ CallReadPlan does not use contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that DbPlanResult uses contentLengthHeader..."
if grep -q "contentLengthHeader body.*contentTypeHeaders media" "src/PostgREST/Response.hs"; then
    echo "✓ DbPlanResult uses contentLengthHeader - fix applied!"
else
    echo "✗ DbPlanResult does not use contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that InspectPlan uses contentLengthHeader..."
if grep -q "cLHeader = if headersOnly then mempty else \[contentLengthHeader rsBody\]" "src/PostgREST/Response.hs"; then
    echo "✓ InspectPlan uses contentLengthHeader - fix applied!"
else
    echo "✗ InspectPlan does not use contentLengthHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that respondInfo uses contentLengthHeader..."
if grep -q "contentLengthHeader mempty.*allOrigins" "src/PostgREST/Response.hs"; then
    echo "✓ respondInfo uses contentLengthHeader - fix applied!"
else
    echo "✗ respondInfo does not use contentLengthHeader - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
