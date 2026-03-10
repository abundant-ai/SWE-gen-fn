#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md has the entry for #3256
echo "Checking that CHANGELOG.md has the entry for #3256..."
if grep -q "#3256, Fix wrong http status for pg error \`42P17 infinite recursion\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3256"
else
    echo "✗ CHANGELOG.md missing entry for #3256 - fix not applied"
    test_status=1
fi

# Check that docs/references/errors.rst has the 42P17 entry
echo "Checking that docs/references/errors.rst has the 42P17 entry..."
if grep -q "| 42P17" "docs/references/errors.rst" && grep -q "| 500" "docs/references/errors.rst" && grep -q "| infinite recursion" "docs/references/errors.rst"; then
    echo "✓ docs/references/errors.rst has 42P17 error code mapping"
else
    echo "✗ docs/references/errors.rst missing 42P17 entry - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs has the "42P17" -> HTTP.status500 mapping
echo "Checking that src/PostgREST/Error.hs has the 42P17 error handling..."
if grep -q '"42P17".*->.*HTTP.status500.*-- infinite recursion' "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has 42P17 -> HTTP.status500 mapping"
else
    echo "✗ src/PostgREST/Error.hs missing 42P17 error handling - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
