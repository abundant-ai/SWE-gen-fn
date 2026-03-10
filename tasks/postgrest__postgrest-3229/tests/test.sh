#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that postgrest.cabal has been updated to use hasql-pool >= 1.0.1 (not 0.10)
echo "Checking that postgrest.cabal uses hasql-pool >= 1.0.1 (not 0.10)..."
if grep -q "hasql-pool.*>= 1.0.1" "postgrest.cabal"; then
    echo "✓ postgrest.cabal uses hasql-pool >= 1.0.1"
elif grep -q "hasql-pool.*>= 0.10" "postgrest.cabal"; then
    echo "✗ postgrest.cabal still uses hasql-pool >= 0.10 - fix not applied"
    test_status=1
else
    echo "✗ postgrest.cabal has unexpected hasql-pool version"
    test_status=1
fi

# Check that hasql-notifications version is updated to >= 0.2.1.1 (not 0.2.1.0)
echo "Checking that postgrest.cabal uses hasql-notifications >= 0.2.1.1 (not 0.2.1.0)..."
if grep -q "hasql-notifications.*>= 0.2.1.1" "postgrest.cabal"; then
    echo "✓ postgrest.cabal uses hasql-notifications >= 0.2.1.1"
elif grep -q "hasql-notifications.*>= 0.2.1.0" "postgrest.cabal"; then
    echo "✗ postgrest.cabal still uses hasql-notifications >= 0.2.1.0 - fix not applied"
    test_status=1
else
    echo "✗ postgrest.cabal has unexpected hasql-notifications version"
    test_status=1
fi

# Check that cabal.project.freeze has the updated index-state
echo "Checking that cabal.project.freeze has updated index-state..."
if grep -q "index-state: hackage.haskell.org 2024-04-15T20:28:44Z" "cabal.project.freeze"; then
    echo "✓ cabal.project.freeze has updated index-state (2024-04-15)"
elif grep -q "index-state: hackage.haskell.org 2024-03-13T22:43:26Z" "cabal.project.freeze"; then
    echo "✗ cabal.project.freeze still has old index-state (2024-03-13) - fix not applied"
    test_status=1
else
    echo "✗ cabal.project.freeze has unexpected index-state"
    test_status=1
fi

# Check that CHANGELOG.md includes the pool logging entry
echo "Checking that CHANGELOG.md includes pool logging entry..."
if grep -q "#3214, Log connection pool events on log-level=info" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes pool logging entry"
else
    echo "✗ CHANGELOG.md missing pool logging entry - fix not applied"
    test_status=1
fi

# Check that nix overlays have been updated for hasql-pool 1.0.1
echo "Checking that nix/overlays/haskell-packages.nix references hasql-pool 1.0.1..."
if grep -q 'ver = "1.0.1"' "nix/overlays/haskell-packages.nix" && grep -q 'pkg = "hasql-pool"' "nix/overlays/haskell-packages.nix"; then
    echo "✓ nix/overlays/haskell-packages.nix references hasql-pool 1.0.1"
elif grep -q 'hasql-pool = lib.dontCheck prev.hasql-pool_0_10' "nix/overlays/haskell-packages.nix"; then
    echo "✗ nix/overlays/haskell-packages.nix still uses hasql-pool_0_10 - fix not applied"
    test_status=1
else
    echo "✗ nix/overlays/haskell-packages.nix has unexpected hasql-pool configuration"
    test_status=1
fi

# Check that src/PostgREST/AppState.hs imports Hasql.Pool.Config
echo "Checking that src/PostgREST/AppState.hs imports Hasql.Pool.Config..."
if grep -q "import qualified Hasql.Pool.Config" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs imports Hasql.Pool.Config"
else
    echo "✗ src/PostgREST/AppState.hs missing Hasql.Pool.Config import - fix not applied"
    test_status=1
fi

# Check that initPool function uses new hasql-pool 1.0.1 API (SQL.settings)
echo "Checking that initPool function uses new hasql-pool API..."
if grep -q "SQL.acquire \$ SQL.settings" "src/PostgREST/AppState.hs"; then
    echo "✓ initPool uses new hasql-pool API (SQL.settings)"
elif grep -A 5 "^initPool ::" "src/PostgREST/AppState.hs" | grep -q "SQL.acquire$"; then
    echo "✗ initPool still uses old hasql-pool API - fix not applied"
    test_status=1
else
    echo "✗ initPool has unexpected API usage"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs has HasqlPoolObs data constructor
echo "Checking that src/PostgREST/Observation.hs has HasqlPoolObs..."
if grep -q "HasqlPoolObs SQL.Observation" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has HasqlPoolObs"
else
    echo "✗ src/PostgREST/Observation.hs missing HasqlPoolObs - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Logger.hs has pool observation logging
echo "Checking that src/PostgREST/Logger.hs logs pool observations..."
if grep -q "HasqlPoolObs" "src/PostgREST/Logger.hs"; then
    echo "✓ src/PostgREST/Logger.hs logs pool observations"
else
    echo "✗ src/PostgREST/Logger.hs missing pool observation logging - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
