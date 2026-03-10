#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/load"
cp "/tests/load/fixtures.sql" "test/load/fixtures.sql"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/NoSuperuserSpec.hs" "test/spec/Feature/NoSuperuserSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/roles.sql" "test/spec/fixtures/roles.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for schema cache permission and generated columns (#2768)..."
echo ""

# Check CHANGELOG.md has the fix entries
echo "Checking CHANGELOG.md has the fix entries..."
if grep -q "#2762" "CHANGELOG.md" && grep -q "permission denied for schema" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has schema permission fix entry"
else
    echo "✗ CHANGELOG.md missing schema permission fix entry - fix not applied"
    test_status=1
fi

if grep -q "#2756" "CHANGELOG.md" && grep -q "generated columns" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has generated columns fix entry"
else
    echo "✗ CHANGELOG.md missing generated columns fix entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs has the generated columns fix
echo "Checking src/PostgREST/SchemaCache.hs has generated columns fix..."
if grep -q "WHEN a.attgenerated = 's' THEN null" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has generated columns fix"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing generated columns fix - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs imports pgVersion120
echo "Checking src/PostgREST/SchemaCache.hs imports pgVersion120..."
if grep -q "pgVersion120" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs imports pgVersion120"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing pgVersion120 import - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs has LEFT JOIN pg_depend for sequence detection
echo "Checking src/PostgREST/SchemaCache.hs has pg_depend join for generated columns..."
if grep -q "LEFT JOIN pg_depend dep" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has pg_depend join"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing pg_depend join - fix not applied"
    test_status=1
fi

# Check test fixture files use :PGUSER instead of :USER
echo "Checking test/io/fixtures.sql uses :PGUSER..."
if grep -q ":PGUSER" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql uses :PGUSER"
else
    echo "✗ test/io/fixtures.sql not using :PGUSER - fix not applied"
    test_status=1
fi

echo "Checking test/load/fixtures.sql uses :PGUSER..."
if grep -q ":PGUSER" "test/load/fixtures.sql"; then
    echo "✓ test/load/fixtures.sql uses :PGUSER"
else
    echo "✗ test/load/fixtures.sql not using :PGUSER - fix not applied"
    test_status=1
fi

# Check nix/tools/withTools.nix creates minimally privileged role
echo "Checking nix/tools/withTools.nix creates minimally privileged role..."
if grep -q "Creating a minimally privileged \$PGUSER connection role" "nix/tools/withTools.nix"; then
    echo "✓ nix/tools/withTools.nix creates minimally privileged role"
else
    echo "✗ nix/tools/withTools.nix not creating minimally privileged role - fix not applied"
    test_status=1
fi

# Check nix/tools/withTools.nix uses superuserRole variable
echo "Checking nix/tools/withTools.nix defines superuserRole..."
if grep -q 'superuserRole = "postgres"' "nix/tools/withTools.nix"; then
    echo "✓ nix/tools/withTools.nix defines superuserRole"
else
    echo "✗ nix/tools/withTools.nix missing superuserRole - fix not applied"
    test_status=1
fi

# Check nix/tools/cabalTools.nix has PGRST_DB_ANON_ROLE support
echo "Checking nix/tools/cabalTools.nix has PGRST_DB_ANON_ROLE..."
if grep -q "PGRST_DB_ANON_ROLE" "nix/tools/cabalTools.nix"; then
    echo "✓ nix/tools/cabalTools.nix has PGRST_DB_ANON_ROLE"
else
    echo "✗ nix/tools/cabalTools.nix missing PGRST_DB_ANON_ROLE - fix not applied"
    test_status=1
fi

# Check postgrest.cabal includes Feature.NoSuperuserSpec test
echo "Checking postgrest.cabal includes Feature.NoSuperuserSpec..."
if grep -q "Feature.NoSuperuserSpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes Feature.NoSuperuserSpec"
else
    echo "✗ postgrest.cabal missing Feature.NoSuperuserSpec - fix not applied"
    test_status=1
fi

# Check Feature.NoSuperuserSpec test file exists
echo "Checking test/spec/Feature/NoSuperuserSpec.hs exists..."
if [ -f "test/spec/Feature/NoSuperuserSpec.hs" ]; then
    echo "✓ test/spec/Feature/NoSuperuserSpec.hs exists"
else
    echo "✗ test/spec/Feature/NoSuperuserSpec.hs missing - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
