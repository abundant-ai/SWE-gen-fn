#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/coverage.overlay" "test/coverage.overlay"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for adding current user to request log (PR #2115)..."
echo ""
echo "This PR adds logging of the current user/role for each request."
echo "The bug was that request logs did not include the effective database role."
echo "The fix adds PostgREST.Logger module and integrates it with request handling."
echo ""

echo "Checking PostgREST.Logger module exists (fix applied)..."
if [ -f "src/PostgREST/Logger.hs" ]; then
    echo "✓ src/PostgREST/Logger.hs exists (fix applied)"

    # Check that the Logger module has middleware function
    if grep -q "middleware" "src/PostgREST/Logger.hs"; then
        echo "✓ Logger.hs contains middleware function"
    else
        echo "✗ Logger.hs does not contain middleware function"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Logger.hs not found (not fixed)"
    test_status=1
fi

echo ""
echo "Checking PostgREST.Cors module exists (fix applied)..."
if [ -f "src/PostgREST/Cors.hs" ]; then
    echo "✓ src/PostgREST/Cors.hs exists (fix applied)"
else
    echo "✗ src/PostgREST/Cors.hs not found (not fixed)"
    test_status=1
fi

echo ""
echo "Checking postgrest.cabal includes Logger module..."
if [ -f "postgrest.cabal" ]; then
    if grep -q "PostgREST.Logger" "postgrest.cabal"; then
        echo "✓ postgrest.cabal includes PostgREST.Logger module"
    else
        echo "✗ postgrest.cabal does not include PostgREST.Logger (not fixed)"
        test_status=1
    fi

    if grep -q "vault" "postgrest.cabal"; then
        echo "✓ postgrest.cabal includes vault dependency"
    else
        echo "✗ postgrest.cabal does not include vault dependency (not fixed)"
        test_status=1
    fi
else
    echo "✗ postgrest.cabal not found"
    test_status=1
fi

echo ""
echo "Checking App.hs imports Logger..."
if [ -f "src/PostgREST/App.hs" ]; then
    if grep -q "import qualified PostgREST.Logger" "src/PostgREST/App.hs"; then
        echo "✓ App.hs imports PostgREST.Logger"
    else
        echo "✗ App.hs does not import PostgREST.Logger (not fixed)"
        test_status=1
    fi

    # Check that Logger.middleware is used
    if grep -q "Logger.middleware" "src/PostgREST/App.hs"; then
        echo "✓ App.hs uses Logger.middleware"
    else
        echo "✗ App.hs does not use Logger.middleware (not fixed)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#1988.*current user.*request log" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions fix for PR #1988 (current user in request log)"
    else
        echo "✗ CHANGELOG.md does not mention fix (not documented)"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking Auth.hs has AuthResult type..."
if [ -f "src/PostgREST/Auth.hs" ]; then
    if grep -q "data AuthResult" "src/PostgREST/Auth.hs"; then
        echo "✓ Auth.hs contains AuthResult type definition"
    else
        echo "✗ Auth.hs does not contain AuthResult type (not fixed)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Auth.hs not found"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

test_file1="test/coverage.overlay"
if [ -f "$test_file1" ]; then
    echo "✓ $test_file1 exists (HEAD version)"
else
    echo "✗ $test_file1 not found - HEAD file not copied!"
    test_status=1
fi

test_file2="test/io/fixtures.sql"
if [ -f "$test_file2" ]; then
    echo "✓ $test_file2 exists (HEAD version)"
else
    echo "✗ $test_file2 not found - HEAD file not copied!"
    test_status=1
fi

test_file3="test/io/test_io.py"
if [ -f "$test_file3" ]; then
    echo "✓ $test_file3 exists (HEAD version)"
else
    echo "✗ $test_file3 not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
