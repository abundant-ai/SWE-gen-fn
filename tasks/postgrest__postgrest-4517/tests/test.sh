#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/fixtures.yaml" "test/io/fixtures/fixtures.yaml"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"

test_status=0

echo "Verifying fix for adding db-schemas restrictions on pg_catalog and information_schema (PR #4517)..."
echo ""
echo "NOTE: This PR adds validation that prevents pg_catalog and information_schema in db-schemas config"
echo "BASE (buggy) silently ignores restricted schemas without validation"
echo "HEAD (fixed) validates and rejects these schemas with clear error message"
echo ""

# Check that parseDbSchemas function exists in Config.hs
echo "Checking src/PostgREST/Config.hs contains parseDbSchemas function..."
if grep -q "parseDbSchemas" "src/PostgREST/Config.hs"; then
    echo "✓ parseDbSchemas function exists"
else
    echo "✗ parseDbSchemas function not found - fix not applied"
    test_status=1
fi

# Check that parseDbSchemas validates pg_catalog
echo "Checking parseDbSchemas validates against pg_catalog..."
if grep -A 10 "parseDbSchemas" "src/PostgREST/Config.hs" | grep -q "pg_catalog"; then
    echo "✓ parseDbSchemas checks pg_catalog"
else
    echo "✗ parseDbSchemas does not check pg_catalog - fix not applied"
    test_status=1
fi

# Check that parseDbSchemas validates information_schema
echo "Checking parseDbSchemas validates against information_schema..."
if grep -A 10 "parseDbSchemas" "src/PostgREST/Config.hs" | grep -q "information_schema"; then
    echo "✓ parseDbSchemas checks information_schema"
else
    echo "✗ parseDbSchemas does not check information_schema - fix not applied"
    test_status=1
fi

# Check that CHANGELOG mentions the restricted schemas feature
echo "Checking CHANGELOG.md mentions db-schemas restriction feature..."
if grep -q "Log error when.*db-schemas.*config contain" "CHANGELOG.md" && grep -q "pg_catalog\|information_schema" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions the restriction feature"
else
    echo "✗ CHANGELOG does not mention restriction feature - fix not applied"
    test_status=1
fi

# Check that docs mention the restriction
echo "Checking docs/references/api/schemas.rst mentions restriction..."
if grep -q "pg_catalog.*and.*information_schema.*are not allowed" "docs/references/api/schemas.rst" || grep -q "not allowed.*pg_catalog\|not allowed.*information_schema" "docs/references/api/schemas.rst"; then
    echo "✓ Documentation mentions the restriction"
else
    echo "✗ Documentation does not mention restriction - fix not applied"
    test_status=1
fi

# Check that test_restricted_db_schemas test exists
echo "Checking test/io/test_cli.py contains test_restricted_db_schemas..."
if grep -q "test_restricted_db_schemas" "test/io/test_cli.py"; then
    echo "✓ test_restricted_db_schemas test exists"
else
    echo "✗ test_restricted_db_schemas test not found - fix not applied"
    test_status=1
fi

# Check that restrictedschemas fixture exists
echo "Checking test/io/fixtures/fixtures.yaml contains restrictedschemas..."
if grep -q "restrictedschemas:" "test/io/fixtures/fixtures.yaml"; then
    echo "✓ restrictedschemas fixture exists"
else
    echo "✗ restrictedschemas fixture not found - fix not applied"
    test_status=1
fi

# Check that the error message for restricted schemas exists in Config.hs
echo "Checking Config.hs contains restriction error message..."
if grep -q "db-schemas does not allow schema" "src/PostgREST/Config.hs"; then
    echo "✓ Restriction error message exists"
else
    echo "✗ Restriction error message not found - fix not applied"
    test_status=1
fi

# Verify the test checks for pg_catalog
echo "Checking test validates pg_catalog is restricted..."
if grep -A 5 "test_restricted_db_schemas" "test/io/test_cli.py" | grep -q "pg_catalog"; then
    echo "✓ Test validates pg_catalog restriction"
else
    echo "✗ Test does not validate pg_catalog - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - db-schemas restriction feature applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
