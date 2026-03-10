#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for DOMAIN default values..."
echo ""

# Check CHANGELOG.md for the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q "#2840, Fix \`Prefer: missing=default\` with DOMAIN default values" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs for the typbasetype handling in columnDefault
echo "Checking src/PostgREST/SchemaCache.hs for typbasetype handling in columnDefault..."
if grep -A 3 "columnDefault" "src/PostgREST/SchemaCache.hs" | grep -q "t.typbasetype  != 0  THEN pg_get_expr(t.typdefaultbin, 0)"; then
    echo "✓ src/PostgREST/SchemaCache.hs has typbasetype handling for DOMAIN defaults"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing typbasetype handling - fix not applied"
    test_status=1
fi

# Check that the columnDefault is used in the proper context (AS column_default, moved to outer query)
echo "Checking src/PostgREST/SchemaCache.hs for proper columnDefault context..."
if grep -q "\|] <> columnDefault <> \[q| AS column_default," "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has columnDefault in proper context with AS column_default,"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing proper columnDefault context - fix not applied"
    test_status=1
fi

# Check that columnDefault comment includes typbasetype explanation
echo "Checking src/PostgREST/SchemaCache.hs for columnDefault comment with typbasetype..."
if grep -q "columnDefault -- typbasetype and typdefaultbin handles" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has columnDefault comment explaining typbasetype"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing columnDefault comment - fix not applied"
    test_status=1
fi

# Check that pgVersion120 columnDefault does NOT have inline "AS column_default," (it's in outer context now)
echo "Checking src/PostgREST/SchemaCache.hs for pgVersion120 columnDefault structure..."
if ! grep -A 5 "pgVer >= pgVersion120" "src/PostgREST/SchemaCache.hs" | grep -q "END AS column_default"; then
    echo "✓ src/PostgREST/SchemaCache.hs pgVersion120 has correct structure (no inline AS column_default)"
else
    echo "✗ src/PostgREST/SchemaCache.hs pgVersion120 incorrect structure - fix not applied"
    test_status=1
fi

# Check that pgVersion100 columnDefault does NOT have inline "AS column_default," (it's in outer context now)
echo "Checking src/PostgREST/SchemaCache.hs for pgVersion100 columnDefault structure..."
if ! grep -A 5 "pgVer >= pgVersion100" "src/PostgREST/SchemaCache.hs" | grep -q "END AS column_default"; then
    echo "✓ src/PostgREST/SchemaCache.hs pgVersion100 has correct structure (no inline AS column_default)"
else
    echo "✗ src/PostgREST/SchemaCache.hs pgVersion100 incorrect structure - fix not applied"
    test_status=1
fi

# Check InsertSpec.hs for the test case
echo "Checking test/spec/Feature/Query/InsertSpec.hs for DOMAIN default test..."
if grep -q "inserts a default on a DOMAIN with default" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/InsertSpec.hs has DOMAIN default test"
else
    echo "✗ test/spec/Feature/Query/InsertSpec.hs missing DOMAIN default test - fix not applied"
    test_status=1
fi

# Check schema.sql for evil_friends table
echo "Checking test/spec/fixtures/schema.sql for evil_friends table..."
if grep -q "create table evil_friends" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql has evil_friends table"
else
    echo "✗ test/spec/fixtures/schema.sql missing evil_friends table - fix not applied"
    test_status=1
fi

# Check schema.sql for devil_int domain
echo "Checking test/spec/fixtures/schema.sql for devil_int domain..."
if grep -q "create domain devil_int as int" "test/spec/fixtures/schema.sql" && \
   grep -q "default 666" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql has devil_int domain with default"
else
    echo "✗ test/spec/fixtures/schema.sql missing devil_int domain - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
