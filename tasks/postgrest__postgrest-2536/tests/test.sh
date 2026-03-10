#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for embedding computed relationships with normal relationships (PR #2536)..."
echo ""
echo "NOTE: This PR fixes aliasing when following a normal embed with a computed relationship."
echo "HEAD (fixed) should have relAggAlias field and proper aliasing logic"
echo "BASE (buggy) lacks relAggAlias and has incorrect aliasing"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entry for the fix
echo "Checking CHANGELOG.md mentions #2534 fix..."
if grep -q "#2534, Fix embedding a computed relationship with a normal relationship" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2534"
else
    echo "✗ CHANGELOG.md missing #2534 entry - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have relAggAlias in defReadPlan
echo "Checking src/PostgREST/Plan.hs has relAggAlias in defReadPlan..."
if grep -q "defReadPlan = ReadPlan \[\] (QualifiedIdentifier mempty mempty) Nothing \[\] \[\] allRange mempty Nothing \[\] Nothing mempty Nothing Nothing rootDepth" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has relAggAlias in defReadPlan (13 fields)"
else
    echo "✗ Plan.hs doesn't have relAggAlias in defReadPlan - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use relAlias in addRels
echo "Checking src/PostgREST/Plan.hs uses relAlias in addRels..."
if grep -q "addRels schema action allRels parentNode (Node rPlan@ReadPlan{relName,relHint,relAlias,depth} forest) =" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses relAlias in addRels pattern"
else
    echo "✗ Plan.hs doesn't use relAlias in addRels - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have parentAlias instead of fromAlias
echo "Checking src/PostgREST/Plan.hs uses parentAlias..."
if grep -q "Just (Node ReadPlan{from=parentNodeQi, fromAlias=parentAlias} _) ->" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses parentAlias"
else
    echo "✗ Plan.hs doesn't use parentAlias - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have aggAlias calculation
echo "Checking src/PostgREST/Plan.hs has aggAlias calculation..."
if grep -q 'aggAlias = qiName (relTable r) <> "_" <> fromMaybe relName relAlias <> "_" <> show depth' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has aggAlias calculation"
else
    echo "✗ Plan.hs doesn't have aggAlias calculation - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have ComputedRelationship case with aggAlias
echo "Checking src/PostgREST/Plan.hs has ComputedRelationship case..."
if grep -q "ComputedRelationship{}" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has ComputedRelationship case"
else
    echo "✗ Plan.hs doesn't have ComputedRelationship case - fix not applied"
    test_status=1
fi

# Check ReadPlan.hs - HEAD should have relAggAlias field
echo "Checking src/PostgREST/Plan/ReadPlan.hs has relAggAlias field..."
if grep -q ", relAggAlias  :: Alias" "src/PostgREST/Plan/ReadPlan.hs"; then
    echo "✓ ReadPlan.hs has relAggAlias field"
else
    echo "✗ ReadPlan.hs doesn't have relAggAlias field - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should use relAggAlias
echo "Checking src/PostgREST/Query/QueryBuilder.hs uses relAggAlias..."
if grep -q "getSelectsJoins rr@(Node ReadPlan{relName, relToParent=Just rel, relAggAlias, relAlias, relJoinType=joinType} _) (selects,joins) =" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses relAggAlias in pattern"
else
    echo "✗ QueryBuilder.hs doesn't use relAggAlias - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should use aggAlias variable
echo "Checking src/PostgREST/Query/QueryBuilder.hs has aggAlias variable..."
if grep -q "aggAlias = pgFmtIdent relAggAlias" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has aggAlias variable"
else
    echo "✗ QueryBuilder.hs doesn't have aggAlias variable - fix not applied"
    test_status=1
fi

# Check ComputedRelsSpec.hs - HEAD should have the new test case
echo "Checking test/spec/Feature/Query/ComputedRelsSpec.hs has new test for normal embed..."
if grep -q "creates queries with the right aliasing when following a normal embed" "test/spec/Feature/Query/ComputedRelsSpec.hs"; then
    echo "✓ ComputedRelsSpec.hs has new test case"
else
    echo "✗ ComputedRelsSpec.hs doesn't have new test case - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should have computed_clients function
echo "Checking test/spec/fixtures/schema.sql has computed_clients function..."
if grep -q "CREATE FUNCTION test.computed_clients(test.projects)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has computed_clients function"
else
    echo "✗ schema.sql doesn't have computed_clients function - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should have computed_projects function
echo "Checking test/spec/fixtures/schema.sql has computed_projects function..."
if grep -q "CREATE FUNCTION test.computed_projects(test.clients)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has computed_projects function"
else
    echo "✗ schema.sql doesn't have computed_projects function - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - computed relationship embedding fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
