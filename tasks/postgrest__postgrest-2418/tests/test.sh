#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PgSafeUpdateSpec.hs" "test/spec/Feature/Query/PgSafeUpdateSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for pg_safeupdate support (PR #2418)..."
echo ""
echo "This PR adds support for PostgreSQL's pg_safeupdate extension which prevents"
echo "full-table UPDATE/DELETE operations without WHERE clauses."
echo ""

echo "Checking default.nix has pg_safeupdate in PostgreSQL 14 packages..."
if [ -f "default.nix" ] && grep -q 'postgresql_14.withPackages (p: \[ p.postgis p.pg_safeupdate \])' "default.nix"; then
    echo "✓ default.nix includes pg_safeupdate for PostgreSQL 14 (fix applied)"
else
    echo "✗ default.nix does not include pg_safeupdate for PostgreSQL 14 (not fixed)"
    test_status=1
fi

echo "Checking default.nix has pg_safeupdate in PostgreSQL 13 packages..."
if [ -f "default.nix" ] && grep -q 'postgresql_13.withPackages (p: \[ p.postgis p.pg_safeupdate \])' "default.nix"; then
    echo "✓ default.nix includes pg_safeupdate for PostgreSQL 13 (fix applied)"
else
    echo "✗ default.nix does not include pg_safeupdate for PostgreSQL 13 (not fixed)"
    test_status=1
fi

echo "Checking postgrest.cabal includes PgSafeUpdateSpec in test suite..."
if [ -f "postgrest.cabal" ] && grep -q 'Feature.Query.PgSafeUpdateSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PgSafeUpdateSpec (fix applied)"
else
    echo "✗ postgrest.cabal does not include PgSafeUpdateSpec (not fixed)"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking PgSafeUpdateSpec.hs exists..."
if [ -f "test/spec/Feature/Query/PgSafeUpdateSpec.hs" ]; then
    echo "✓ PgSafeUpdateSpec.hs exists (HEAD version)"
else
    echo "✗ PgSafeUpdateSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

echo "Checking PgSafeUpdateSpec.hs has module declaration..."
if [ -f "test/spec/Feature/Query/PgSafeUpdateSpec.hs" ] && grep -q 'module Feature.Query.PgSafeUpdateSpec where' "test/spec/Feature/Query/PgSafeUpdateSpec.hs"; then
    echo "✓ PgSafeUpdateSpec.hs has correct module declaration (HEAD version)"
else
    echo "✗ PgSafeUpdateSpec.hs does not have correct module declaration"
    test_status=1
fi

echo "Checking test fixtures were copied..."
if [ -f "test/spec/fixtures/data.sql" ]; then
    echo "✓ data.sql exists (HEAD version)"
else
    echo "✗ data.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/spec/fixtures/schema.sql" ]; then
    echo "✓ schema.sql exists (HEAD version)"
else
    echo "✗ schema.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/spec/fixtures/privileges.sql" ]; then
    echo "✓ privileges.sql exists (HEAD version)"
else
    echo "✗ privileges.sql not found - HEAD file not copied!"
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
