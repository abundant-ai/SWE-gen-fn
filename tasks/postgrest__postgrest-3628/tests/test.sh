#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entry for PR #3607
echo "Checking that CHANGELOG.md has the fix entry for PR #3607..."
if grep -q "#3607, Log to stderr when the JWT secret is less than 32 characters long" "CHANGELOG.md" && \
   grep -q "#3607, PostgREST now fails to start when the JWT secret is less than 32 characters long" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #3607 fix entries - fix applied!"
else
    echo "✗ CHANGELOG.md missing PR #3607 fix entries - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Config.hs has the JWT secret length validation..."
if grep -q "The JWT secret must be at least 32 characters long" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has JWT secret length validation - fix applied!"
else
    echo "✗ Config.hs missing JWT secret length validation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has the test_secret_min_length test..."
if grep -q "def test_secret_min_length" "test/io/test_io.py" && \
   grep -q "The JWT secret must be at least 32 characters long" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_secret_min_length test - fix applied!"
else
    echo "✗ test_io.py missing test_secret_min_length test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
