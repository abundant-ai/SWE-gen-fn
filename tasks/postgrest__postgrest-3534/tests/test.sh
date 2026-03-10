#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that Error.hs has the correct status code mapping for 54* errors
echo "Checking that Error.hs maps 54* errors to status 500..."
if grep -q "'5':'4':_ -> HTTP.status500" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs maps 54* errors to status 500 - fix applied!"
else
    echo "✗ Error.hs doesn't map 54* errors to status 500 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs doesn't map 54* errors to status 413..."
if ! grep -q "'5':'4':_ -> HTTP.status413" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs doesn't have incorrect 413 mapping - fix applied!"
else
    echo "✗ Error.hs still has incorrect 413 mapping - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ErrorSpec.hs has the test for statement too complex returning 500..."
if grep -q "should return 500 for statement too complex" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs has test for 500 status on complex statement - fix applied!"
else
    echo "✗ ErrorSpec.hs missing test for 500 status - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ErrorSpec.hs test expects status 500 not 413..."
if grep -q "matchStatus = 500" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs test expects status 500 - fix applied!"
else
    echo "✗ ErrorSpec.hs test doesn't expect status 500 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that schema.sql has infinite_inserts table..."
if grep -q "create table test.infinite_inserts" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has infinite_inserts table - fix applied!"
else
    echo "✗ schema.sql missing infinite_inserts table - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs/references/errors.rst has correct status code mapping..."
if grep -q "| 54\*.*| 500.*| too complex" "docs/references/errors.rst"; then
    echo "✓ errors.rst maps 54* to 500 - fix applied!"
else
    echo "✗ errors.rst doesn't map 54* to 500 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions the fix..."
if grep -q "#3255" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions PR #3255 - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention PR #3255 - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
