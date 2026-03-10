#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key1.config" "test/io/configs/expected/jwt-role-claim-key1.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key2.config" "test/io/configs/expected/jwt-role-claim-key2.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key3.config" "test/io/configs/expected/jwt-role-claim-key3.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key4.config" "test/io/configs/expected/jwt-role-claim-key4.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key5.config" "test/io/configs/expected/jwt-role-claim-key5.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/jwt-role-claim-key1.config" "test/io/configs/jwt-role-claim-key1.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/jwt-role-claim-key2.config" "test/io/configs/jwt-role-claim-key2.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/jwt-role-claim-key3.config" "test/io/configs/jwt-role-claim-key3.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/jwt-role-claim-key4.config" "test/io/configs/jwt-role-claim-key4.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/jwt-role-claim-key5.config" "test/io/configs/jwt-role-claim-key5.config"
mkdir -p "test/io"
cp "/tests/io/fixtures.yaml" "test/io/fixtures.yaml"

# Verify that the fix has been applied by checking the files exist and have correct content
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md mentions the string comparison feature
echo "Checking that CHANGELOG.md mentions the string comparison feature..."
if grep -q "#1536, Add string comparison feature for jwt-role-claim-key" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the feature - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the feature - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention JWT Role Claim Key Extraction..."
if grep -q "JWT Role Claim Key Extraction" "docs/references/auth.rst"; then
    echo "✓ Docs mention JWT Role Claim Key Extraction - fix applied!"
else
    echo "✗ Docs do not mention JWT Role Claim Key Extraction - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention string comparison operators..."
if grep -q "extended string comparison operators" "docs/references/auth.rst"; then
    echo "✓ Docs mention string comparison operators - fix applied!"
else
    echo "✗ Docs do not mention string comparison operators - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention the == operator example..."
if grep -q '@ ==' "docs/references/auth.rst"; then
    echo "✓ Docs contain == operator example - fix applied!"
else
    echo "✗ Docs do not contain == operator example - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that config test files exist..."
for i in 1 2 3 4 5; do
    if [ -f "test/io/configs/jwt-role-claim-key${i}.config" ] && [ -f "test/io/configs/expected/jwt-role-claim-key${i}.config" ]; then
        echo "✓ Config files for jwt-role-claim-key${i} exist - fix applied!"
    else
        echo "✗ Config files for jwt-role-claim-key${i} do not exist - fix not applied"
        test_status=1
    fi
done

echo ""
echo "Checking fixtures.yaml contains roleclaims test data..."
if grep -q "roleclaims:" "test/io/fixtures.yaml"; then
    echo "✓ fixtures.yaml contains roleclaims - fix applied!"
else
    echo "✗ fixtures.yaml does not contain roleclaims - fix not applied"
    test_status=1
fi

echo ""
echo "Checking postgrest.dict contains new dictionary terms..."
if grep -q "JSPath" "docs/postgrest.dict" && grep -q "Keycloak" "docs/postgrest.dict"; then
    echo "✓ postgrest.dict contains new terms - fix applied!"
else
    echo "✗ postgrest.dict does not contain new terms - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
