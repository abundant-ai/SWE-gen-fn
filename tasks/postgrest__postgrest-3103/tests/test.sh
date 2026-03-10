#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3089, The any media type handler now sets \`Content-Type: application/octet-stream\` by default instead of \`Content-Type: application/json\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that Plan.hs imports ResolvedHandler
echo "Checking that Plan.hs imports ResolvedHandler..."
if grep -q "ResolvedHandler," "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs imports ResolvedHandler"
else
    echo "✗ Plan.hs missing ResolvedHandler import - fix not applied"
    test_status=1
fi

# Check that negotiateContent function signature uses ResolvedHandler
echo "Checking that negotiateContent uses ResolvedHandler in signature..."
if grep -q "Either ApiRequestError ResolvedHandler" "src/PostgREST/Plan.hs"; then
    echo "✓ negotiateContent signature uses ResolvedHandler"
else
    echo "✗ negotiateContent signature incorrect - fix not applied"
    test_status=1
fi

# Check that Plan.hs does NOT have defaultMTAnyToMTJSON function (removed in fix)
echo "Checking that Plan.hs does NOT have defaultMTAnyToMTJSON..."
if ! grep -q "defaultMTAnyToMTJSON" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs does not have defaultMTAnyToMTJSON (correctly removed)"
else
    echo "✗ Plan.hs still has defaultMTAnyToMTJSON - fix not applied"
    test_status=1
fi

# Check that negotiateContent does NOT use defaultMTAnyToMTJSON in the case statement
echo "Checking that negotiateContent does NOT call defaultMTAnyToMTJSON..."
if ! grep -q "defaultMTAnyToMTJSON \$ case" "src/PostgREST/Plan.hs"; then
    echo "✓ negotiateContent does not call defaultMTAnyToMTJSON"
else
    echo "✗ negotiateContent still calls defaultMTAnyToMTJSON - fix not applied"
    test_status=1
fi

# Check that Plan.hs case statement starts with "case (act, firstAcceptedPick) of" (not wrapped)
echo "Checking that case statement is unwrapped..."
if grep -q "^  case (act, firstAcceptedPick) of$" "src/PostgREST/Plan.hs"; then
    echo "✓ case statement is correctly unwrapped"
else
    echo "✗ case statement formatting incorrect - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
