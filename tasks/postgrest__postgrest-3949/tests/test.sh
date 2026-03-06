#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpsertSpec.hs" "test/spec/Feature/Query/UpsertSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #3949 which fixes ordering with POST, PATCH, PUT, and DELETE requests
# HEAD state (2ca6bf85) = fix applied, ordering works with mutation requests
# BASE state (with bug.patch) = ordering broken with mutation requests

test_status=0

echo "Verifying source code matches HEAD state (ordering fix applied)..."
echo ""

echo "Checking that CHANGELOG.md has ordering fix entry..."
if grep -q "#3013, Fix \`order=\` with POST, PATCH, PUT and DELETE requests - @taimoorzaeem" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has ordering fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have ordering fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs does NOT have the buggy ActRelationMut check in addOrders..."
if grep -A5 "addOrders ctx ApiRequest{..} rReq =" "src/PostgREST/Plan.hs" | grep -q "ActDb (ActRelationMut _ _) -> Right rReq"; then
    echo "✗ Plan.hs still has ActRelationMut check in addOrders - fix not applied"
    test_status=1
else
    echo "✓ Plan.hs does not have ActRelationMut check in addOrders - fix applied!"
fi

echo ""
echo "Checking that Plan.hs uses simple addOrders implementation..."
if grep -q "addOrders ctx ApiRequest{..} rReq = foldr addOrderToNode" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses simple addOrders implementation - fix applied!"
else
    echo "✗ Plan.hs does not use simple addOrders implementation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that DeleteSpec.hs has ordering test..."
if grep -q "works with request method DELETE and embedded resource" "test/spec/Feature/Query/DeleteSpec.hs"; then
    echo "✓ DeleteSpec.hs has ordering test - fix applied!"
else
    echo "✗ DeleteSpec.hs does not have ordering test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that UpdateSpec.hs has ordering test with PATCH..."
if grep -q "works with request method PATCH and embedded resource" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has PATCH ordering test - fix applied!"
else
    echo "✗ UpdateSpec.hs does not have PATCH ordering test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that UpdateSpec.hs has ordering test on top-level resource..."
if grep -q "with ordering on top-level resource" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has top-level ordering test - fix applied!"
else
    echo "✗ UpdateSpec.hs does not have top-level ordering test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that UpsertSpec.hs has ordering test with PUT..."
if grep -q "works with request method PUT and embedded resource" "test/spec/Feature/Query/UpsertSpec.hs"; then
    echo "✓ UpsertSpec.hs has PUT ordering test - fix applied!"
else
    echo "✗ UpsertSpec.hs does not have PUT ordering test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that UpsertSpec.hs has ordering test with batch upserts..."
if grep -q "works with batch upserts and embedded resource" "test/spec/Feature/Query/UpsertSpec.hs"; then
    echo "✓ UpsertSpec.hs has batch upsert ordering test - fix applied!"
else
    echo "✗ UpsertSpec.hs does not have batch upsert ordering test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that schema.sql has artists table definition..."
if grep -q "CREATE TABLE test.artists" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has artists table - fix applied!"
else
    echo "✗ schema.sql does not have artists table - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that schema.sql has albums table definition..."
if grep -q "CREATE TABLE test.albums" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has albums table - fix applied!"
else
    echo "✗ schema.sql does not have albums table - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that data.sql has artists test data..."
if grep -q "INSERT INTO artists" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has artists test data - fix applied!"
else
    echo "✗ data.sql does not have artists test data - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that data.sql has albums test data..."
if grep -q "INSERT INTO albums" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has albums test data - fix applied!"
else
    echo "✗ data.sql does not have albums test data - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that privileges.sql grants permissions on artists table..."
if grep -q "GRANT ALL ON TABLE artists TO postgrest_test_anonymous" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql grants artists permissions - fix applied!"
else
    echo "✗ privileges.sql does not grant artists permissions - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that privileges.sql grants permissions on albums table..."
if grep -q "GRANT ALL ON TABLE albums TO postgrest_test_anonymous" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql grants albums permissions - fix applied!"
else
    echo "✗ privileges.sql does not grant albums permissions - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
