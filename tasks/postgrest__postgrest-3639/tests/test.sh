#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entry for PR #3093
echo "Checking that CHANGELOG.md has the fix entry for PR #3093..."
if grep -q "#3093, Nested empty embeds no longer show empty values and are correctly omitted" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #3093 fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md missing PR #3093 fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has the hasOnlyNullEmbed implementation..."
if grep -q "hasOnlyNullEmbed" "src/PostgREST/Plan.hs" && \
   grep -q "checkIfNullEmbed" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has hasOnlyNullEmbed and checkIfNullEmbed - fix applied!"
else
    echo "✗ Plan.hs missing hasOnlyNullEmbed or checkIfNullEmbed - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
