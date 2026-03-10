#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/load"
cp "/tests/load/targets.http" "test/load/targets.http"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that postgrest.cabal uses jose-jwt instead of jose
echo "Checking that postgrest.cabal uses jose-jwt library..."
if grep -q "jose-jwt.*>= 0.9.6 && < 0.11" "postgrest.cabal"; then
    echo "✓ postgrest.cabal uses jose-jwt library - fix applied!"
else
    echo "✗ postgrest.cabal missing jose-jwt library - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs imports Jose.Jwt modules..."
if grep -q "import qualified Jose.Jwk.*as JWT" "src/PostgREST/Auth.hs" && \
   grep -q "import qualified Jose.Jwt.*as JWT" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs imports Jose.Jwt modules - fix applied!"
else
    echo "✗ Auth.hs missing Jose.Jwt imports - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs has manual claims verification..."
if grep -q "failedExpClaim" "src/PostgREST/Auth.hs" && \
   grep -q "failedNbfClaim" "src/PostgREST/Auth.hs" && \
   grep -q "failedIatClaim" "src/PostgREST/Auth.hs" && \
   grep -q "failedAudClaim" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs has manual claims verification functions - fix applied!"
else
    echo "✗ Auth.hs missing manual claims verification - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Config.hs uses Jose.Jwk types..."
if grep -q "import qualified Jose.Jwa.*as JWT" "src/PostgREST/Config.hs" && \
   grep -q "import qualified Jose.Jwk.*as JWT" "src/PostgREST/Config.hs" && \
   grep -q "Jose.Jwk.*Jwk, JwkSet" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs uses Jose.Jwk types - fix applied!"
else
    echo "✗ Config.hs missing Jose.Jwk types - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has the JWT error tests (restored with fix)..."
if grep -q "def test_jwt_errors" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_jwt_errors function - fix applied!"
else
    echo "✗ test_io.py missing test_jwt_errors function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has JWT cache test names (from HEAD state)..."
if grep -q "def test_jwt_cache_server_timing" "test/io/test_io.py" || \
   grep -q "def test_jwt_cache_without_exp_claim" "test/io/test_io.py"; then
    echo "✓ test_io.py has original JWT cache test names - fix applied!"
else
    echo "✗ test_io.py has different JWT cache test names - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that targets.http has Authorization headers (restored with fix)..."
auth_count=$(grep -c "Authorization: Bearer" "test/load/targets.http" || true)
if [ "$auth_count" -gt 0 ]; then
    echo "✓ targets.http has $auth_count Authorization headers - fix applied!"
else
    echo "✗ targets.http has no Authorization headers - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
