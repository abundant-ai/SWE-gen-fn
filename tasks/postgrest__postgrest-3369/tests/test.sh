#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md does NOT have the entry for #3327 (it should be reverted)
echo "Checking that CHANGELOG.md does NOT have entry for #3327..."
if grep -q "#3327, Fix slow responses on schema cache reloads" "CHANGELOG.md"; then
    echo "✗ CHANGELOG.md still has entry for #3327 - fix not applied (should be reverted)"
    test_status=1
else
    echo "✓ CHANGELOG.md does not have entry for #3327 (correctly reverted)"
fi

# Check that docs/references/schema_cache.rst says requests WILL wait (old behavior restored)
echo "Checking that docs/references/schema_cache.rst says requests will wait..."
if grep -q "Requests will wait until the schema cache reload is done" "docs/references/schema_cache.rst"; then
    echo "✓ docs/references/schema_cache.rst correctly states requests will wait"
else
    echo "✗ docs/references/schema_cache.rst missing wait statement - fix not applied"
    test_status=1
fi

# Check that docs/references/schema_cache.rst does NOT say "no downtime" (that claim should be reverted)
echo "Checking that docs/references/schema_cache.rst does NOT claim 'no downtime'..."
if grep -q "There's no downtime when reloading the schema cache" "docs/references/schema_cache.rst"; then
    echo "✗ docs/references/schema_cache.rst still claims 'no downtime' - fix not applied"
    test_status=1
else
    echo "✓ docs/references/schema_cache.rst does not claim 'no downtime' (correctly reverted)"
fi

# Check that src/PostgREST/AppState.hs has putSchemaCache BEFORE observer calls (reverted position)
echo "Checking that src/PostgREST/AppState.hs has putSchemaCache before observer calls..."
# We need to check the order: putSchemaCache should come before "observer $ SchemaCacheQueriedObs"
if grep -B5 "observer \$ SchemaCacheQueriedObs resultTime" "src/PostgREST/AppState.hs" | grep -q "putSchemaCache appState \$ Just sCache"; then
    echo "✓ src/PostgREST/AppState.hs has putSchemaCache before observer calls (correctly reverted)"
else
    echo "✗ src/PostgREST/AppState.hs putSchemaCache not in correct position - fix not applied"
    test_status=1
fi

# Check that the comment about "it's important to update AppState schema cache only once..." is REMOVED
echo "Checking that the delayed putSchemaCache comment is removed..."
if grep -q "it's important to update AppState schema cache only once it has been fully evaluated" "src/PostgREST/AppState.hs"; then
    echo "✗ src/PostgREST/AppState.hs still has the delayed update comment - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/AppState.hs does not have the delayed update comment (correctly reverted)"
fi

# Check that test/io/test_big_schema.py has the OLD test expecting slow response (plan_dur > 10000.0)
echo "Checking that test/io/test_big_schema.py expects slow response..."
if grep -q "assert plan_dur > 10000.0" "test/io/test_big_schema.py"; then
    echo "✓ test/io/test_big_schema.py expects plan_dur > 10000.0 (correctly reverted)"
else
    echo "✗ test/io/test_big_schema.py does not expect slow response - fix not applied"
    test_status=1
fi

# Check that test name is the old one: test_requests__wait_for_schema_cache_reload
echo "Checking that test has correct name (wait for reload)..."
if grep -q "def test_requests__wait_for_schema_cache_reload" "test/io/test_big_schema.py"; then
    echo "✓ test/io/test_big_schema.py has test_requests__wait_for_schema_cache_reload (correctly reverted)"
else
    echo "✗ test/io/test_big_schema.py missing correct test name - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
