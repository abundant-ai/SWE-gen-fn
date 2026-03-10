#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for avoiding empty transactions on invalid embedding (PR #2502)..."
echo ""
echo "NOTE: This PR fixes the issue where invalid resource embedding still opens a DB transaction."
echo "HEAD (fixed) avoids acquiring DB connections for planning errors by refactoring logic"
echo "BASE (buggy) has Middleware.hs that opens transactions even when planning fails"
echo ""

# Check postgrest.cabal - HEAD should NOT have PostgREST.Middleware module
echo "Checking postgrest.cabal does NOT include PostgREST.Middleware..."
if ! grep -q "PostgREST.Middleware" "postgrest.cabal"; then
    echo "✓ postgrest.cabal does not include PostgREST.Middleware (removed)"
else
    echo "✗ postgrest.cabal still has PostgREST.Middleware - fix not applied"
    test_status=1
fi

# Check Middleware.hs does NOT exist in HEAD
echo "Checking src/PostgREST/Middleware.hs does NOT exist..."
if [ ! -f "src/PostgREST/Middleware.hs" ]; then
    echo "✓ Middleware.hs deleted (as expected)"
else
    echo "✗ Middleware.hs still exists - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should NOT import Middleware
echo "Checking src/PostgREST/App.hs does NOT import Middleware..."
if ! grep -q "import.*PostgREST.Middleware" "src/PostgREST/App.hs"; then
    echo "✓ App.hs does not import Middleware (removed)"
else
    echo "✗ App.hs still imports Middleware - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/App.hs does NOT use runAppInDb..."
if ! grep -q "runAppInDb" "src/PostgREST/App.hs"; then
    echo "✓ App.hs does not use runAppInDb (removed)"
else
    echo "✗ App.hs still uses runAppInDb - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should have refactored handleRequest signature
echo "Checking src/PostgREST/App.hs has refactored handleRequest..."
if grep -q "handleRequest :: AuthResult -> AppConfig -> AppState.AppState" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has refactored handleRequest signature"
else
    echo "✗ App.hs missing refactored handleRequest - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should return Either for error handling
echo "Checking src/PostgREST/Plan.hs returns Either Error..."
if grep -q "Either Error" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs returns Either for error handling"
else
    echo "✗ Plan.hs doesn't return Either - fix not applied"
    test_status=1
fi

# Check Query.hs - HEAD should have optionalRollback
echo "Checking src/PostgREST/Query.hs has optionalRollback..."
if grep -q "optionalRollback" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has optionalRollback"
else
    echo "✗ Query.hs missing optionalRollback - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should have optionalRollback
echo "Checking src/PostgREST/Response.hs has optionalRollback..."
if grep -q "optionalRollback" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has optionalRollback"
else
    echo "✗ Response.hs missing optionalRollback - fix not applied"
    test_status=1
fi

# Check test_io.py - HEAD should have test for no pool connection on bad embedding
echo "Checking test/io/test_io.py has test_no_pool_connection_required_on_bad_embedding..."
if grep -q "test_no_pool_connection_required_on_bad_embedding" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_no_pool_connection_required_on_bad_embedding"
else
    echo "✗ test_io.py missing test_no_pool_connection_required_on_bad_embedding - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fix for avoiding empty transactions applied"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
