#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/JsonOperatorSpec.hs" "test/spec/Feature/Query/JsonOperatorSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Check that CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2929.*Fix arrow filtering on RPC returning dynamic TABLE with composite type' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that Plan.hs does NOT have the buggy resolveTableField function (should be removed in fix)
echo "Checking Plan.hs does NOT have buggy resolveTableField function..."
if grep -q 'resolveTableField :: Table -> Field -> CoercibleField' "src/PostgREST/Plan.hs"; then
    echo "✗ Plan.hs still has buggy resolveTableField function - fix not applied"
    test_status=1
else
    echo "✓ Plan.hs does not have buggy resolveTableField function"
fi

# Check that Plan.hs has cfToJson=False for json/jsonb types (the fix)
echo "Checking Plan.hs has cfToJson=False for json/jsonb types..."
if grep -q 'cfIRType="json"}  -> cf{cfJsonPath=jp, cfToJson=False}' "src/PostgREST/Plan.hs" && \
   grep -q 'cfIRType="jsonb"} -> cf{cfJsonPath=jp, cfToJson=False}' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has cfToJson=False for json/jsonb types"
else
    echo "✗ Plan.hs missing cfToJson=False for json/jsonb types - fix not applied"
    test_status=1
fi

# Check that Plan.hs uses resolveTableFieldName directly in resolveTypeOrUnknown
echo "Checking Plan.hs uses resolveTableFieldName in resolveTypeOrUnknown..."
if grep -q 'Just . flip resolveTableFieldName fn' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses resolveTableFieldName correctly"
else
    echo "✗ Plan.hs not using resolveTableFieldName - fix not applied"
    test_status=1
fi

# Check that JsonOperatorSpec.hs has the test for RPC returning dynamic TABLE with composite type
echo "Checking JsonOperatorSpec.hs has test for RPC with composite type..."
if grep -q 'works when an RPC returns a dynamic TABLE with a composite type' "test/spec/Feature/Query/JsonOperatorSpec.hs" && \
   grep -q '/rpc/returns_complex?select=val->r&val->i=gt.0.5&order=val->>i.desc' "test/spec/Feature/Query/JsonOperatorSpec.hs"; then
    echo "✓ JsonOperatorSpec.hs has test for RPC with composite type"
else
    echo "✗ JsonOperatorSpec.hs missing test for RPC with composite type - fix not applied"
    test_status=1
fi

# Check that schema.sql has the returns_complex function
echo "Checking schema.sql for returns_complex function..."
if grep -q 'create or replace function test.returns_complex()' "test/spec/fixtures/schema.sql" && \
   grep -q 'returns table(id int, val complex)' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has returns_complex function"
else
    echo "✗ schema.sql missing returns_complex function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
