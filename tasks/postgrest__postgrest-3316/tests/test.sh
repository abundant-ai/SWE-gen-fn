#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/pgbench/2676"
cp "/tests/pgbench/2676/new.sql" "test/pgbench/2676/new.sql"
mkdir -p "test/pgbench/2676"
cp "/tests/pgbench/2676/old.sql" "test/pgbench/2676/old.sql"
mkdir -p "test/pgbench"
cp "/tests/pgbench/README.md" "test/pgbench/README.md"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that src/PostgREST/Query/SqlFragment.hs has the isJsonObject check
echo "Checking that src/PostgREST/Query/SqlFragment.hs has isJsonObject validation..."
if grep -q "isJsonObject = -- light validation" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs has isJsonObject validation"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing isJsonObject validation - fix not applied"
    test_status=1
fi

# Check that it checks for insignificant whitespace
echo "Checking that src/PostgREST/Query/SqlFragment.hs handles insignificant whitespace..."
if grep -q "insignificantWhitespace = \[32,9,10,13\]" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs handles insignificant whitespace"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing whitespace handling - fix not applied"
    test_status=1
fi

# Check that it checks for opening brace
echo "Checking that src/PostgREST/Query/SqlFragment.hs checks for opening brace..."
if grep -q 'LBS.take 1 (LBS.dropWhile (`elem` insignificantWhitespace) (fromMaybe mempty body)) == "{"' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs checks for opening brace"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing brace check - fix not applied"
    test_status=1
fi

# Check that json_typeof and jsonb_typeof are NOT used in the SQL generation
echo "Checking that json_typeof/jsonb_typeof are removed from SQL queries..."
if grep -q "jsonTypeofF" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✗ src/PostgREST/Query/SqlFragment.hs still uses jsonTypeofF - fix not applied"
    test_status=1
elif grep -q "jsonBuildArrayF" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✗ src/PostgREST/Query/SqlFragment.hs still uses jsonBuildArrayF - fix not applied"
    test_status=1
elif grep -q "pgrst_uniform_json" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✗ src/PostgREST/Query/SqlFragment.hs still uses pgrst_uniform_json - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/Query/SqlFragment.hs no longer uses json_typeof/jsonb_typeof"
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "#2676, Performance improvement on bulk json inserts" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that test files exist
echo "Checking that test benchmark files exist..."
if [ -f "test/pgbench/2676/new.sql" ] && [ -f "test/pgbench/2676/old.sql" ]; then
    echo "✓ test/pgbench/2676/ benchmark files exist"
else
    echo "✗ test/pgbench/2676/ benchmark files missing - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
