#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that src/PostgREST/Admin.hs imports Data.Aeson
echo "Checking that src/PostgREST/Admin.hs imports Data.Aeson as JSON..."
if grep -q "import qualified Data.Aeson                as JSON" "src/PostgREST/Admin.hs"; then
    echo "✓ src/PostgREST/Admin.hs imports Data.Aeson as JSON"
else
    echo "✗ src/PostgREST/Admin.hs missing Data.Aeson import - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Admin.hs has the schema_cache endpoint
echo "Checking that src/PostgREST/Admin.hs has schema_cache endpoint..."
if grep -q '["schema_cache"]' "src/PostgREST/Admin.hs"; then
    echo "✓ src/PostgREST/Admin.hs has schema_cache endpoint"
else
    echo "✗ src/PostgREST/Admin.hs missing schema_cache endpoint - fix not applied"
    test_status=1
fi

# Check that the schema_cache endpoint calls AppState.getSchemaCache
echo "Checking that schema_cache endpoint calls AppState.getSchemaCache..."
if grep -q "sCache <- AppState.getSchemaCache appState" "src/PostgREST/Admin.hs"; then
    echo "✓ schema_cache endpoint calls AppState.getSchemaCache"
else
    echo "✗ schema_cache endpoint missing getSchemaCache call - fix not applied"
    test_status=1
fi

# Check that the schema_cache endpoint encodes and responds
echo "Checking that schema_cache endpoint encodes response..."
if grep -q "respond \$ Wai.responseLBS HTTP.status200 \[\] (maybe mempty JSON.encode sCache)" "src/PostgREST/Admin.hs"; then
    echo "✓ schema_cache endpoint encodes and responds correctly"
else
    echo "✗ schema_cache endpoint missing proper response - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "#3210, Dump schema cache through admin API" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that test_admin_schema_cache test exists
echo "Checking that test/io/test_io.py has test_admin_schema_cache..."
if grep -q "def test_admin_schema_cache(defaultenv):" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has test_admin_schema_cache"
else
    echo "✗ test/io/test_io.py missing test_admin_schema_cache - fix not applied"
    test_status=1
fi

# Check that the test verifies the /schema_cache endpoint
echo "Checking that test_admin_schema_cache tests /schema_cache endpoint..."
if grep -q 'response = postgrest.admin.get("/schema_cache")' "test/io/test_io.py"; then
    echo "✓ test_admin_schema_cache tests /schema_cache endpoint"
else
    echo "✗ test_admin_schema_cache doesn't test /schema_cache endpoint - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
