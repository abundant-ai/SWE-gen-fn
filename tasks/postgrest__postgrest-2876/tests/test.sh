#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"

test_status=0

echo "Verifying fix for improved details field of the singular error response..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#1655, Improve `details` field of the singular error response' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check that the error message was updated in Error.hs (simple version)
echo "Checking src/PostgREST/Error.hs for improved (simplified) error message..."
if grep -q '"The result contains"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has simplified error message"
else
    echo "✗ Error.hs missing simplified error message - fix not applied"
    test_status=1
fi

# Check that the verbose error message format is NOT present
echo "Checking src/PostgREST/Error.hs does not contain verbose error message..."
if grep -q '"Results contain"' "src/PostgREST/Error.hs" && grep -q "requires 1 row" "src/PostgREST/Error.hs"; then
    echo "✗ Error.hs still contains verbose error message - fix not applied"
    test_status=1
else
    echo "✓ Error.hs does not contain verbose error message"
fi

# Check that the test expectations were updated in SingularSpec.hs (simple version)
echo "Checking test/spec/Feature/Query/SingularSpec.hs for updated test expectations..."
if grep -q '"details":"The result contains 4 rows"' "test/spec/Feature/Query/SingularSpec.hs"; then
    echo "✓ SingularSpec.hs has updated test expectations (4 rows)"
else
    echo "✗ SingularSpec.hs missing updated test expectations (4 rows) - fix not applied"
    test_status=1
fi

if grep -q '"details":"The result contains 0 rows"' "test/spec/Feature/Query/SingularSpec.hs"; then
    echo "✓ SingularSpec.hs has updated test expectations (0 rows)"
else
    echo "✗ SingularSpec.hs missing updated test expectations (0 rows) - fix not applied"
    test_status=1
fi

if grep -q '"details":"The result contains 2 rows"' "test/spec/Feature/Query/SingularSpec.hs"; then
    echo "✓ SingularSpec.hs has updated test expectations (2 rows)"
else
    echo "✗ SingularSpec.hs missing updated test expectations (2 rows) - fix not applied"
    test_status=1
fi

if grep -q '"details":"The result contains 5 rows"' "test/spec/Feature/Query/SingularSpec.hs"; then
    echo "✓ SingularSpec.hs has updated test expectations (5 rows)"
else
    echo "✗ SingularSpec.hs missing updated test expectations (5 rows) - fix not applied"
    test_status=1
fi

# Check that verbose test expectations are NOT present
echo "Checking test/spec/Feature/Query/SingularSpec.hs does not contain verbose test expectations..."
if grep -q '"details":"Results contain' "test/spec/Feature/Query/SingularSpec.hs" && grep -q "requires 1 row" "test/spec/Feature/Query/SingularSpec.hs"; then
    echo "✗ SingularSpec.hs still contains verbose test expectations - fix not applied"
    test_status=1
else
    echo "✓ SingularSpec.hs does not contain verbose test expectations"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
