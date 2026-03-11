#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for pool interaction refactoring (PR #2398)..."
echo ""
echo "NOTE: This PR unifies pool interaction behind usePool/releasePool helpers"
echo "BASE (buggy) uses inconsistent pool access patterns"
echo "HEAD (fixed) uses usePool and releasePool consistently"
echo ""

# Check AppState.hs - HEAD should export usePool and no longer export getPool
echo "Checking src/PostgREST/AppState.hs exports usePool..."
if grep -q "usePool" "src/PostgREST/AppState.hs" && grep -q "^  , usePool$" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs exports usePool"
else
    echo "✗ AppState.hs does not export usePool - fix not applied"
    test_status=1
fi

# Check that getPool is removed from exports
if ! grep -q "^  , getPool$" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs no longer exports getPool"
else
    echo "✗ AppState.hs still exports getPool - fix not applied"
    test_status=1
fi

# Check usePool function definition
echo "Checking AppState.hs defines usePool function..."
if grep -q "usePool :: AppState -> SQL.Session a -> IO (Either SQL.UsageError a)" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs defines usePool with correct signature"
else
    echo "✗ AppState.hs does not define usePool correctly - fix not applied"
    test_status=1
fi

if grep -q "usePool AppState{..} = SQL.use statePool" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs implements usePool correctly"
else
    echo "✗ AppState.hs usePool implementation incorrect - fix not applied"
    test_status=1
fi

# Check releasePool no longer calls throwTo
echo "Checking AppState.hs releasePool implementation..."
if grep -q "releasePool AppState{..} = SQL.release statePool$" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs releasePool simplified (no throwTo)"
else
    echo "✗ AppState.hs releasePool not simplified - fix not applied"
    test_status=1
fi

# Check App.hs uses usePool instead of getPool
echo "Checking src/PostgREST/App.hs uses usePool..."
if grep -q "AppState.usePool appState" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses AppState.usePool"
else
    echo "✗ App.hs does not use AppState.usePool - fix not applied"
    test_status=1
fi

# Check that App.hs no longer imports Hasql.Pool
if ! grep -q "^import qualified Hasql.Pool" "src/PostgREST/App.hs"; then
    echo "✓ App.hs no longer imports Hasql.Pool"
else
    echo "✗ App.hs still imports Hasql.Pool - fix not applied"
    test_status=1
fi

# Check Admin.hs uses usePool
echo "Checking src/PostgREST/Admin.hs uses usePool..."
if grep -q "AppState.usePool appState" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs uses AppState.usePool"
else
    echo "✗ Admin.hs does not use AppState.usePool - fix not applied"
    test_status=1
fi

# Check that Admin.hs no longer imports Hasql.Pool
if ! grep -q "^import qualified Hasql.Pool" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs no longer imports Hasql.Pool"
else
    echo "✗ Admin.hs still imports Hasql.Pool - fix not applied"
    test_status=1
fi

# Check CLI.hs no longer imports Hasql.Pool
echo "Checking src/PostgREST/CLI.hs refactoring..."
if ! grep -q "^import qualified Hasql.Pool" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs no longer imports Hasql.Pool"
else
    echo "✗ CLI.hs still imports Hasql.Pool - fix not applied"
    test_status=1
fi

# Check style.nix includes .py files
echo "Checking nix/tools/style.nix includes Python files..."
if grep -q "'\*.py'" "nix/tools/style.nix"; then
    echo "✓ style.nix includes .py files in diff check"
else
    echo "✗ style.nix does not include .py files - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - pool refactoring applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
