#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4015 which fixes JWT cache invalidation when jwt-secret changes
# HEAD state (a622f29) = fix applied, JWT cache is invalidated on secret change
# BASE state (with bug.patch) = JWT cache NOT invalidated on secret change

test_status=0

echo "Verifying source code matches HEAD state (JWT cache invalidation fix applied)..."
echo ""

echo "Checking that CHANGELOG.md has JWT cache fix entry..."
if grep -q "#4014, Fix JWT cache allows old tokens after the jwt-secret is changed in a config reload" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has JWT cache fix entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have JWT cache fix entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs reads config at the start of readInDbConfig..."
if grep -q "^  conf <- getConfig appState" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs reads config into 'conf' variable - fix applied!"
else
    echo "✗ AppState.hs does not read config into 'conf' variable - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs compares old and new jwt-secret..."
if grep -q "if configJwtSecret conf == configJwtSecret newConf then" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs compares old and new jwt-secret - fix applied!"
else
    echo "✗ AppState.hs does not compare jwt-secret - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs calls JwtCache.emptyCache when secret changes..."
if grep -q "JwtCache.emptyCache (getJwtCacheState appState)" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs calls JwtCache.emptyCache - fix applied!"
else
    echo "✗ AppState.hs does not call JwtCache.emptyCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that JwtCache.hs exports emptyCache function..."
if grep -q ", emptyCache" "src/PostgREST/Auth/JwtCache.hs"; then
    echo "✓ JwtCache.hs exports emptyCache - fix applied!"
else
    echo "✗ JwtCache.hs does not export emptyCache - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that JwtCache.hs implements emptyCache function..."
if grep -q "emptyCache :: JwtCacheState -> IO ()" "src/PostgREST/Auth/JwtCache.hs"; then
    echo "✓ JwtCache.hs has emptyCache function signature - fix applied!"
else
    echo "✗ JwtCache.hs does not have emptyCache function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that JwtCache.hs calls C.purge in emptyCache..."
if grep -q "emptyCache JwtCacheState{jwtCache} = C.purge jwtCache" "src/PostgREST/Auth/JwtCache.hs"; then
    echo "✓ JwtCache.hs calls C.purge in emptyCache - fix applied!"
else
    echo "✗ JwtCache.hs does not call C.purge in emptyCache - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
