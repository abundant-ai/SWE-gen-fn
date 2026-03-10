#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpsertSpec.hs" "test/spec/Feature/Query/UpsertSpec.hs"

test_status=0

echo "Verifying fix for Preference-Applied header support..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#740, Add `Preference-Applied` in response for `Prefer: return=representation/headers-only/minimal`' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check Preferences.hs has ToAppliedHeader instance
echo "Checking src/PostgREST/ApiRequest/Preferences.hs for ToAppliedHeader instance..."
if grep -q 'instance ToAppliedHeader PreferRepresentation' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has ToAppliedHeader instance"
else
    echo "✗ Preferences.hs missing ToAppliedHeader instance - fix not applied"
    test_status=1
fi

# Check Response.hs has concatPrefAppsHeaders function
echo "Checking src/PostgREST/Response.hs for concatPrefAppsHeaders function..."
if grep -q 'concatPrefAppsHeaders' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has concatPrefAppsHeaders function"
else
    echo "✗ Response.hs missing concatPrefAppsHeaders function - fix not applied"
    test_status=1
fi

# Check Response.hs has addPrefToHeaders function
echo "Checking src/PostgREST/Response.hs for addPrefToHeaders function..."
if grep -q 'addPrefToHeaders' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has addPrefToHeaders function"
else
    echo "✗ Response.hs missing addPrefToHeaders function - fix not applied"
    test_status=1
fi

# Check that preferRepresentation is Maybe type (after fix)
echo "Checking src/PostgREST/ApiRequest/Preferences.hs for Maybe PreferRepresentation type..."
if grep -q ', preferRepresentation :: Maybe PreferRepresentation' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has Maybe PreferRepresentation type"
else
    echo "✗ Preferences.hs missing Maybe PreferRepresentation type - fix not applied"
    test_status=1
fi

# Check Plan.hs uses pattern matching with Just for preferRepresentation
echo "Checking src/PostgREST/Plan.hs for Just pattern matching..."
if grep -q 'preferRepresentation == Just None || isNothing preferRepresentation' "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has correct Just pattern matching"
else
    echo "✗ Plan.hs missing correct Just pattern matching - fix not applied"
    test_status=1
fi

# Check Response.hs uses addPrefToHeaders with Just Full
echo "Checking src/PostgREST/Response.hs for addPrefToHeaders usage with Just Full..."
if grep -q 'Just Full -> response HTTP.status201 (addPrefToHeaders headers Full' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has addPrefToHeaders with Just Full"
else
    echo "✗ Response.hs missing addPrefToHeaders with Just Full - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
