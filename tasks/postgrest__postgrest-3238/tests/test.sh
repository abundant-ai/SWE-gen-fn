#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/__snapshots__/test_cli"
cp "/tests/io/__snapshots__/test_cli/test_schema_cache_snapshot.yaml" "test/io/__snapshots__/test_cli/test_schema_cache_snapshot.yaml"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that src/PostgREST/SchemaCache.hs properly serializes dbMediaHandlers and dbTimezones
echo "Checking that src/PostgREST/SchemaCache.hs serializes media handlers and timezones..."
if grep -q '"dbMediaHandlers"   .= JSON.toJSON hdlers' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs serializes dbMediaHandlers"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing dbMediaHandlers serialization - fix not applied"
    test_status=1
fi

if grep -q '"dbTimezones"       .= JSON.toJSON tzs' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs serializes dbTimezones"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing dbTimezones serialization - fix not applied"
    test_status=1
fi

# Check that MediaType derives JSON.ToJSON
echo "Checking that src/PostgREST/MediaType.hs has JSON.ToJSON derivation..."
if grep -q "deriving (Eq, Show, Generic, JSON.ToJSON)" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has JSON.ToJSON derivation"
else
    echo "✗ src/PostgREST/MediaType.hs missing JSON.ToJSON derivation - fix not applied"
    test_status=1
fi

# Check that MediaHandler derives JSON.ToJSON
echo "Checking that src/PostgREST/SchemaCache/Routine.hs has MediaHandler JSON.ToJSON derivation..."
if grep -q "deriving (Eq, Show, Generic, JSON.ToJSON)" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs has MediaHandler JSON.ToJSON derivation"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs missing MediaHandler JSON.ToJSON derivation - fix not applied"
    test_status=1
fi

# Check that TimezoneNames uses Set Text instead of Set ByteString
echo "Checking that src/PostgREST/Config/Database.hs uses Set Text for TimezoneNames..."
if grep -q "type TimezoneNames    = Set Text" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs uses Set Text for TimezoneNames"
else
    echo "✗ src/PostgREST/Config/Database.hs still uses Set ByteString - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking that CHANGELOG.md mentions the fix..."
if grep -q "#3237, Dump media handlers and timezones with --dump-schema" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that syrupy is in the test dependencies
echo "Checking that nix/tools/tests.nix includes syrupy..."
if grep -q "ps.syrupy" "nix/tools/tests.nix"; then
    echo "✓ nix/tools/tests.nix includes syrupy"
else
    echo "✗ nix/tools/tests.nix missing syrupy - fix not applied"
    test_status=1
fi

# Check that test files exist
echo "Checking that test snapshot files exist..."
if [ -f "test/io/__snapshots__/test_cli/test_schema_cache_snapshot.yaml" ] && [ -f "test/io/test_cli.py" ]; then
    echo "✓ test/io/ test files exist"
else
    echo "✗ test/io/ test files missing - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
