#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/fixtures"
cp "/tests/io/fixtures/fixtures.yaml" "test/io/fixtures/fixtures.yaml"

test_status=0

echo "Verifying fix for JWT role claim key string slicing (PR #4603)..."
echo ""
echo "NOTE: This PR adds string slicing operator for jwt-role-claim-key"
echo "BASE (buggy) does not support slicing syntax like [1:] or [:-7]"
echo "HEAD (fixed) supports Python-like slice syntax [a:b], [a:], [:b], [:]"
echo ""

# Check that JSPath.hs includes JSPSlice data constructor
echo "Checking src/PostgREST/Config/JSPath.hs includes JSPSlice data constructor..."
if grep -q "JSPSlice (Maybe Int) (Maybe Int)" "src/PostgREST/Config/JSPath.hs"; then
    echo "✓ JSPath.hs defines JSPSlice data constructor"
else
    echo "✗ JSPath.hs does not define JSPSlice - fix not applied"
    test_status=1
fi

# Check that dumpJSPath handles JSPSlice
echo "Checking dumpJSPath handles JSPSlice..."
if grep -q 'dumpJSPath (JSPSlice' "src/PostgREST/Config/JSPath.hs"; then
    echo "✓ dumpJSPath handles JSPSlice"
else
    echo "✗ dumpJSPath does not handle JSPSlice - fix not applied"
    test_status=1
fi

# Check that walkJSPath handles slicing on JSON.String
echo "Checking walkJSPath supports string slicing..."
if grep -q 'walkJSPath (Just (JSON.String str)) (JSPSlice start end:rest)' "src/PostgREST/Config/JSPath.hs"; then
    echo "✓ walkJSPath handles string slicing"
else
    echo "✗ walkJSPath does not handle string slicing - fix not applied"
    test_status=1
fi

# Check that slicing implementation normalizes indices (handles negative indices)
echo "Checking slicing implementation handles negative indices..."
if grep -A 5 'JSPSlice start end:rest' "src/PostgREST/Config/JSPath.hs" | grep -q "norm"; then
    echo "✓ Slicing implementation normalizes negative indices"
else
    echo "✗ Slicing implementation does not handle negative indices - fix not applied"
    test_status=1
fi

# Check that pJSPSlice parser exists
echo "Checking pJSPSlice parser exists..."
if grep -q "pJSPSlice :: P.Parser JSPathExp" "src/PostgREST/Config/JSPath.hs"; then
    echo "✓ pJSPSlice parser exists"
else
    echo "✗ pJSPSlice parser does not exist - fix not applied"
    test_status=1
fi

# Check that pJSPathExp includes pJSPSlice
echo "Checking pJSPathExp includes pJSPSlice..."
if grep "pJSPathExp = " "src/PostgREST/Config/JSPath.hs" | grep -q "pJSPSlice"; then
    echo "✓ pJSPathExp includes pJSPSlice parser"
else
    echo "✗ pJSPathExp does not include pJSPSlice - fix not applied"
    test_status=1
fi

# Check that filter no longer has P.eof (since filter can now be followed by slice)
echo "Checking pJSPFilter allows subsequent expressions..."
if grep -A 3 'pJSPFilter :: P.Parser JSPathExp' "src/PostgREST/Config/JSPath.hs" | grep "P.eof" | grep -v "this should be the last"; then
    echo "✗ pJSPFilter still has P.eof restriction - fix not applied"
    test_status=1
else
    echo "✓ pJSPFilter allows subsequent expressions (slice can follow filter)"
fi

# Check that walkJSPath filter still supports rest (for chaining with slice)
echo "Checking walkJSPath filter supports chaining with other expressions..."
if grep 'JSPFilter jspFilter:rest' "src/PostgREST/Config/JSPath.hs" | grep -q "walkJSPath"; then
    echo "✓ Filter walkJSPath supports chaining (rest parameter)"
else
    echo "✗ Filter walkJSPath does not support chaining - fix not applied"
    test_status=1
fi

# Check documentation includes slice operator
echo "Checking docs/references/auth.rst documents slice operator..."
if grep -q "slice operator" "docs/references/auth.rst"; then
    echo "✓ Documentation includes slice operator"
else
    echo "✗ Documentation does not include slice operator - fix not applied"
    test_status=1
fi

# Check documentation has examples of slice syntax
echo "Checking documentation has slice syntax examples..."
if grep -q '\[1:\]' "docs/references/auth.rst" || grep -q '\[a:b\]' "docs/references/auth.rst"; then
    echo "✓ Documentation has slice syntax examples"
else
    echo "✗ Documentation missing slice syntax examples - fix not applied"
    test_status=1
fi

# Check test fixtures include slice test cases
echo "Checking test/io/fixtures/fixtures.yaml includes slice test cases..."
if grep -q '\[7:\]' "test/io/fixtures/fixtures.yaml"; then
    echo "✓ Test fixtures include [7:] slice test"
else
    echo "✗ Test fixtures missing [7:] slice test - fix not applied"
    test_status=1
fi

if grep -q '\[:-7\]' "test/io/fixtures/fixtures.yaml"; then
    echo "✓ Test fixtures include [:-7] slice test"
else
    echo "✗ Test fixtures missing [:-7] slice test - fix not applied"
    test_status=1
fi

if grep -q '\[7:-7\]' "test/io/fixtures/fixtures.yaml"; then
    echo "✓ Test fixtures include [7:-7] slice test"
else
    echo "✗ Test fixtures missing [7:-7] slice test - fix not applied"
    test_status=1
fi

if grep -q '\[:\]' "test/io/fixtures/fixtures.yaml"; then
    echo "✓ Test fixtures include [:] slice test"
else
    echo "✗ Test fixtures missing [:] slice test - fix not applied"
    test_status=1
fi

# Check for filter+slice combination test
echo "Checking test fixtures include filter+slice combination..."
if grep -q '\[?(@ \*== "_test_")\]\[7:\]' "test/io/fixtures/fixtures.yaml"; then
    echo "✓ Test fixtures include filter+slice combination"
else
    echo "✗ Test fixtures missing filter+slice combination test - fix not applied"
    test_status=1
fi

# Check CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the slicing fix..."
if grep -q "#4599" "CHANGELOG.md" && grep -q "slicing" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the string slicing fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - string slicing support applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
