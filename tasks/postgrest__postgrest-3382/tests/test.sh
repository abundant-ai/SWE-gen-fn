#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/NullsStripSpec.hs" "test/spec/Feature/Query/NullsStripSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md has the entry for #3373
echo "Checking that CHANGELOG.md has the entry for #3373..."
if grep -q "#3373, Remove rejected mediatype \`application/vnd.pgrst.object+json\` from response" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3373"
else
    echo "✗ CHANGELOG.md missing entry for #3373 - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs does NOT have the erroneous headers line for SingularityError
echo "Checking that src/PostgREST/Error.hs does NOT have the SingularityError headers line..."
if grep -q "headers SingularityError{}.*=.*\[MediaType.toContentType.*MTVndSingularJSON" "src/PostgREST/Error.hs"; then
    echo "✗ src/PostgREST/Error.hs still has the SingularityError headers line - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/Error.hs does not have the SingularityError headers line"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
