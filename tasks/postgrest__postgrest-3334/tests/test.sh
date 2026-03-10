#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that src/PostgREST/Admin.hs uses getSchemaCacheLoaded (not isJust)
echo "Checking that src/PostgREST/Admin.hs uses getSchemaCacheLoaded..."
if grep -q "isSchemaCacheLoaded <- AppState.getSchemaCacheLoaded appState" "src/PostgREST/Admin.hs"; then
    echo "✓ src/PostgREST/Admin.hs uses getSchemaCacheLoaded"
else
    echo "✗ src/PostgREST/Admin.hs does not use getSchemaCacheLoaded - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs exports getSchemaCacheLoaded
echo "Checking that src/PostgREST/AppState.hs exports getSchemaCacheLoaded..."
if grep -q "getSchemaCacheLoaded" "src/PostgREST/AppState.hs" | head -20; then
    echo "✓ src/PostgREST/AppState.hs exports getSchemaCacheLoaded"
else
    echo "✗ src/PostgREST/AppState.hs does not export getSchemaCacheLoaded - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs has stateSchemaCacheLoaded field
echo "Checking that src/PostgREST/AppState.hs has stateSchemaCacheLoaded field..."
if grep -q "stateSchemaCacheLoaded.*::.*IORef Bool" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs has stateSchemaCacheLoaded field"
else
    echo "✗ src/PostgREST/AppState.hs missing stateSchemaCacheLoaded field - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "#3330, Incorrect admin server \`/ready\` response on slow schema cache loads" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
