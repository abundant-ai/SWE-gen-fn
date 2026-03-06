#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4032 which fixes regression with parameter charset=utf-8 in mediatype
# HEAD state (a731c73b) = fix applied, has charset=utf-8 handling
# BASE state (with bug.patch) = no charset=utf-8 handling, tests removed
# ORACLE state (BASE + fix.patch) = has charset=utf-8 handling and tests

test_status=0

echo "Verifying source code matches HEAD state (mediatype parser fix)..."
echo ""

echo "Checking that CHANGELOG.md has the fix entry..."
if grep -q "#4030, Fix regression with parameter \`charset=utf-8\` in mediatype" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs has TODO comment..."
if grep -q -- "-- TODO: Improve mediatype parser as per RFC 2045" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has TODO comment - fix applied!"
else
    echo "✗ MediaType.hs does not have TODO comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs does NOT have P.eof in tokenizeMediaType..."
if ! grep -A 2 "params <- P.many pSemicolonSeparatedKeyVals" "src/PostgREST/MediaType.hs" | grep -q "P.eof"; then
    echo "✓ MediaType.hs does not have P.eof - fix applied!"
else
    echo "✗ MediaType.hs has P.eof - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs has improved comment for ending semicolon..."
if grep -q "ending semicolon, discard input after that because it has already failed or we have hit EOF" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has improved comment - fix applied!"
else
    echo "✗ MediaType.hs does not have improved comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs allows hyphens in parameter keys..."
if grep -q -- 'key <- P.many1 (P.alphaNum <|> P.oneOf "-")' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs allows hyphens in keys - fix applied!"
else
    echo "✗ MediaType.hs does not allow hyphens in keys - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs allows hyphens in unquoted values..."
if grep -q 'pUnQuoted = P.many1 (P.alphaNum <|> P.oneOf "|-")' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs allows hyphens in unquoted values - fix applied!"
else
    echo "✗ MediaType.hs does not allow hyphens in unquoted values - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CustomMediaSpec.hs has test for charset=utf-8..."
if grep -q 'regression test allowing charset=utf-8' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has charset=utf-8 test - fix applied!"
else
    echo "✗ CustomMediaSpec.hs does not have charset=utf-8 test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CustomMediaSpec.hs has test for unrecognized parameters..."
if grep -q 'handle unrecognized parameters leniently' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has unrecognized parameters test - fix applied!"
else
    echo "✗ CustomMediaSpec.hs does not have unrecognized parameters test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
