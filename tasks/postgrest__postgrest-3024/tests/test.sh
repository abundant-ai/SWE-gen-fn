#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PreferencesSpec.hs" "test/spec/Feature/Query/PreferencesSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Check CHANGELOG for the timezone preference mention
echo "Checking CHANGELOG for timezone preference addition..."
if grep -q 'Add timezone in Prefer header' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions timezone in Prefer header addition"
else
    echo "✗ CHANGELOG missing timezone preference entry - fix not applied"
    test_status=1
fi

# Check that PreferTimezone type is defined in Preferences.hs
echo "Checking Preferences.hs for PreferTimezone type..."
if grep -q 'PreferTimezone' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has PreferTimezone type"
else
    echo "✗ Preferences.hs missing PreferTimezone type - fix not applied"
    test_status=1
fi

# Check that preferTimezone field exists in Preferences data type
echo "Checking Preferences.hs for preferTimezone field..."
if grep -q 'preferTimezone' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has preferTimezone field"
else
    echo "✗ Preferences.hs missing preferTimezone field - fix not applied"
    test_status=1
fi

# Check that TimezoneNames type is defined in Config/Database.hs
echo "Checking Config/Database.hs for TimezoneNames type..."
if grep -q 'TimezoneNames' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs has TimezoneNames type"
else
    echo "✗ Config/Database.hs missing TimezoneNames type - fix not applied"
    test_status=1
fi

# Check that dbTimezones field exists in SchemaCache
echo "Checking SchemaCache.hs for dbTimezones field..."
if grep -q 'dbTimezones' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has dbTimezones field"
else
    echo "✗ SchemaCache.hs missing dbTimezones field - fix not applied"
    test_status=1
fi

# Check that timezones query exists in SchemaCache.hs
echo "Checking SchemaCache.hs for timezones query..."
if grep -q 'timezones ::' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has timezones query"
else
    echo "✗ SchemaCache.hs missing timezones query - fix not applied"
    test_status=1
fi

# Check that Query.hs setPgLocals includes timezone setting
echo "Checking Query.hs for timezone SQL in setPgLocals..."
if grep -q 'timezoneSql' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs setPgLocals includes timezoneSql"
else
    echo "✗ Query.hs setPgLocals missing timezoneSql - fix not applied"
    test_status=1
fi

# Check that ApiRequest.hs passes dbTimezones to fromHeaders
echo "Checking ApiRequest.hs for dbTimezones usage..."
if grep -q 'dbTimezones' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes dbTimezones to fromHeaders"
else
    echo "✗ ApiRequest.hs missing dbTimezones usage - fix not applied"
    test_status=1
fi

# Check that PreferencesSpec has timezone tests
echo "Checking PreferencesSpec.hs for timezone tests..."
if grep -q 'timezone=America/Los_Angeles' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has timezone preference tests"
else
    echo "✗ PreferencesSpec.hs missing timezone preference tests - fix not applied"
    test_status=1
fi

# Check that timestamps table exists in schema.sql
echo "Checking schema.sql for timestamps table..."
if grep -q 'create table timestamps' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has timestamps table"
else
    echo "✗ schema.sql missing timestamps table - fix not applied"
    test_status=1
fi

# Check that data.sql has timestamp data
echo "Checking data.sql for timestamp data..."
if grep -q 'INSERT INTO timestamps' "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has timestamp test data"
else
    echo "✗ data.sql missing timestamp test data - fix not applied"
    test_status=1
fi

# Check that nix/tools/withTools.nix uses TZ=$PGTZ
echo "Checking withTools.nix for PGTZ variable..."
if grep -q 'TZ=\$PGTZ' "nix/tools/withTools.nix"; then
    echo "✓ withTools.nix uses TZ=\$PGTZ"
else
    echo "✗ withTools.nix not using TZ=\$PGTZ - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
