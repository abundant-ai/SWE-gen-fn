#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

test_status=0

echo "Verifying fix for resource cleanup refactor (PR #2403)..."
echo ""
echo "NOTE: This PR refactors resource cleanup to use bracket pattern"
echo "BASE (buggy) has typo 'plattforms', missing destroy export, and incorrect cleanup"
echo "HEAD (fixed) corrects typo, adds destroy function with bracket, and fixes test syntax"
echo ""

# Check App.hs - HEAD should have correct spelling "platforms"
echo "Checking src/PostgREST/App.hs has correct spelling 'platforms'..."
if grep -q 'panic "Cannot run with unix socket on non-unix platforms."' "src/PostgREST/App.hs"; then
    echo "✓ App.hs has correct spelling 'platforms'"
else
    echo "✗ App.hs does not have correct spelling - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should export destroy function
echo "Checking src/PostgREST/AppState.hs exports destroy function..."
if grep -q ", destroy" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs exports destroy function"
else
    echo "✗ AppState.hs does not export destroy - fix not applied"
    test_status=1
fi

# Check that destroy function is defined
if grep -q "destroy :: AppState -> IO ()" "src/PostgREST/AppState.hs" && grep -q "destroy = releasePool" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs defines destroy function"
else
    echo "✗ AppState.hs does not define destroy function - fix not applied"
    test_status=1
fi

# Check CLI.hs - HEAD should use bracket pattern
echo "Checking src/PostgREST/CLI.hs uses bracket for resource cleanup..."
if grep -q "bracket" "src/PostgREST/CLI.hs" && grep -q "AppState.destroy" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs uses bracket with AppState.destroy"
else
    echo "✗ CLI.hs does not use bracket pattern - fix not applied"
    test_status=1
fi

# Check that releasePool is NOT called in dumpSchema (should be handled by bracket)
if grep -q "AppState.releasePool appState" "src/PostgREST/CLI.hs"; then
    echo "✗ CLI.hs incorrectly calls releasePool in dumpSchema - fix not applied"
    test_status=1
else
    echo "✓ CLI.hs does not call releasePool (handled by bracket)"
fi

# Check Unix.hs - HEAD should have simple interrupt handler
echo "Checking src/PostgREST/Unix.hs has correct interrupt handler..."
if grep -q "let interrupt = throwTo (AppState.getMainThreadId appState) UserInterrupt" "src/PostgREST/Unix.hs"; then
    echo "✓ Unix.hs has simple interrupt handler (no explicit releasePool)"
else
    echo "✗ Unix.hs does not have correct interrupt handler - fix not applied"
    test_status=1
fi

# Check test/spec/Main.hs - HEAD should have correct syntax
echo "Checking test/spec/Main.hs has correct syntax..."
if grep -q "either (panic . show) id" "test/spec/Main.hs"; then
    echo "✓ Main.hs has correct syntax 'panic . show'"
else
    echo "✗ Main.hs does not have correct syntax - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - resource cleanup refactor applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
