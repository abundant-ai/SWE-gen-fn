#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for --dump-schema running with wrong PG version (PR #2153)..."
echo ""
echo "This PR fixes an issue where --dump-schema was using the wrong PostgreSQL version"
echo "by ensuring queryDbStructure gets the actual PG version from the database connection."
echo ""

echo "Checking CHANGELOG.md has both fix entries..."
if [ -f "CHANGELOG.md" ] && grep -q '#2101.*Remove aggregates, procedures and window functions' "CHANGELOG.md" && grep -q '#2153.*Fix --dump-schema running with a wrong PG version' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes both fix entries (fix applied)"
else
    echo "✗ CHANGELOG.md does not include both fix entries (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/App.hs restores ctxPgVersion parameter..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'DbStructure.accessibleProcs ctxPgVersion configDbPreparedStatements' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses ctxPgVersion parameter (fix applied)"
else
    echo "✗ App.hs does not use ctxPgVersion parameter (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/CLI.hs removes actualPgVersion usage in dumpSchema..."
if [ -f "src/PostgREST/CLI.hs" ] && ! grep -q 'actualPgVersion <- AppState.getPgVersion appState' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs does not use actualPgVersion in dumpSchema (fix applied)"
else
    echo "✗ CLI.hs still uses actualPgVersion in dumpSchema (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/Config/Database.hs exports pgVersionStatement..."
if [ -f "src/PostgREST/Config/Database.hs" ] && grep -q 'module PostgREST.Config.Database' "src/PostgREST/Config/Database.hs" && grep -q 'pgVersionStatement' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs exports pgVersionStatement (fix applied)"
else
    echo "✗ Config/Database.hs does not export pgVersionStatement (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/DbStructure.hs signature reverts to not take PgVersion parameter..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q 'queryDbStructure :: \[Schema\] -> \[Schema\] -> Bool -> SQL.Transaction DbStructure' "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs queryDbStructure signature does not take PgVersion (fix applied)"
else
    echo "✗ DbStructure.hs queryDbStructure signature still takes PgVersion (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/DbStructure.hs imports pgVersionStatement..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q 'import PostgREST.Config.Database' "src/PostgREST/DbStructure.hs" && grep -q 'pgVersionStatement' "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs imports pgVersionStatement (fix applied)"
else
    echo "✗ DbStructure.hs does not import pgVersionStatement (not fixed)"
    test_status=1
fi

echo "Checking PostgREST/DbStructure.hs queries PG version inside transaction..."
if [ -f "src/PostgREST/DbStructure.hs" ] && grep -q 'pgVer   <- SQL.statement mempty pgVersionStatement' "src/PostgREST/DbStructure.hs"; then
    echo "✓ DbStructure.hs queries PG version inside transaction (fix applied)"
else
    echo "✗ DbStructure.hs does not query PG version inside transaction (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking Main.hs exists..."
if [ -f "test/spec/Main.hs" ]; then
    echo "✓ Main.hs exists (HEAD version)"
else
    echo "✗ Main.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking schema.sql exists..."
if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
