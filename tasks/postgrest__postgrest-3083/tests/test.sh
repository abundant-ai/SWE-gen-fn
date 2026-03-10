#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PreferencesSpec.hs" "test/spec/Feature/Query/PreferencesSpec.hs"

# Verify that the fix has been applied by checking test file and source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check PreferencesSpec.hs has the max-affected tests
echo "Checking PreferencesSpec.hs for 'max-affected' test context..."
if grep -q 'context "test Prefer: max-affected with handling=strict"' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has max-affected with handling=strict tests"
else
    echo "✗ PreferencesSpec.hs missing max-affected with handling=strict tests - fix not applied"
    test_status=1
fi

echo "Checking PreferencesSpec.hs for 'max-affected' with handling=lenient tests..."
if grep -q 'context "test Prefer: max-affected with handling=lenient"' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has max-affected with handling=lenient tests"
else
    echo "✗ PreferencesSpec.hs missing max-affected with handling=lenient tests - fix not applied"
    test_status=1
fi

# Check for specific error code PGRST124
echo "Checking PreferencesSpec.hs for PGRST124 error code..."
if grep -q '"code":"PGRST124"' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has PGRST124 error code"
else
    echo "✗ PreferencesSpec.hs missing PGRST124 error code - fix not applied"
    test_status=1
fi

# Check for the error message "Query result exceeds max-affected preference constraint"
echo "Checking PreferencesSpec.hs for max-affected error message..."
if grep -q 'Query result exceeds max-affected preference constraint' "test/spec/Feature/Query/PreferencesSpec.hs"; then
    echo "✓ PreferencesSpec.hs has max-affected error message"
else
    echo "✗ PreferencesSpec.hs missing max-affected error message - fix not applied"
    test_status=1
fi

# Check Preferences.hs for PreferMaxAffected export
echo "Checking Preferences.hs for PreferMaxAffected export..."
if grep -q ', PreferMaxAffected(..)' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs exports PreferMaxAffected"
else
    echo "✗ Preferences.hs missing PreferMaxAffected export - fix not applied"
    test_status=1
fi

# Check Preferences.hs for PreferMaxAffected field in Preferences data type
echo "Checking Preferences.hs for preferMaxAffected field..."
if grep -q 'preferMaxAffected.*:: Maybe PreferMaxAffected' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has preferMaxAffected field"
else
    echo "✗ Preferences.hs missing preferMaxAffected field - fix not applied"
    test_status=1
fi

# Check Preferences.hs for max-affected in example documentation
echo "Checking Preferences.hs for max-affected=100 in documentation..."
if grep -q 'max-affected=100' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has max-affected in documentation examples"
else
    echo "✗ Preferences.hs missing max-affected in documentation - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md for the entry
echo "Checking CHANGELOG.md for the fix entry..."
if grep -q "#2887, Add Preference \`max-affected\` to limit affected resources" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
