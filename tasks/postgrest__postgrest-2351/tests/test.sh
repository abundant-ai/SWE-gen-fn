#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"

test_status=0

echo "Verifying fix for Location header with Prefer: return=representation (PR #2351)..."
echo ""
echo "NOTE: This PR changes behavior so Location header is only returned with Prefer: return=headers-only"
echo "We verify that the source code has the fix and test files are updated."
echo ""

echo "Checking source code has FIXED condition (rep == HeadersOnly)..."
if [ -f "src/PostgREST/Query/Statements.hs" ] && grep -q "if isInsert && rep == HeadersOnly" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs has FIXED condition (rep == HeadersOnly)"
else
    echo "✗ Statements.hs missing FIXED condition - fix not applied!"
    test_status=1
fi

echo "Checking Preferences.hs has FIXED comment (no Location header mention for Full)..."
if [ -f "src/PostgREST/Request/Preferences.hs" ] && grep -q "Full.*-- \^ Return the body\.$" "src/PostgREST/Request/Preferences.hs"; then
    echo "✓ Preferences.hs has FIXED comment for Full (no Location header)"
else
    echo "✗ Preferences.hs missing FIXED comment"
    test_status=1
fi

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ] && grep -q "#2312" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2312"
else
    echo "✗ CHANGELOG.md missing #2312 entry"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test file was copied correctly..."
echo ""

echo "Checking test/spec/Feature/Query/InsertSpec.hs expects NO Location header with return=representation..."
if [ -f "test/spec/Feature/Query/InsertSpec.hs" ] && [ -s "test/spec/Feature/Query/InsertSpec.hs" ]; then
    # In HEAD (with fix), return=representation should NOT have Location header
    # Should have matchHeaderAbsent hLocation
    absent_count=$(grep -c "matchHeaderAbsent hLocation" "test/spec/Feature/Query/InsertSpec.hs" || true)
    if [ "$absent_count" -gt 0 ]; then
        echo "✓ InsertSpec.hs expects NO Location header in $absent_count places (HEAD version)"
    else
        echo "✗ InsertSpec.hs doesn't use matchHeaderAbsent hLocation - HEAD file not copied!"
        test_status=1
    fi

    # Check specific test moved location (unicode test moved from one context to another)
    if grep -q 'context "with unicode values"' "test/spec/Feature/Query/InsertSpec.hs"; then
        echo "✓ InsertSpec.hs has unicode test context (HEAD version)"
    else
        echo "✗ InsertSpec.hs missing unicode test context"
        test_status=1
    fi
else
    echo "✗ InsertSpec.hs missing or empty"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix applied and HEAD test file copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
