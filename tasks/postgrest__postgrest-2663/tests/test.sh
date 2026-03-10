#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-numeric.config" "test/io/configs/expected/boolean-numeric.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-string.config" "test/io/configs/expected/boolean-string.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/defaults.config" "test/io/configs/expected/defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for db-pool-max-lifetime feature..."
echo ""
echo "NOTE: This PR adds db-pool-max-lifetime configuration option"
echo "HEAD (fixed) should have db-pool-max-lifetime config and hasql-pool 0.9 dependency."
echo "BASE (buggy) lacks the db-pool-max-lifetime feature."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2663 entry
echo "Checking CHANGELOG.md has PR #2663 entry..."
if grep -q "#2663, Limit maximal postgresql connection lifetime" "CHANGELOG.md" && \
   grep -q "db-pool-max-lifetime" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2663 entry with db-pool-max-lifetime"
else
    echo "✗ CHANGELOG.md missing PR #2663 entry - fix not applied"
    test_status=1
fi

# Check postgrest.cabal - HEAD should have hasql-pool >= 0.9
echo "Checking postgrest.cabal has hasql-pool >= 0.9..."
if grep -q "hasql-pool.*>= 0.9" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has hasql-pool >= 0.9"
else
    echo "✗ postgrest.cabal missing hasql-pool >= 0.9 - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should have configDbPoolMaxLifetime parameter
echo "Checking src/PostgREST/AppState.hs uses configDbPoolMaxLifetime..."
if grep -q "configDbPoolMaxLifetime" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs uses configDbPoolMaxLifetime"
else
    echo "✗ AppState.hs missing configDbPoolMaxLifetime - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should have db-pool-max-lifetime config option
echo "Checking src/PostgREST/Config.hs has db-pool-max-lifetime..."
if grep -q "db-pool-max-lifetime" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has db-pool-max-lifetime config option"
else
    echo "✗ Config.hs missing db-pool-max-lifetime - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should have configDbPoolMaxLifetime field
echo "Checking src/PostgREST/Config.hs has configDbPoolMaxLifetime field..."
if grep -q "configDbPoolMaxLifetime" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configDbPoolMaxLifetime field"
else
    echo "✗ Config.hs missing configDbPoolMaxLifetime field - fix not applied"
    test_status=1
fi

# Check CLI.hs - HEAD should have db-pool-max-lifetime example
echo "Checking src/PostgREST/CLI.hs has db-pool-max-lifetime example..."
if grep -q "db-pool-max-lifetime" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has db-pool-max-lifetime example"
else
    echo "✗ CLI.hs missing db-pool-max-lifetime example - fix not applied"
    test_status=1
fi

# Check nix overlays - HEAD should have hasql-pool 0.9
echo "Checking nix/overlays/haskell-packages.nix has hasql-pool 0.9..."
if grep -q 'ver = "0.9"' "nix/overlays/haskell-packages.nix" && \
   grep -q "hasql-pool" "nix/overlays/haskell-packages.nix"; then
    echo "✓ haskell-packages.nix has hasql-pool 0.9"
else
    echo "✗ haskell-packages.nix missing hasql-pool 0.9 - fix not applied"
    test_status=1
fi

# Check test config files - HEAD should have db-pool-max-lifetime in expected configs
echo "Checking test config files have db-pool-max-lifetime..."
if grep -q "db-pool-max-lifetime" "test/io/configs/expected/defaults.config"; then
    echo "✓ Test config files have db-pool-max-lifetime"
else
    echo "✗ Test config files missing db-pool-max-lifetime - fix not applied"
    test_status=1
fi

# Check that db-pool-acquisition-timeout is no longer optional (has default)
echo "Checking db-pool-acquisition-timeout has default value..."
if grep -q "db-pool-acquisition-timeout.*10" "test/io/configs/expected/defaults.config"; then
    echo "✓ db-pool-acquisition-timeout has default value"
else
    echo "✗ db-pool-acquisition-timeout missing default - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - db-pool-max-lifetime feature properly implemented"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
