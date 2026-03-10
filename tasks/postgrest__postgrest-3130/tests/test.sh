#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/MultipleSchemaSpec.hs" "test/spec/Feature/Query/MultipleSchemaSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3124, Fix table's media type handlers not working for all schemas" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs uses ANY(\$1) instead of hardcoded '{test}'
echo "Checking that SchemaCache.hs uses ANY(\$1) for schema filtering..."
if grep -q "proc_schema.nspname = ANY(\$1) and" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses dynamic schema parameter ANY(\$1)"
else
    echo "✗ SchemaCache.hs not using ANY(\$1) - still hardcoded to '{test}' - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs does NOT have the hardcoded '{test}' bug
echo "Checking that SchemaCache.hs does NOT have hardcoded '{test}' schema..."
if ! grep -q "proc_schema.nspname = ANY('{test}') and" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs does not have hardcoded '{test}'"
else
    echo "✗ SchemaCache.hs still has hardcoded '{test}' - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs has the schema filter in the second union query
echo "Checking that SchemaCache.hs has schema filter in return type handler query..."
if grep -q "where" "src/PostgREST/SchemaCache.hs" && grep -q "pro_sch.nspname = ANY(\$1) and NOT proretset" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has schema filter for return type handlers"
else
    echo "✗ SchemaCache.hs missing schema filter for return type handlers - fix not applied"
    test_status=1
fi

# Check that memory test has correct threshold (27M not 26M)
echo "Checking that memory-tests.sh has correct memory threshold..."
if grep -q 'jsonKeyTest "1M" "POST" "/rpc/leak?columns=blob" "27M"' "test/memory/memory-tests.sh"; then
    echo "✓ memory-tests.sh has correct 27M threshold"
else
    echo "✗ memory-tests.sh has wrong threshold - fix not applied"
    test_status=1
fi

# Check that MultipleSchemaSpec.hs includes tests for media handlers with domains
echo "Checking that MultipleSchemaSpec.hs includes media handler tests..."
if grep -q "succeeds in calling handler with a domain on another schema" "test/spec/Feature/Query/MultipleSchemaSpec.hs"; then
    echo "✓ MultipleSchemaSpec.hs includes media handler tests"
else
    echo "✗ MultipleSchemaSpec.hs missing media handler tests - fix not applied"
    test_status=1
fi

# Check that schema.sql includes media handler functions
echo "Checking that schema.sql includes media handler functions..."
if grep -q "create function v2.get_plain_text()" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes get_plain_text() function"
else
    echo "✗ schema.sql missing media handler functions - fix not applied"
    test_status=1
fi

# Check that schema.sql includes the special media type domain
echo "Checking that schema.sql includes special media type domain..."
if grep -q 'create domain v2."text/special"' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes text/special domain"
else
    echo "✗ schema.sql missing text/special domain - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
