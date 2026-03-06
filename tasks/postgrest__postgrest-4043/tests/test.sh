#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AudienceJwtSecretSpec.hs" "test/spec/Feature/Auth/AudienceJwtSecretSpec.hs"
mkdir -p "test/spec/Feature/Auth"
cp "/tests/spec/Feature/Auth/AuthSpec.hs" "test/spec/Feature/Auth/AuthSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4043 which fixes JWT audience validation for array-valued aud claims
# HEAD state (9ca7da10) = fix applied, isValidAudClaim handles both string and array audiences
# BASE state (with bug.patch) = failedAudClaim only checks string, rejects arrays
# ORACLE state (BASE + fix.patch) = isValidAudClaim handles both string and array audiences

test_status=0

echo "Verifying source code matches HEAD state (JWT audience array validation fix)..."
echo ""

echo "Checking that Auth.hs has isValidAudClaim function with proper array handling..."
if grep -q "isValidAudClaim :: JSON.Value -> Either JwtError Bool" "src/PostgREST/Auth.hs" && \
   grep -q "isValidAudClaim (JSON.Array arr)" "src/PostgREST/Auth.hs" && \
   grep -q "allStrings arr = Right \$ maybe True" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs has isValidAudClaim with array handling - fix applied!"
else
    echo "✗ Auth.hs does not have proper isValidAudClaim with array handling - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs uses verifyClaim pattern (not failedAudClaim)..."
if grep -q "verifyClaim mclaims \"aud\" isValidAudClaim \"JWT not in audience\"" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs uses verifyClaim pattern - fix applied!"
else
    echo "✗ Auth.hs does not use verifyClaim pattern - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs has LambdaCase language extension..."
if grep -q "{-# LANGUAGE LambdaCase" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs has LambdaCase extension - fix applied!"
else
    echo "✗ Auth.hs does not have LambdaCase extension - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Auth.hs has allStrings helper function..."
if grep -q "allStrings = all" "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs has allStrings helper - fix applied!"
else
    echo "✗ Auth.hs does not have allStrings helper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that documentation has jwt_aud_validation section..."
if grep -q "jwt_aud_validation" "docs/references/auth.rst" && \
   grep -q "JWT \`\`aud\`\` Claim Validation" "docs/references/auth.rst"; then
    echo "✓ Documentation has jwt_aud_validation section - fix applied!"
else
    echo "✗ Documentation does not have jwt_aud_validation section - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that documentation mentions array handling..."
if grep -q "If the \`\`aud\`\` value is a JSON array of strings, it will search every element for a match" "docs/references/auth.rst"; then
    echo "✓ Documentation mentions array handling - fix applied!"
else
    echo "✗ Documentation does not mention array handling - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that postgrest.cabal includes jose-jwt dependency..."
if grep -q "jose-jwt" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes jose-jwt - fix applied!"
else
    echo "✗ postgrest.cabal does not include jose-jwt - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AudienceJwtSecretSpec.hs has comprehensive tests..."
if grep -q "succeeds when the audience claim has more than 1 element and one matches" "test/spec/Feature/Auth/AudienceJwtSecretSpec.hs"; then
    echo "✓ AudienceJwtSecretSpec has array audience tests - fix applied!"
else
    echo "✗ AudienceJwtSecretSpec does not have array audience tests - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Main.hs includes AudienceJwtSecretSpec (not disabledSpec)..."
if grep -q "Feature.Auth.AudienceJwtSecretSpec.spec" "test/spec/Main.hs"; then
    echo "✓ Main.hs includes AudienceJwtSecretSpec.spec - fix applied!"
else
    echo "✗ Main.hs does not include AudienceJwtSecretSpec.spec - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SpecHelper.hs has generateJWT function..."
if grep -q "generateJWT :: BL.ByteString -> ByteString" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper has generateJWT function - fix applied!"
else
    echo "✗ SpecHelper does not have generateJWT function - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
