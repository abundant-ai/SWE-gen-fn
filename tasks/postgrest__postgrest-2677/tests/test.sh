#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/pgbench/1652"
cp "/tests/pgbench/1652/new.sql" "test/pgbench/1652/new.sql"
mkdir -p "test/pgbench/1652"
cp "/tests/pgbench/1652/old.sql" "test/pgbench/1652/old.sql"
mkdir -p "test/pgbench/2677"
cp "/tests/pgbench/2677/new.sql" "test/pgbench/2677/new.sql"
mkdir -p "test/pgbench/2677"
cp "/tests/pgbench/2677/old.sql" "test/pgbench/2677/old.sql"
mkdir -p "test/pgbench"
cp "/tests/pgbench/README.md" "test/pgbench/README.md"
mkdir -p "test/pgbench"
cp "/tests/pgbench/fixtures.sql" "test/pgbench/fixtures.sql"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for function call inlining optimization..."
echo ""
echo "NOTE: This PR optimizes SQL query generation using LATERAL instead of CTE."
echo "HEAD (fixed) should use fromJsonBodyF and simpler function call logic."
echo "BASE (buggy) has complex normalizedBody/pgFmtSelectFromJson code."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #1652 entry
echo "Checking CHANGELOG.md has PR #1652 entry..."
if grep -q "#1652, Fix function call with arguments not inlining" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #1652 entry"
else
    echo "✗ CHANGELOG.md missing PR #1652 entry - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should use fromJsonBodyF (simpler code)
echo "Checking src/PostgREST/Query/QueryBuilder.hs should use fromJsonBodyF..."
if grep -q "fromJsonBodyF body iCols True False" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses fromJsonBodyF function"
else
    echo "✗ QueryBuilder.hs missing fromJsonBodyF usage - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should NOT have normalizedBody in mutatePlanToQuery
echo "Checking QueryBuilder.hs should NOT have normalizedBody in INSERT..."
if grep -A2 "mutatePlanToQuery (Insert" "src/PostgREST/Query/QueryBuilder.hs" | grep -q "normalizedBody"; then
    echo "✗ QueryBuilder.hs still has normalizedBody in INSERT - fix not applied"
    test_status=1
else
    echo "✓ QueryBuilder.hs removed normalizedBody from INSERT"
fi

# Check QueryBuilder.hs - HEAD should use simpler function call (not prmsCTE)
echo "Checking QueryBuilder.hs has simplified function call code..."
if grep -q "fromCall" "src/PostgREST/Query/QueryBuilder.hs" && \
   ! grep -q "prmsCTE" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has simplified function call code"
else
    echo "✗ QueryBuilder.hs missing simplified function call - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - function call uses LATERAL pattern
echo "Checking QueryBuilder.hs uses LATERAL for function calls..."
if grep -q "LATERAL.*callIt" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses LATERAL pattern"
else
    echo "✗ QueryBuilder.hs missing LATERAL pattern - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs - HEAD should still have fromJsonBodyF function
echo "Checking src/PostgREST/Query/SqlFragment.hs has fromJsonBodyF..."
if grep -q "fromJsonBodyF ::" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has fromJsonBodyF function"
else
    echo "✗ SqlFragment.hs missing fromJsonBodyF - fix not applied"
    test_status=1
fi

# Check pgbench test files exist
echo "Checking pgbench test files exist..."
if [ -f "test/pgbench/1652/new.sql" ] && [ -f "test/pgbench/1652/old.sql" ] && \
   [ -f "test/pgbench/2677/new.sql" ] && [ -f "test/pgbench/2677/old.sql" ]; then
    echo "✓ pgbench test files exist"
else
    echo "✗ pgbench test files missing - fix not applied"
    test_status=1
fi

# Check pgbench README and fixtures exist
echo "Checking pgbench README and fixtures..."
if [ -f "test/pgbench/README.md" ] && [ -f "test/pgbench/fixtures.sql" ]; then
    echo "✓ pgbench README and fixtures exist"
else
    echo "✗ pgbench README or fixtures missing - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should have simplified cost expectations (single value, not version-dependent)
echo "Checking test/spec/Feature/Query/PlanSpec.hs has simplified costs..."
if grep -q "totalCost \`shouldBe\` 3.27" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has simplified cost expectations"
else
    echo "✗ PlanSpec.hs missing simplified costs - fix not applied"
    test_status=1
fi

# Check PlanSpec.hs - HEAD should have function inlining tests added
echo "Checking PlanSpec.hs has function inlining tests..."
if grep -q "function inlining" "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ PlanSpec.hs has function inlining tests"
else
    echo "✗ PlanSpec.hs missing function inlining tests - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should have pgVersion130 check for domain embedding
echo "Checking test/spec/Feature/Query/RpcSpec.hs has pgVersion130 check..."
if grep -q "actualPgVersion >= pgVersion130" "test/spec/Feature/Query/RpcSpec.hs" && \
   grep -q "can embed if rpc returns domain of table type" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has pgVersion130 check for embedding domain types"
else
    echo "✗ RpcSpec.hs missing pgVersion130 check - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - should import pgVersion130
echo "Checking RpcSpec.hs imports pgVersion130..."
if grep -q "pgVersion130" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs imports pgVersion130"
else
    echo "✗ RpcSpec.hs missing pgVersion130 import - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - function call inlining refactor properly implemented"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"

