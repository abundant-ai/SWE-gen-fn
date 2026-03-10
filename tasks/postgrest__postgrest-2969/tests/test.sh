#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PreferencesSpec.hs" "test/spec/Feature/Query/PreferencesSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

# Check that CHANGELOG.md has the fix entry for #2943
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2943.*handling=strict/lenient.*Prefer' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that postgrest.cabal includes PreferencesSpec test module
echo "Checking postgrest.cabal includes PreferencesSpec..."
if grep -q 'Feature.Query.PreferencesSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PreferencesSpec"
else
    echo "✗ postgrest.cabal missing PreferencesSpec - fix not applied"
    test_status=1
fi

# Check that Preferences.hs has PreferHandling type
echo "Checking Preferences.hs has PreferHandling type..."
if grep -q 'data PreferHandling' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'Strict.*-- \^ Throw error on unrecognised preferences' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'Lenient.*-- \^ Ignore unrecognised preferences' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has PreferHandling type with Strict and Lenient"
else
    echo "✗ Preferences.hs missing PreferHandling type - fix not applied"
    test_status=1
fi

# Check that Preferences data type has preferHandling and invalidPrefs fields
echo "Checking Preferences data type has new fields..."
if grep -q 'preferHandling.*:: Maybe PreferHandling' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'invalidPrefs.*:: \[ByteString\]' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences data type has preferHandling and invalidPrefs fields"
else
    echo "✗ Preferences data type missing new fields - fix not applied"
    test_status=1
fi

# Check that ToHeaderValue instance exists for PreferHandling
echo "Checking ToHeaderValue instance for PreferHandling..."
if grep -q 'toHeaderValue Strict.*=.*"handling=strict"' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'toHeaderValue Lenient.*=.*"handling=lenient"' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ ToHeaderValue instance for PreferHandling is correct"
else
    echo "✗ ToHeaderValue instance for PreferHandling missing - fix not applied"
    test_status=1
fi

# Check that Error.hs has PGRST122 error code
echo "Checking Error.hs has PGRST122 error code..."
if grep -q 'ApiRequestErrorCode22' "src/PostgREST/Error.hs" && \
   grep -q 'ApiRequestErrorCode22.*->.*"122"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has PGRST122 error code (ApiRequestErrorCode22)"
else
    echo "✗ Error.hs missing PGRST122 error code - fix not applied"
    test_status=1
fi

# Check that InvalidPreferences error type exists
echo "Checking Types.hs has InvalidPreferences error type..."
if grep -q 'InvalidPreferences \[ByteString\]' "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has InvalidPreferences error type"
else
    echo "✗ Types.hs missing InvalidPreferences error type - fix not applied"
    test_status=1
fi

# Check that Error.hs has InvalidPreferences JSON serialization
echo "Checking Error.hs has InvalidPreferences JSON serialization..."
if grep -q 'toJSON (InvalidPreferences prefs)' "src/PostgREST/Error.hs" && \
   grep -q '"Invalid preferences given with handling=strict"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has InvalidPreferences JSON serialization"
else
    echo "✗ Error.hs missing InvalidPreferences JSON serialization - fix not applied"
    test_status=1
fi

# Check that Plan.hs validates preferences with handling=strict
echo "Checking Plan.hs validates preferences when handling=strict..."
if grep -q 'if not (null invalidPrefs) && preferHandling == Just Strict' "src/PostgREST/Plan.hs" && \
   grep -q 'InvalidPreferences invalidPrefs' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs validates preferences when handling=strict"
else
    echo "✗ Plan.hs missing preference validation - fix not applied"
    test_status=1
fi

# Check that PreferencesSpec.hs has tests for handling=strict
echo "Checking PreferencesSpec.hs has tests for handling=strict..."
if grep -q 'check prefer: handling=strict and handling=lenient' "test/spec/Feature/Query/PreferencesSpec.hs" && \
   grep -q 'throws error when handling=strict and invalid prefs are given' "test/spec/Feature/Query/PreferencesSpec.hs" && \
   grep -q '"details":"Invalid preferences: anything"' "test/spec/Feature/Query/PreferencesSpec.hs" && \
   grep -q '"code":"PGRST122"' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has tests for handling=strict"
else
    echo "✗ PreferencesSpec.hs missing tests for handling=strict - fix not applied"
    test_status=1
fi

# Check that PreferencesSpec.hs has tests for handling=lenient
echo "Checking PreferencesSpec.hs has tests for handling=lenient..."
if grep -q 'check behaviour of Prefer: handling=lenient' "test/spec/Feature/Query/PreferencesSpec.hs" && \
   grep -q 'does not throw error when handling=lenient and invalid prefs' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has tests for handling=lenient"
else
    echo "✗ PreferencesSpec.hs missing tests for handling=lenient - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
