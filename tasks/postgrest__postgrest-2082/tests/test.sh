#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/EmbedDisambiguationSpec.hs" "test/Feature/EmbedDisambiguationSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"

test_status=0

echo "Verifying fix for improved relationship error messages (PR #2082)..."
echo ""
echo "This PR improves error messages when relationships cannot be found between entities."
echo "The bug was less helpful error messages - the fix adds schema information and better hints."
echo ""

# The test expects the source code to have the IMPROVED error messages (after fix is applied)
# The HEAD test files expect the improved error messages
# They should match when fix.patch is applied

echo "Checking Error.hs has the fix applied..."
if [ -f "src/PostgREST/Error.hs" ]; then
    echo "✓ src/PostgREST/Error.hs exists"

    # After fix: should have 3 parameters (Text Text Text)
    if grep -q "| NoRelBetween Text Text Text" "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs has NoRelBetween with schema parameter (fix applied)"
    else
        echo "✗ Error.hs missing improved NoRelBetween signature (fix not applied)"
        test_status=1
    fi

    # After fix: should have the detailed hint
    if grep -q "Verify that.*exist in the schema.*and that there is a foreign key relationship" "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs has improved hint mentioning table verification (fix applied)"
    else
        echo "✗ Error.hs missing improved hint text (fix not applied)"
        test_status=1
    fi

    # Check for the detailed error message pattern
    if grep -q "Could not find a relationship between.*in the schema cache" "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs has schema cache mention in error message"
    else
        echo "✗ Error.hs missing schema cache mention"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Error.hs not found"
    test_status=1
fi

echo ""
echo "Checking DbRequestBuilder.hs passes schema parameter..."
if [ -f "src/PostgREST/Request/DbRequestBuilder.hs" ]; then
    echo "✓ src/PostgREST/Request/DbRequestBuilder.hs exists"

    # After fix: should pass schema parameter
    if grep -q "Left \$ NoRelBetween origin target schema" "src/PostgREST/Request/DbRequestBuilder.hs"; then
        echo "✓ DbRequestBuilder.hs passes schema to NoRelBetween (fix applied)"
    else
        echo "✗ DbRequestBuilder.hs not passing schema parameter (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Request/DbRequestBuilder.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files have improved error expectations..."
if [ -f "test/Feature/EmbedDisambiguationSpec.hs" ]; then
    echo "✓ test/Feature/EmbedDisambiguationSpec.hs exists (HEAD version)"

    # The HEAD version should have the improved error messages in test expectations
    if grep -q "Verify that.*exist in the schema.*and that there is a foreign key relationship" "test/Feature/EmbedDisambiguationSpec.hs"; then
        echo "✓ EmbedDisambiguationSpec.hs expects improved hints (matches fixed code)"
    else
        echo "✗ EmbedDisambiguationSpec.hs missing improved error expectations"
        test_status=1
    fi
else
    echo "✗ test/Feature/EmbedDisambiguationSpec.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/Feature/QuerySpec.hs" ]; then
    echo "✓ test/Feature/QuerySpec.hs exists (HEAD version)"

    # The HEAD version should have the improved error messages in test expectations
    if grep -q "Verify that.*exist in the schema.*and that there is a foreign key relationship" "test/Feature/QuerySpec.hs"; then
        echo "✓ QuerySpec.hs expects improved hints (matches fixed code)"
    else
        echo "✗ QuerySpec.hs missing improved error expectations"
        test_status=1
    fi
else
    echo "✗ test/Feature/QuerySpec.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
