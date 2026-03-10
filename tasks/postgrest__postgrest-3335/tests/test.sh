#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/big_schema.sql" "test/io/big_schema.sql"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that src/PostgREST/AppState.hs has the fix applied
# The fix moves putSchemaCache to AFTER the observer calls (not before)
echo "Checking that src/PostgREST/AppState.hs has putSchemaCache after observer calls..."
if grep -A5 "Right sCache -> do" "src/PostgREST/AppState.hs" | grep -q "observer.*SchemaCacheQueriedObs" && \
   grep -A10 "Right sCache -> do" "src/PostgREST/AppState.hs" | grep -q "observer.*SchemaCacheLoadedObs" && \
   grep -A15 "Right sCache -> do" "src/PostgREST/AppState.hs" | grep -q "putSchemaCache appState.*Just sCache"; then
    # Now verify putSchemaCache comes AFTER the observers (not before)
    # Extract the order and check
    order=$(grep -A15 "Right sCache -> do" "src/PostgREST/AppState.hs" | grep -n -E "(observer.*SchemaCacheQueriedObs|putSchemaCache appState.*Just sCache)" | head -2)
    first_line=$(echo "$order" | head -1 | cut -d: -f1)
    second_line=$(echo "$order" | tail -1 | cut -d: -f1)

    if echo "$order" | head -1 | grep -q "SchemaCacheQueriedObs" && \
       echo "$order" | tail -1 | grep -q "putSchemaCache"; then
        echo "✓ src/PostgREST/AppState.hs has putSchemaCache after observers - fix applied"
    else
        echo "✗ src/PostgREST/AppState.hs has putSchemaCache in wrong order - fix not applied"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/AppState.hs missing required code structure - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "#3327, Fix slow responses on schema cache reloads" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that test_big_schema.py has the test for NOT waiting (fast responses)
echo "Checking that test_big_schema.py has test_requests_do_not_wait_for_schema_cache_reload..."
if grep -q "def test_requests_do_not_wait_for_schema_cache_reload" "test/io/test_big_schema.py"; then
    echo "✓ test_big_schema.py has correct test name"
else
    echo "✗ test_big_schema.py missing correct test - fix not applied"
    test_status=1
fi

# Check that test expects fast response (plan_dur < 2.0)
echo "Checking that test expects fast response (plan_dur < 2.0)..."
if grep -A25 "def test_requests_do_not_wait_for_schema_cache_reload" "test/io/test_big_schema.py" | grep -q "assert plan_dur < 2.0"; then
    echo "✓ test expects fast response"
else
    echo "✗ test does not expect fast response - fix not applied"
    test_status=1
fi

# Check that big_schema.sql has the notify_pgrst function
echo "Checking that big_schema.sql has notify_pgrst function..."
if grep -q "create or replace function apflora.notify_pgrst" "test/io/big_schema.sql"; then
    echo "✓ big_schema.sql has notify_pgrst function"
else
    echo "✗ big_schema.sql missing notify_pgrst function - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
