#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4037 which fixes a regression with parameter charset=utf-8 in mediatype
# HEAD state (d4ec0e52) = fix applied, parser allows hyphens in parameter keys and values
# BASE state (with bug.patch) = parser restricted to alphanumeric keys and pipe-only values
# ORACLE state (BASE + fix.patch) = parser allows hyphens in parameter keys and values

test_status=0

echo "Verifying source code matches HEAD state (mediatype parser fix)..."
echo ""

echo "Checking that MediaType.hs has correct parser for parameter keys..."
if grep -q 'key <- P.many1 (P.alphaNum <|> P.oneOf "-")' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs allows hyphens in parameter keys - fix applied!"
else
    echo "✗ MediaType.hs does not allow hyphens in parameter keys - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs has correct parser for parameter values..."
if grep -q 'pUnQuoted = P.many1 (P.alphaNum <|> P.oneOf "|-")' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs allows hyphens in parameter values - fix applied!"
else
    echo "✗ MediaType.hs does not allow hyphens in parameter values - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs does NOT have strict P.eof..."
if grep -q "P.optional \$ P.try \$ P.spaces \*> P.char ';' -- ending semicolon, discard input after that because it has already failed or we have hit EOF" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has lenient ending semicolon handling - fix applied!"
else
    echo "✗ MediaType.hs does not have lenient ending semicolon handling - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs does NOT have P.eof after params..."
if ! grep -A 1 "params <- P.many pSemicolonSeparatedKeyVals" "src/PostgREST/MediaType.hs" | grep -q "P.eof"; then
    echo "✓ MediaType.hs does not have strict P.eof - fix applied!"
else
    echo "✗ MediaType.hs has strict P.eof - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that MediaType.hs has TODO comment..."
if grep -q "TODO: Improve mediatype parser as per RFC 2045" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has TODO comment - fix applied!"
else
    echo "✗ MediaType.hs does not have TODO comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md has the fix entry..."
if grep -q "#4030, Fix regression with parameter \`charset=utf-8\` in mediatype" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CustomMediaSpec.hs has regression tests..."
if grep -q "regression test allowing charset=utf-8" "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec has regression test for charset=utf-8 - fix applied!"
else
    echo "✗ CustomMediaSpec does not have regression test for charset=utf-8 - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CustomMediaSpec.hs has unrecognized parameters test..."
if grep -q "handle unrecognized parameters leniently" "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec has unrecognized parameters test - fix applied!"
else
    echo "✗ CustomMediaSpec does not have unrecognized parameters test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
