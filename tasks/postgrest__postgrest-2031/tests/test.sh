#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/EmbedDisambiguationSpec.hs" "test/Feature/EmbedDisambiguationSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #2031 which improves error message for ambiguous embedding
# HEAD state (ac4d02f0f80229e6ed45c8bb98ed52a27f36e64e) = fix applied
# BASE state (with bug.patch) = old error format (generic hint, uses "embedding" field)
# ORACLE state (BASE + fix.patch) = new error format (specific hint with relHint function, uses "origin/target" fields)

test_status=0

echo "Verifying source code matches HEAD state (improved ambiguous embedding error message)..."
echo ""

echo "Checking that CHANGELOG mentions the improved error message..."
if grep -q "#2031, Improve error message for ambiguous embedding and add a relevant hint that includes unambiguous embedding suggestions" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions improved error message - fix applied!"
else
    echo "✗ CHANGELOG does not mention improved error message - fix not applied"
    test_status=1
fi

echo "Checking that Error.hs has the improved hint message..."
if grep -q "Try changing '" "src/PostgREST/Error.hs" && \
   grep -q "to one of the following:" "src/PostgREST/Error.hs" && \
   grep -q "relHint rels" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has improved hint with relHint function - fix applied!"
else
    echo "✗ Error.hs missing improved hint or relHint function - fix not applied"
    test_status=1
fi

echo "Checking that Error.hs has the improved error message..."
if grep -q "Could not embed because more than one relationship was found for" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has improved error message - fix applied!"
else
    echo "✗ Error.hs missing improved error message - fix not applied"
    test_status=1
fi

echo "Checking that Error.hs has the relHint function..."
if grep -q "relHint :: \[Relationship\] -> Text" "src/PostgREST/Error.hs" && \
   grep -q "relHint rels = T.intercalate" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has relHint function - fix applied!"
else
    echo "✗ Error.hs missing relHint function - fix not applied"
    test_status=1
fi

echo "Checking that compressedRel uses 'embedding' field..."
if grep -q '"embedding" .=' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs compressedRel uses 'embedding' field - fix applied!"
else
    echo "✗ Error.hs compressedRel not using 'embedding' field - fix not applied"
    test_status=1
fi

echo "Checking that compressedRel uses 'many-to-one', 'one-to-many', 'many-to-many' cardinality strings..."
if grep -q '"many-to-one"' "src/PostgREST/Error.hs" && \
   grep -q '"one-to-many"' "src/PostgREST/Error.hs" && \
   grep -q '"many-to-many"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses full cardinality names - fix applied!"
else
    echo "✗ Error.hs not using full cardinality names - fix not applied"
    test_status=1
fi

echo "Checking that test file has updated error expectations..."
if grep -q '"hint": "Try changing' "test/Feature/EmbedDisambiguationSpec.hs" && \
   grep -q '"embedding": "message with person"' "test/Feature/EmbedDisambiguationSpec.hs" && \
   grep -q '"cardinality": "many-to-one"' "test/Feature/EmbedDisambiguationSpec.hs"; then
    echo "✓ EmbedDisambiguationSpec.hs has updated error format expectations - test from HEAD!"
else
    echo "✗ EmbedDisambiguationSpec.hs does not have updated expectations - test not from HEAD"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
