#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/QueryCost.hs" "test/spec/QueryCost.hs"

test_status=0

echo "Verifying fix for hasql-1.6 and hasql-pool-0.8 upgrade (PR #2454)..."
echo ""
echo "NOTE: This PR upgrades hasql and hasql-pool dependencies with breaking API changes"
echo "BASE (buggy) uses hasql < 1.6 (ServerError with 4 params) and hasql-pool < 0.8 (old API)"
echo "HEAD (fixed) uses hasql >= 1.6 (ServerError with 5 params) and hasql-pool >= 0.8 (new API)"
echo ""

# Check cabal file - HEAD should have hasql >= 1.6
echo "Checking postgrest.cabal has hasql >= 1.6..."
if grep -q "hasql.*>= 1.6" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has hasql >= 1.6"
else
    echo "✗ postgrest.cabal does not have hasql >= 1.6 - fix not applied"
    test_status=1
fi

# Check cabal file - HEAD should have hasql-pool >= 0.8
echo "Checking postgrest.cabal has hasql-pool >= 0.8..."
if grep -q "hasql-pool.*>= 0.8" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has hasql-pool >= 0.8"
else
    echo "✗ postgrest.cabal does not have hasql-pool >= 0.8 - fix not applied"
    test_status=1
fi

# Check Main.hs - HEAD should use P.acquire with 3 arguments (including Nothing for timeout)
echo "Checking test/spec/Main.hs uses P.acquire with timeout parameter..."
if grep -q "P.acquire 3 Nothing" "test/spec/Main.hs"; then
    echo "✓ Main.hs uses P.acquire with Nothing timeout parameter"
else
    echo "✗ Main.hs does not use P.acquire with timeout parameter - fix not applied"
    test_status=1
fi

# Check QueryCost.hs - HEAD should use P.acquire with 3 arguments (including Nothing for timeout)
echo "Checking test/spec/QueryCost.hs uses P.acquire with timeout parameter..."
if grep -q 'P.acquire 3 Nothing "postgresql://"' "test/spec/QueryCost.hs"; then
    echo "✓ QueryCost.hs uses P.acquire with Nothing timeout parameter"
else
    echo "✗ QueryCost.hs does not use P.acquire with timeout parameter - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should use SQL.acquire with Nothing parameter
echo "Checking src/PostgREST/AppState.hs uses SQL.acquire with timeout..."
if grep -q "SQL.acquire configDbPoolSize Nothing" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses SQL.acquire with Nothing timeout"
else
    echo "✗ AppState.hs does not use SQL.acquire with timeout - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should use SQL.release instead of SQL.flush
echo "Checking src/PostgREST/AppState.hs uses SQL.release instead of SQL.flush..."
if grep -q "SQL.release statePool" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses SQL.release (new hasql-pool-0.8 API)"
else
    echo "✗ AppState.hs still uses SQL.flush - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should use ServerError with 5 parameters (includes _p for position)
echo "Checking src/PostgREST/Error.hs handles ServerError with position parameter..."
if grep -q "ServerError c m d h _p" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs handles ServerError with position parameter (_p)"
else
    echo "✗ Error.hs does not handle ServerError position parameter - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should use AcquisitionTimeoutUsageError instead of PoolIsReleasedUsageError
echo "Checking src/PostgREST/Error.hs uses AcquisitionTimeoutUsageError..."
if grep -q "AcquisitionTimeoutUsageError" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses AcquisitionTimeoutUsageError (new hasql-pool-0.8 error type)"
else
    echo "✗ Error.hs still uses old error type - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should NOT use PoolIsReleasedUsageError (removed in hasql-pool-0.8)
echo "Checking src/PostgREST/Error.hs does NOT use PoolIsReleasedUsageError..."
if ! grep -q "PoolIsReleasedUsageError" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs does not use PoolIsReleasedUsageError (removed)"
else
    echo "✗ Error.hs still uses PoolIsReleasedUsageError - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have correct HTTP status for AcquisitionTimeoutUsageError
echo "Checking src/PostgREST/Error.hs maps AcquisitionTimeoutUsageError to HTTP 504..."
if grep -q "AcquisitionTimeoutUsageError.*status504" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs maps AcquisitionTimeoutUsageError to HTTP 504"
else
    echo "✗ Error.hs does not map AcquisitionTimeoutUsageError correctly - fix not applied"
    test_status=1
fi

# Check nix overlays - HEAD should have hasql-1.6 and related packages
echo "Checking nix/overlays/haskell-packages.nix has hasql-1.6 setup..."
if grep -q "hasql_1_6" "nix/overlays/haskell-packages.nix"; then
    echo "✓ haskell-packages.nix references hasql_1_6"
else
    echo "✗ haskell-packages.nix does not reference hasql_1_6 - fix not applied"
    test_status=1
fi

# Check nix overlays - HEAD should have hasql-pool-0.8 setup
echo "Checking nix/overlays/haskell-packages.nix has hasql-pool-0.8 setup..."
if grep -q 'pkg = "hasql-pool"' "nix/overlays/haskell-packages.nix" && grep -q 'ver = "0.8' "nix/overlays/haskell-packages.nix"; then
    echo "✓ haskell-packages.nix has hasql-pool 0.8 setup"
else
    echo "✗ haskell-packages.nix does not have hasql-pool 0.8 - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - hasql-1.6 and hasql-pool-0.8 upgrade successful"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
