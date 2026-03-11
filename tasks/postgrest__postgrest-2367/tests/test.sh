#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/EmbedInnerJoinSpec.hs" "test/spec/Feature/Query/EmbedInnerJoinSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for inaccurate count with inner embeds (PR #2367)..."
echo ""
echo "NOTE: This PR fixes inaccurate result count when an inner embed was selected"
echo "BASE (buggy) has 'else mempty' which clears the WHERE conditions"
echo "HEAD (fixed) has 'else rest' which preserves the WHERE conditions"
echo ""

# Check that CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the fix..."
if grep -q "#2342, Fix inaccurate result count when an inner embed was selected after a normal embed in the query string" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the inner embed count fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

# Check that QueryBuilder.hs has the correct logic (else rest, not else mempty)
echo "Checking src/PostgREST/Query/QueryBuilder.hs has correct logic..."
if grep -A 2 "if joinType == Just JTInner" "src/PostgREST/Query/QueryBuilder.hs" | grep -q "else rest"; then
    echo "✓ QueryBuilder.hs uses 'else rest' (correct)"
else
    echo "✗ QueryBuilder.hs does not use 'else rest' - fix not applied"
    test_status=1
fi

# Verify it's not using the buggy 'else mempty'
if grep -A 2 "if joinType == Just JTInner" "src/PostgREST/Query/QueryBuilder.hs" | grep -q "else mempty"; then
    echo "✗ QueryBuilder.hs still uses 'else mempty' (buggy) - fix not applied"
    test_status=1
else
    echo "✓ QueryBuilder.hs does not use 'else mempty' (buggy code removed)"
fi

# Check that EmbedInnerJoinSpec.hs has the test case for working alongside another embedding
echo "Checking test/spec/Feature/Query/EmbedInnerJoinSpec.hs has the test case..."
if grep -q "works alongside another embedding" "test/spec/Feature/Query/EmbedInnerJoinSpec.hs"; then
    echo "✓ EmbedInnerJoinSpec.hs has 'works alongside another embedding' test"
else
    echo "✗ EmbedInnerJoinSpec.hs missing test case - fix not applied"
    test_status=1
fi

# Check for the specific test case that verifies the order independence
if grep -q "select=id,authors(name),publishers!inner(name)" "test/spec/Feature/Query/EmbedInnerJoinSpec.hs"; then
    echo "✓ Test includes check for select with authors and publishers!inner"
else
    echo "✗ Test missing specific select query - fix not applied"
    test_status=1
fi

if grep -q "select=id,publishers!inner(name),authors(name)" "test/spec/Feature/Query/EmbedInnerJoinSpec.hs"; then
    echo "✓ Test includes check for reversed order (publishers!inner before authors)"
else
    echo "✗ Test missing reversed order check - fix not applied"
    test_status=1
fi

# Check that data.sql has the Dostoevsky author and Crime and Punishment book
echo "Checking test/spec/fixtures/data.sql has test data..."
if grep -q "Fyodor Dostoevsky" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql includes Fyodor Dostoevsky"
else
    echo "✗ data.sql missing Fyodor Dostoevsky - test data incomplete"
    test_status=1
fi

if grep -q "Crime and Punishment" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql includes Crime and Punishment"
else
    echo "✗ data.sql missing Crime and Punishment - test data incomplete"
    test_status=1
fi

# Check that privileges.sql grants access to publishers table
echo "Checking test/spec/fixtures/privileges.sql grants publishers access..."
if grep -q "publishers" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql grants access to publishers"
else
    echo "✗ privileges.sql missing publishers grant - fix not applied"
    test_status=1
fi

# Check that schema.sql has the publishers view
echo "Checking test/spec/fixtures/schema.sql has publishers view..."
if grep -q "create view test.publishers" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql creates publishers view"
else
    echo "✗ schema.sql missing publishers view - fix not applied"
    test_status=1
fi

# Check that books view includes first_publisher_id
if grep -q "first_publisher_id from private.books" "test/spec/fixtures/schema.sql"; then
    echo "✓ books view includes first_publisher_id column"
else
    echo "✗ books view missing first_publisher_id - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - inner embed count fix is applied correctly"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
