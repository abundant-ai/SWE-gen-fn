#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"

test_status=0

echo "Verifying fix for case-insensitive 'is' filter operator (PR #2081)..."
echo ""
echo "This PR makes the 'is' filter operator accept NULL and trilean values case-insensitively."
echo "The bug was that only lowercase values (is.null, is.true, etc.) worked."
echo "The fix adds case-insensitive parsing so is.NULL, is.TRUE, is.FaLsE, etc. all work."
echo ""

echo "Checking Parsers.hs has the fix applied..."
if [ -f "src/PostgREST/Request/Parsers.hs" ]; then
    echo "✓ src/PostgREST/Request/Parsers.hs exists"

    # After fix: should use ciString instead of string for parsing trilean values
    if grep -q "ciString \"null\"" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs uses ciString for 'null' parsing (fix applied)"
    else
        echo "✗ Parsers.hs not using ciString for 'null' (fix not applied)"
        test_status=1
    fi

    if grep -q "ciString \"true\"" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs uses ciString for 'true' parsing (fix applied)"
    else
        echo "✗ Parsers.hs not using ciString for 'true' (fix not applied)"
        test_status=1
    fi

    if grep -q "ciString \"false\"" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs uses ciString for 'false' parsing (fix applied)"
    else
        echo "✗ Parsers.hs not using ciString for 'false' (fix not applied)"
        test_status=1
    fi

    if grep -q "ciString \"unknown\"" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs uses ciString for 'unknown' parsing (fix applied)"
    else
        echo "✗ Parsers.hs not using ciString for 'unknown' (fix not applied)"
        test_status=1
    fi

    # Check that ciChar and ciString helper functions are defined
    if grep -q "ciChar :: Char -> GenParser Char state Char" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs has ciChar helper function defined"
    else
        echo "✗ Parsers.hs missing ciChar helper function"
        test_status=1
    fi

    if grep -q "ciString :: \[Char\] -> GenParser Char state \[Char\]" "src/PostgREST/Request/Parsers.hs"; then
        echo "✓ Parsers.hs has ciString helper function defined"
    else
        echo "✗ Parsers.hs missing ciString helper function"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Request/Parsers.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test file has case-insensitive test cases..."
if [ -f "test/Feature/QuerySpec.hs" ]; then
    echo "✓ test/Feature/QuerySpec.hs exists (HEAD version)"

    # The HEAD version should have tests for uppercase/mixed case values
    if grep -q "done=is.NULL" "test/Feature/QuerySpec.hs"; then
        echo "✓ QuerySpec.hs tests uppercase NULL (matches fixed code)"
    else
        echo "✗ QuerySpec.hs missing uppercase NULL test"
        test_status=1
    fi

    if grep -q "done=is.TRUE" "test/Feature/QuerySpec.hs"; then
        echo "✓ QuerySpec.hs tests uppercase TRUE (matches fixed code)"
    else
        echo "✗ QuerySpec.hs missing uppercase TRUE test"
        test_status=1
    fi

    if grep -q "done=is.FAlSe" "test/Feature/QuerySpec.hs"; then
        echo "✓ QuerySpec.hs tests mixed case FALSE (matches fixed code)"
    else
        echo "✗ QuerySpec.hs missing mixed case FALSE test"
        test_status=1
    fi

    if grep -q "done=is.UnKnOwN" "test/Feature/QuerySpec.hs"; then
        echo "✓ QuerySpec.hs tests mixed case UNKNOWN (matches fixed code)"
    else
        echo "✗ QuerySpec.hs missing mixed case UNKNOWN test"
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
