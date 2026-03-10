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
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying JWT caching feature implementation..."
echo ""

# Check that jwt-cache-max-lifetime config option is present in expected config files
echo "Checking config files have jwt-cache-max-lifetime..."
if grep -q 'jwt-cache-max-lifetime' "test/io/configs/expected/defaults.config"; then
    echo "✓ defaults.config has jwt-cache-max-lifetime"
else
    echo "✗ defaults.config missing jwt-cache-max-lifetime - fix not applied"
    test_status=1
fi

if grep -q 'jwt-cache-max-lifetime' "test/io/configs/expected/types.config"; then
    echo "✓ types.config has jwt-cache-max-lifetime"
else
    echo "✗ types.config missing jwt-cache-max-lifetime - fix not applied"
    test_status=1
fi

# Check that the cache and clock dependencies are in postgrest.cabal
echo "Checking postgrest.cabal has cache and clock dependencies..."
if grep -q 'cache.*>= 0.1.3' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has cache dependency"
else
    echo "✗ postgrest.cabal missing cache dependency - fix not applied"
    test_status=1
fi

if grep -q 'clock.*>= 0.8.3' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has clock dependency"
else
    echo "✗ postgrest.cabal missing clock dependency - fix not applied"
    test_status=1
fi

# Check that AppState exports AuthResult and getJwtCache
echo "Checking AppState.hs exports AuthResult and getJwtCache..."
if grep -q 'AuthResult(..)' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs exports AuthResult"
else
    echo "✗ AppState.hs missing AuthResult export - fix not applied"
    test_status=1
fi

if grep -q 'getJwtCache' "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs exports getJwtCache"
else
    echo "✗ AppState.hs missing getJwtCache export - fix not applied"
    test_status=1
fi

# Check that CHANGELOG has JWT caching entry
echo "Checking CHANGELOG.md has JWT caching entry..."
if grep -q 'jwt-cache-max-lifetime' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has jwt-cache-max-lifetime entry"
else
    echo "✗ CHANGELOG.md missing JWT caching entry - fix not applied"
    test_status=1
fi

# Check that test_io.py has JWT caching tests
echo "Checking test_io.py has JWT caching test functions..."
if grep -q 'test_server_timing_jwt_should_decrease_on_subsequent_requests' "test/io/test_io.py"; then
    echo "✓ test_io.py has test_server_timing_jwt_should_decrease_on_subsequent_requests"
else
    echo "✗ test_io.py missing JWT caching test - fix not applied"
    test_status=1
fi

if grep -q 'test_jwt_caching_works_with_db_plan_disabled' "test/io/test_io.py"; then
    echo "✓ test_io.py has test_jwt_caching_works_with_db_plan_disabled"
else
    echo "✗ test_io.py missing JWT caching test - fix not applied"
    test_status=1
fi

# Check that SpecHelper.hs has configJwtCacheMaxLifetime
echo "Checking SpecHelper.hs has configJwtCacheMaxLifetime..."
if grep -q 'configJwtCacheMaxLifetime' "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs has configJwtCacheMaxLifetime"
else
    echo "✗ SpecHelper.hs missing configJwtCacheMaxLifetime - fix not applied"
    test_status=1
fi

# Check that memory-tests.sh has correct memory threshold
echo "Checking memory-tests.sh has correct memory threshold (23M)..."
if grep -q 'jsonKeyTest "1M" "POST" "/rpc/leak?columns=blob" "23M"' "test/memory/memory-tests.sh"; then
    echo "✓ memory-tests.sh has correct memory threshold (23M)"
else
    echo "✗ memory-tests.sh has incorrect memory threshold - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
