#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RelatedQueriesSpec.hs" "test/spec/Feature/Query/RelatedQueriesSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for null filtering on embedded resource when column name equals relation name..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2862, Fix null filtering on embedded resource when using a column name equal to the relation name' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that the problematic line was removed from Plan.hs
echo "Checking src/PostgREST/Plan.hs for removal of UnacceptableFilter line..."
if grep -q 'Just ReadPlan{relName}, _.*Left.*UnacceptableFilter relName' "src/PostgREST/Plan.hs"; then
    echo "✗ Plan.hs still contains the problematic line - fix not applied"
    test_status=1
else
    echo "✓ Plan.hs does not contain the problematic line"
fi

# Check that the test cases for the fix were added to RelatedQueriesSpec.hs
echo "Checking test/spec/Feature/Query/RelatedQueriesSpec.hs for new test cases..."
if grep -q "doesn't interfere filtering on column names used for disambiguation" "test/spec/Feature/Query/RelatedQueriesSpec.hs"; then
    echo "✓ RelatedQueriesSpec.hs has test case for user_friend filtering"
else
    echo "✗ RelatedQueriesSpec.hs missing test case for user_friend filtering - fix not applied"
    test_status=1
fi

if grep -q "doesn't interfere filtering on column names that are the same as the relation name" "test/spec/Feature/Query/RelatedQueriesSpec.hs"; then
    echo "✓ RelatedQueriesSpec.hs has test case for tournaments filtering"
else
    echo "✗ RelatedQueriesSpec.hs missing test case for tournaments filtering - fix not applied"
    test_status=1
fi

# Check that schema.sql includes the tables for the test cases
echo "Checking test/spec/fixtures/schema.sql for profiles and user_friend tables..."
if grep -q 'create table profiles' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has profiles table"
else
    echo "✗ schema.sql missing profiles table - fix not applied"
    test_status=1
fi

if grep -q 'create table user_friend' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has user_friend table"
else
    echo "✗ schema.sql missing user_friend table - fix not applied"
    test_status=1
fi

if grep -q 'create table tournaments' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has tournaments table"
else
    echo "✗ schema.sql missing tournaments table - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
