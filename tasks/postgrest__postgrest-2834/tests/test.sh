#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"

test_status=0

echo "Verifying fix for GHC 9.0.2 compatibility (#2834)..."
echo ""

# Check CHANGELOG.md for the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q "#2834, Fix compilation on Ubuntu by being compatible with GHC 9.0.2" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the GHC 9.0.2 compatibility fix entry"
else
    echo "✗ CHANGELOG.md missing GHC 9.0.2 compatibility entry - fix not applied"
    test_status=1
fi

# Check that OverloadedRecordDot is NOT present in Plan.hs
echo "Checking src/PostgREST/Plan.hs for removal of OverloadedRecordDot..."
if grep -q "OverloadedRecordDot" "src/PostgREST/Plan.hs"; then
    echo "✗ src/PostgREST/Plan.hs still has OverloadedRecordDot - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/Plan.hs does not have OverloadedRecordDot"
fi

# Check that mutatePlan uses Preferences{..} pattern match instead of preferences variable
echo "Checking src/PostgREST/Plan.hs for Preferences{..} pattern match..."
if grep -q "mutatePlan.*ApiRequest{iPreferences=Preferences{\.\.}" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses Preferences{..} pattern match"
else
    echo "✗ src/PostgREST/Plan.hs not using Preferences{..} pattern - fix not applied"
    test_status=1
fi

# Check that direct field access (preferResolution, preferRepresentation, preferMissing) is used instead of dot notation
echo "Checking src/PostgREST/Plan.hs for direct field access without dot notation..."
if grep -q "preferences\.prefer" "src/PostgREST/Plan.hs"; then
    echo "✗ src/PostgREST/Plan.hs still uses dot notation (preferences.field) - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/Plan.hs does not use dot notation"
fi

# Verify preferResolution is used directly
if grep -q "preferResolution" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses direct field access (preferResolution)"
else
    echo "✗ src/PostgREST/Plan.hs missing direct field access - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
