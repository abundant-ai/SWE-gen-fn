#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying Server-Timing feature implementation..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/NullsStripSpec.hs" "test/spec/Feature/Query/NullsStripSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ServerTimingSpec.hs" "test/spec/Feature/Query/ServerTimingSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Check that CHANGELOG.md has the Server-Timing entry
echo "Checking CHANGELOG.md for Server-Timing feature entry..."
if grep -q '#2771.*Server-Timing.*JWT' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has Server-Timing feature entry"
else
    echo "✗ CHANGELOG.md missing Server-Timing entry - fix not applied"
    test_status=1
fi

# Check that timeit dependency is added to cabal file
echo "Checking postgrest.cabal has timeit dependency..."
if grep -q 'timeit.*>= 2.0 && < 2.1' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has timeit dependency"
else
    echo "✗ postgrest.cabal missing timeit dependency - fix not applied"
    test_status=1
fi

# Check that ServerTimingSpec test is added to cabal file
echo "Checking postgrest.cabal includes ServerTimingSpec test..."
if grep -q 'Feature.Query.ServerTimingSpec' "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes ServerTimingSpec test"
else
    echo "✗ postgrest.cabal missing ServerTimingSpec test - fix not applied"
    test_status=1
fi

# Check that NullsStripSpec is correctly named (not NullsStrip)
echo "Checking postgrest.cabal has correct NullsStripSpec naming..."
if grep -q 'Feature.Query.NullsStripSpec' "postgrest.cabal" && \
   ! grep -q 'Feature.Query.NullsStrip[^S]' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has correct NullsStripSpec naming"
else
    echo "✗ postgrest.cabal has incorrect test naming - fix not applied"
    test_status=1
fi

# Check that Auth module exports getJwtDur
echo "Checking Auth.hs exports getJwtDur..."
if grep -q 'getJwtDur' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs exports getJwtDur"
else
    echo "✗ Auth.hs missing getJwtDur export - fix not applied"
    test_status=1
fi

# Check that Auth module imports timeItT from System.TimeIt
echo "Checking Auth.hs imports timeItT..."
if grep -q 'System.TimeIt.*timeItT' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs imports timeItT"
else
    echo "✗ Auth.hs missing timeItT import - fix not applied"
    test_status=1
fi

# Check that jwtDurKey is defined in Auth.hs
echo "Checking Auth.hs defines jwtDurKey..."
if grep -q 'jwtDurKey :: Vault.Key Double' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs defines jwtDurKey"
else
    echo "✗ Auth.hs missing jwtDurKey definition - fix not applied"
    test_status=1
fi

# Check that getJwtDur function is defined in Auth.hs
echo "Checking Auth.hs defines getJwtDur function..."
if grep -q 'getJwtDur :: Wai.Request -> Maybe Double' "src/PostgREST/Auth.hs" && \
   grep -q 'getJwtDur.*Vault.lookup jwtDurKey' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs defines getJwtDur function"
else
    echo "✗ Auth.hs missing getJwtDur function - fix not applied"
    test_status=1
fi

# Check that middleware uses timeItT when configDbPlanEnabled
echo "Checking Auth.hs middleware uses timeItT conditionally..."
if grep -q 'configDbPlanEnabled conf' "src/PostgREST/Auth.hs" && \
   grep -q 'timeItT parseJwt' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs middleware uses timeItT conditionally"
else
    echo "✗ Auth.hs middleware not using timeItT - fix not applied"
    test_status=1
fi

# Check that middleware stores jwtDur in vault
echo "Checking Auth.hs stores jwtDur in vault..."
if grep -q 'Vault.insert jwtDurKey dur' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs stores jwtDur in vault"
else
    echo "✗ Auth.hs not storing jwtDur in vault - fix not applied"
    test_status=1
fi

# Check that Response module exports ServerTimingParams
echo "Checking Response.hs exports ServerTimingParams..."
if grep -q 'ServerTimingParams(..)' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs exports ServerTimingParams"
else
    echo "✗ Response.hs missing ServerTimingParams export - fix not applied"
    test_status=1
fi

# Check that ServerTimingParams is defined in Response.hs
echo "Checking Response.hs defines ServerTimingParams..."
if grep -q 'newtype ServerTimingParams' "src/PostgREST/Response.hs" && \
   grep -q 'jwtDur :: Double' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs defines ServerTimingParams with jwtDur"
else
    echo "✗ Response.hs missing ServerTimingParams definition - fix not applied"
    test_status=1
fi

# Check that Response.hs imports Numeric for showFFloat
echo "Checking Response.hs imports Numeric..."
if grep -q 'import.*Numeric.*showFFloat' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs imports Numeric for formatting"
else
    echo "✗ Response.hs missing Numeric import - fix not applied"
    test_status=1
fi

# Check that response functions accept ServerTimingParams parameter
echo "Checking Response.hs functions accept ServerTimingParams..."
if grep -q 'readResponse.*ServerTimingParams' "src/PostgREST/Response.hs" || \
   grep -q 'Maybe ServerTimingParams' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs functions accept ServerTimingParams"
else
    echo "✗ Response.hs functions not accepting ServerTimingParams - fix not applied"
    test_status=1
fi

# Check that App.hs imports ServerTimingParams
echo "Checking App.hs imports ServerTimingParams..."
if grep -q 'import PostgREST.Response.*ServerTimingParams' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports ServerTimingParams"
else
    echo "✗ App.hs missing ServerTimingParams import - fix not applied"
    test_status=1
fi

# Check that App.hs creates serverTimingParams with configDbPlanEnabled check
echo "Checking App.hs creates serverTimingParams..."
if grep -q 'serverTimingParams.*configDbPlanEnabled' "src/PostgREST/App.hs" && \
   grep -q 'ServerTimingParams.*jwtDur.*Auth.getJwtDur' "src/PostgREST/App.hs"; then
    echo "✓ App.hs creates serverTimingParams correctly"
else
    echo "✗ App.hs not creating serverTimingParams - fix not applied"
    test_status=1
fi

# Check that handleRequest signature includes ServerTimingParams parameter
echo "Checking App.hs handleRequest signature includes ServerTimingParams..."
if grep -q 'handleRequest.*Maybe ServerTimingParams' "src/PostgREST/App.hs"; then
    echo "✓ App.hs handleRequest signature includes ServerTimingParams"
else
    echo "✗ App.hs handleRequest signature missing ServerTimingParams - fix not applied"
    test_status=1
fi

# Check that handleRequest passes serverTimingParams to response functions
echo "Checking App.hs passes serverTimingParams to response functions..."
if grep -q 'readResponse.*serverTimingParams' "src/PostgREST/App.hs" && \
   grep -q 'createResponse.*serverTimingParams' "src/PostgREST/App.hs" && \
   grep -q 'updateResponse.*serverTimingParams' "src/PostgREST/App.hs" && \
   grep -q 'deleteResponse.*serverTimingParams' "src/PostgREST/App.hs" && \
   grep -q 'invokeResponse.*serverTimingParams' "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes serverTimingParams to all response functions"
else
    echo "✗ App.hs not passing serverTimingParams to all response functions - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
