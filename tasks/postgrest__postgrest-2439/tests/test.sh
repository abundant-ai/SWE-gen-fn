#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedDisambiguationSpec.hs" "test/spec/Feature/Query/EmbedDisambiguationSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for one-to-one relationship embedding (PR #2439)..."
echo ""
echo "NOTE: This PR adds detection of one-to-one (O2O) relationships for resource embedding"
echo "BASE (buggy) only has M2O (many-to-one) relationships"
echo "HEAD (fixed) has both M2O and O2O relationship detection"
echo ""

# Check CHANGELOG - HEAD should mention #1984 and one-to-one relationships
echo "Checking CHANGELOG.md mentions PR #1984 and one-to-one relationships..."
if grep -q "#1984" "CHANGELOG.md" && grep -q "one-to-one relationships" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PR #1984 and one-to-one relationships"
else
    echo "✗ CHANGELOG.md does not mention PR #1984 or one-to-one relationships - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should use allM2OandO2ORels instead of allM2ORels
echo "Checking src/PostgREST/DbStructure.hs uses allM2OandO2ORels..."
if grep -q "allM2OandO2ORels" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs uses allM2OandO2ORels"
else
    echo "✗ DbStructure.hs still uses allM2ORels - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should have addViewM2OAndO2ORels function
echo "Checking src/PostgREST/DbStructure.hs has addViewM2OAndO2ORels function..."
if grep -q "addViewM2OAndO2ORels" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs has addViewM2OAndO2ORels function"
else
    echo "✗ DbStructure.hs does not have addViewM2OAndO2ORels - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should have O2O cardinality type
echo "Checking src/PostgREST/DbStructure.hs checks for O2O cardinality..."
if grep -q "isO2O" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs has O2O cardinality checks"
else
    echo "✗ DbStructure.hs does not check for O2O - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should use addInverseRels instead of addO2MRels
echo "Checking src/PostgREST/DbStructure.hs uses addInverseRels..."
if grep -q "addInverseRels" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs uses addInverseRels"
else
    echo "✗ DbStructure.hs still uses addO2MRels - fix not applied"
    test_status=1
fi

# Check DbStructure.hs - HEAD should decode isOneToOne boolean from query
echo "Checking src/PostgREST/DbStructure.hs decodes isOneToOne flag..."
if grep -q "isOneToOne" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs decodes isOneToOne flag from relationship query"
else
    echo "✗ DbStructure.hs does not decode isOneToOne - fix not applied"
    test_status=1
fi

# Check that the comment mentions "O2O" instead of just "M2O"
echo "Checking src/PostgREST/DbStructure.hs comments mention O2O relationships..."
if grep -q "M2O and O2O" "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs comments mention both M2O and O2O"
else
    echo "✗ DbStructure.hs comments don't mention O2O - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - one-to-one relationship embedding detection added successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
