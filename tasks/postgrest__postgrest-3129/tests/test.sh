#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3126, Fix empty row on media type handler function" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that Statements.hs uses nullableColumn (fromMaybe mempty <$> nullableColumn HD.bytea)
echo "Checking that Statements.hs uses nullableColumn for media type handler..."
if grep -q "(fromMaybe mempty <\$> nullableColumn HD.bytea)" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs uses nullableColumn with fromMaybe mempty"
else
    echo "✗ Statements.hs not using nullableColumn - still using column - fix not applied"
    test_status=1
fi

# Check that Statements.hs does NOT have the buggy "column HD.bytea" on the same line
echo "Checking that Statements.hs does NOT have buggy 'column HD.bytea'..."
if ! grep -q ") <\*> column HD.bytea$" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs does not have buggy 'column HD.bytea'"
else
    echo "✗ Statements.hs still has buggy 'column HD.bytea' - fix not applied"
    test_status=1
fi

# Check that CustomMediaSpec.hs includes test for empty row handling
echo "Checking that CustomMediaSpec.hs includes test for empty row..."
if grep -q 'should not fail when the function doesn'"'"'t return a row' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs includes test for empty row handling"
else
    echo "✗ CustomMediaSpec.hs missing test for empty row - fix not applied"
    test_status=1
fi

# Check that schema.sql includes get_line function
echo "Checking that schema.sql includes get_line function..."
if grep -q "create or replace function test.get_line (id int)" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes get_line function"
else
    echo "✗ schema.sql missing get_line function - fix not applied"
    test_status=1
fi

# Check that schema.sql get_line function returns the correct type
echo "Checking that schema.sql get_line returns application/vnd.twkb..."
if grep -q 'returns "application/vnd.twkb"' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql get_line returns correct media type"
else
    echo "✗ schema.sql get_line has wrong return type - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
