#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Check that CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2963.*Fix RPCs not embedding correctly when using overloaded functions for computed relationships' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that Relationship.hs HAS relTableAlias field (added in the fix)
echo "Checking Relationship.hs for relTableAlias field..."
if grep -q 'relTableAlias' "src/PostgREST/SchemaCache/Relationship.hs"; then
    echo "✓ Relationship.hs has relTableAlias field"
else
    echo "✗ Relationship.hs missing relTableAlias field - fix not applied"
    test_status=1
fi

# Check that Plan.hs uses relTableAlias instead of relTable for ComputedRelationship
echo "Checking Plan.hs uses relTableAlias for ComputedRelationship..."
if grep -q 'relToParent=Just r{relTableAlias=maybe (relTable r)' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses relTableAlias correctly"
else
    echo "✗ Plan.hs not using relTableAlias - fix not applied"
    test_status=1
fi

# Check that QueryBuilder.hs uses relTableAlias for ComputedRelationship with type cast
echo "Checking QueryBuilder.hs uses relTableAlias with type cast..."
if grep -q 'Just ComputedRelationship{relFunction,relTableAlias,relTable}' "src/PostgREST/Query/QueryBuilder.hs" && \
   grep -q 'fromQi relFunction <> "(" <> pgFmtIdent (qiName relTableAlias) <> "::" <> fromQi relTable <> ")"' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses relTableAlias with type cast correctly"
else
    echo "✗ QueryBuilder.hs not using relTableAlias correctly - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs HAS the relTableAlias column (added in the fix)
echo "Checking SchemaCache.hs for relTableAlias column..."
if grep -q 'pure (QualifiedIdentifier mempty mempty)' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has relTableAlias column"
else
    echo "✗ SchemaCache.hs missing relTableAlias column - fix not applied"
    test_status=1
fi

# Check that ComputedRelsSpec.hs has the overloaded functions tests
echo "Checking ComputedRelsSpec.hs has overloaded functions tests..."
if grep -q 'can be defined using overloaded functions' "test/spec/Feature/Query/ComputedRelsSpec.hs"; then
    echo "✓ ComputedRelsSpec.hs has overloaded functions tests"
else
    echo "✗ ComputedRelsSpec.hs missing overloaded functions tests - fix not applied"
    test_status=1
fi

# Check that ComputedRelsSpec.hs has the specific test cases
echo "Checking ComputedRelsSpec.hs for specific overloaded function test cases..."
if grep -q 'items?select=.*computed_rel_overload' "test/spec/Feature/Query/ComputedRelsSpec.hs" && \
   grep -q 'items2?select=.*computed_rel_overload' "test/spec/Feature/Query/ComputedRelsSpec.hs" && \
   grep -q 'rpc/search?id=1&select=.*computed_rel_overload' "test/spec/Feature/Query/ComputedRelsSpec.hs" && \
   grep -q 'rpc/search2?id=1&select=.*computed_rel_overload' "test/spec/Feature/Query/ComputedRelsSpec.hs"; then
    echo "✓ ComputedRelsSpec.hs has all expected overloaded function test cases"
else
    echo "✗ ComputedRelsSpec.hs missing expected test cases - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
