#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/JsonOperatorSpec.hs" "test/Feature/JsonOperatorSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/MultipleSchemaSpec.hs" "test/Feature/MultipleSchemaSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/RpcSpec.hs" "test/Feature/RpcSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"

test_status=0

echo "Verifying fix for dropping PostgreSQL 9.5 support (PR #2038)..."
echo ""
echo "This PR removes support for PostgreSQL 9.5 from PostgREST."
echo "The bug was that PostgreSQL 9.5 support was still present in the codebase."
echo "The fix removes all references to PostgreSQL 9.5 from documentation, CI, and build files."
echo ""

echo "Checking CHANGELOG.md has the fix documented..."
if [ -f "CHANGELOG.md" ]; then
    echo "✓ CHANGELOG.md exists"
    if grep -q "#2038, Dropped support for PostgreSQL 9.5" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md documents dropping PostgreSQL 9.5 support (fix applied)"
    else
        echo "✗ CHANGELOG.md missing entry for dropping PostgreSQL 9.5 (fix not applied)"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking README.md doesn't reference PostgreSQL 9.5..."
if [ -f "README.md" ]; then
    echo "✓ README.md exists"

    # After fix: should NOT have PostgreSQL 9.5 row-level security documentation
    if grep -q "Since PostgreSQL 9.5 supports true \[row-level" "README.md"; then
        echo "✗ README.md still has PostgreSQL 9.5 documentation (fix not applied)"
        test_status=1
    else
        echo "✓ README.md doesn't reference PostgreSQL 9.5 (fix applied)"
    fi
else
    echo "✗ README.md not found"
    test_status=1
fi

echo ""
echo "Checking default.nix doesn't reference PostgreSQL 9.5..."
if [ -f "default.nix" ]; then
    echo "✓ default.nix exists"

    # After fix: should NOT have postgresql-9.5 in the list
    if grep -q "postgresql-9.5" "default.nix" || grep -q "postgresql_9_5" "default.nix"; then
        echo "✗ default.nix still references PostgreSQL 9.5 (fix not applied)"
        test_status=1
    else
        echo "✓ default.nix doesn't reference PostgreSQL 9.5 (fix applied)"
    fi
else
    echo "✗ default.nix not found"
    test_status=1
fi

echo ""
echo "Checking nix/overlays/postgresql-legacy.nix..."
if [ -f "nix/overlays/postgresql-legacy.nix" ]; then
    echo "✓ nix/overlays/postgresql-legacy.nix exists"

    # After fix: postgresql_9_5 definition should be commented out
    if grep -q "^  postgresql_9_5 =" "nix/overlays/postgresql-legacy.nix"; then
        echo "✗ postgresql-legacy.nix still has active postgresql_9_5 definition (fix not applied)"
        test_status=1
    elif grep -q "^  # postgresql_9_5 =" "nix/overlays/postgresql-legacy.nix"; then
        echo "✓ postgresql-legacy.nix has postgresql_9_5 commented out (fix applied)"
    else
        echo "✗ postgresql-legacy.nix missing postgresql_9_5 definition entirely"
        test_status=1
    fi
else
    echo "✗ nix/overlays/postgresql-legacy.nix not found"
    test_status=1
fi

echo ""
echo "Checking nix/README.md doesn't list PostgreSQL 9.5 commands..."
if [ -f "nix/README.md" ]; then
    echo "✓ nix/README.md exists"

    # After fix: should NOT have postgrest-with-postgresql-9.5 command
    if grep -q "postgrest-with-postgresql-9.5" "nix/README.md"; then
        echo "✗ nix/README.md still lists PostgreSQL 9.5 commands (fix not applied)"
        test_status=1
    else
        echo "✓ nix/README.md doesn't list PostgreSQL 9.5 commands (fix applied)"
    fi
else
    echo "✗ nix/README.md not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Config/PgVersion.hs has correct minimum version..."
if [ -f "src/PostgREST/Config/PgVersion.hs" ]; then
    echo "✓ src/PostgREST/Config/PgVersion.hs exists"

    # After fix: minimumPgVersion should be pgVersion96, not pgVersion95
    if grep -q "minimumPgVersion = pgVersion96" "src/PostgREST/Config/PgVersion.hs"; then
        echo "✓ minimumPgVersion is set to pgVersion96 (fix applied)"
    else
        echo "✗ minimumPgVersion not set to pgVersion96 (fix not applied)"
        test_status=1
    fi

    # After fix: pgVersion95 should not be exported or defined
    if grep -q "pgVersion95" "src/PostgREST/Config/PgVersion.hs"; then
        echo "✗ pgVersion95 still exists in PgVersion.hs (fix not applied)"
        test_status=1
    else
        echo "✓ pgVersion95 removed from PgVersion.hs (fix applied)"
    fi
else
    echo "✗ src/PostgREST/Config/PgVersion.hs not found"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Query/SqlFragment.hs has response functions without PgVersion..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ]; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs exists"

    # After fix: responseHeadersF should not take PgVersion parameter
    if grep -q "responseHeadersF :: SqlFragment" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✓ responseHeadersF doesn't take PgVersion parameter (fix applied)"
    elif grep -q "responseHeadersF :: PgVersion" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✗ responseHeadersF still takes PgVersion parameter (fix not applied)"
        test_status=1
    fi

    # After fix: responseStatusF should not take PgVersion parameter
    if grep -q "responseStatusF :: SqlFragment" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✓ responseStatusF doesn't take PgVersion parameter (fix applied)"
    elif grep -q "responseStatusF :: PgVersion" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✗ responseStatusF still takes PgVersion parameter (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs not found"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
