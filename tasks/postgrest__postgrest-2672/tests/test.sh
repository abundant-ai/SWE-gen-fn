#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/pgbench/1567"
cp "/tests/pgbench/1567/new.sql" "test/pgbench/1567/new.sql"
mkdir -p "test/pgbench/1567"
cp "/tests/pgbench/1567/old.sql" "test/pgbench/1567/old.sql"
mkdir -p "test/pgbench"
cp "/tests/pgbench/README.md" "test/pgbench/README.md"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for bulk INSERT/PATCH with columns parameter..."
echo ""
echo "NOTE: This PR adds support for undefined JSON keys to use DEFAULT column values"
echo "HEAD (fixed) should have PreferUndefinedKeys and apply-defaults logic."
echo "BASE (buggy) lacks the undefined-keys preference handling."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #1567 entry
echo "Checking CHANGELOG.md has PR #1567 entry..."
if grep -q "#1567, On bulk inserts with" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #1567 entry"
else
    echo "✗ CHANGELOG.md missing PR #1567 entry - fix not applied"
    test_status=1
fi

# Check Preferences.hs - HEAD should export PreferUndefinedKeys
echo "Checking src/PostgREST/ApiRequest/Preferences.hs exports PreferUndefinedKeys..."
if grep -q "PreferUndefinedKeys(..)" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs exports PreferUndefinedKeys"
else
    echo "✗ Preferences.hs missing PreferUndefinedKeys export - fix not applied"
    test_status=1
fi

# Check Preferences.hs - HEAD should have preferUndefinedKeys field in Preferences data type
echo "Checking Preferences.hs has preferUndefinedKeys field..."
if grep -q "preferUndefinedKeys" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has preferUndefinedKeys field"
else
    echo "✗ Preferences.hs missing preferUndefinedKeys field - fix not applied"
    test_status=1
fi

# Check Preferences.hs - HEAD should define PreferUndefinedKeys data type with ApplyDefaults
echo "Checking Preferences.hs defines PreferUndefinedKeys data type..."
if grep -q "data PreferUndefinedKeys" "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q "ApplyDefaults" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs defines PreferUndefinedKeys with ApplyDefaults"
else
    echo "✗ Preferences.hs missing PreferUndefinedKeys data type - fix not applied"
    test_status=1
fi

# Check Preferences.hs - HEAD should parse undefined-keys preference
echo "Checking Preferences.hs parses undefined-keys preference..."
if grep -q "parsePrefs \[ApplyDefaults, IgnoreDefaults\]" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs parses undefined-keys preference"
else
    echo "✗ Preferences.hs missing undefined-keys parsing - fix not applied"
    test_status=1
fi

# Check Preferences.hs - HEAD should have toHeaderValue for undefined-keys
echo "Checking Preferences.hs has toHeaderValue for undefined-keys..."
if grep -q "undefined-keys=apply-defaults" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has toHeaderValue for undefined-keys"
else
    echo "✗ Preferences.hs missing toHeaderValue for undefined-keys - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should use preferUndefinedKeys in mutation plan
echo "Checking src/PostgREST/Plan.hs uses preferUndefinedKeys..."
if grep -q "preferUndefinedKeys" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs uses preferUndefinedKeys"
else
    echo "✗ Plan.hs missing preferUndefinedKeys usage - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should handle undefined keys for inserts
echo "Checking src/PostgREST/Query/QueryBuilder.hs handles undefined keys..."
if grep -q "applyDefaults" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs handles undefined keys"
else
    echo "✗ QueryBuilder.hs missing undefined keys handling - fix not applied"
    test_status=1
fi

# Check test files exist
echo "Checking test files exist..."
if [ -f "test/pgbench/1567/new.sql" ] && [ -f "test/pgbench/1567/old.sql" ]; then
    echo "✓ pgbench test files exist"
else
    echo "✗ pgbench test files missing - fix not applied"
    test_status=1
fi

# Check InsertSpec.hs - HEAD should have tests for undefined keys with defaults
echo "Checking test/spec/Feature/Query/InsertSpec.hs has undefined keys tests..."
if grep -q "undefined-keys" "test/spec/Feature/Query/InsertSpec.hs" || \
   grep -q "apply-defaults" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has undefined keys tests"
else
    echo "✗ InsertSpec.hs missing undefined keys tests - fix not applied"
    test_status=1
fi

# Check UpdateSpec.hs - HEAD should have tests for undefined keys in PATCH
echo "Checking test/spec/Feature/Query/UpdateSpec.hs has undefined keys tests..."
if grep -q "undefined-keys" "test/spec/Feature/Query/UpdateSpec.hs" || \
   grep -q "apply-defaults" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has undefined keys tests"
else
    echo "✗ UpdateSpec.hs missing undefined keys tests - fix not applied"
    test_status=1
fi

# Check schema.sql or data.sql has complex_items table with defaults
echo "Checking test fixtures have complex_items table..."
if grep -q "complex_items" "test/spec/fixtures/schema.sql" || \
   grep -q "complex_items" "test/spec/fixtures/data.sql"; then
    echo "✓ Test fixtures have complex_items table"
else
    echo "✗ Test fixtures missing complex_items table - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - undefined-keys feature properly implemented"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
