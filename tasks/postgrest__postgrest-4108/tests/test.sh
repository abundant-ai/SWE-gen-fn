#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4108 which fixes db-extra-search-path handling and schema cache error logging
# HEAD state (7470eee10ef) = fix applied
# BASE state (with bug.patch) = broken (missing proper error logging)
# ORACLE state (BASE + fix.patch) = proper error logging with config values (matches HEAD/fix)

test_status=0

echo "Verifying source code matches HEAD state (db-extra-search-path fix applied)..."
echo ""

echo "Checking that SchemaCacheErrorObs includes db-schemas and db-extra-search-path parameters..."
if grep -q 'SchemaCacheErrorObs (NonEmpty Text) \[Text\] SQL.UsageError' "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has SchemaCacheErrorObs with config parameters - fix applied!"
else
    echo "✗ Observation.hs missing config parameters in SchemaCacheErrorObs - fix not applied"
    test_status=1
fi

echo "Checking that schema cache error message includes db-schemas and db-extra-search-path..."
if grep -q 'db-schemas=' "src/PostgREST/Observation.hs" && grep -q 'db-extra-search-path=' "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs error message includes config values - fix applied!"
else
    echo "✗ Observation.hs error message missing config values - fix not applied"
    test_status=1
fi

echo "Checking that AppState passes config values to SchemaCacheErrorObs..."
if grep -q 'SchemaCacheErrorObs configDbSchemas configDbExtraSearchPath e' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs passes config values to error observer - fix applied!"
else
    echo "✗ AppState.hs not passing config values to error observer - fix not applied"
    test_status=1
fi

echo "Checking that CLI passes config values to SchemaCacheErrorObs..."
if grep -q 'SchemaCacheErrorObs configDbSchemas configDbExtraSearchPath e' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs passes config values to error observer - fix applied!"
else
    echo "✗ CLI.hs not passing config values to error observer - fix not applied"
    test_status=1
fi

echo "Checking that test file includes schema cache error observation test..."
if grep -q "test_schema_cache_error_observation" "test/io/test_io.py"; then
    echo "✓ test_io.py includes schema cache error observation test - test from HEAD!"
else
    echo "✗ test_io.py does not include schema cache error observation test - test not from HEAD"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the enhanced fix description..."
if grep -q "Schema Cache load error is now logged including" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions enhanced fix description - fix applied!"
else
    echo "✗ CHANGELOG does not mention enhanced fix description - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
