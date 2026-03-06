#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/utf-8.config" "test/io/configs/expected/utf-8.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/utf-8.config" "test/io/configs/utf-8.config"

# Verify the fix for loading UTF-8 config files
# In BASE state: configurator-pg is 0.2 (doesn't support UTF-8 with ASCII locale)
# After fix: configurator-pg is upgraded to 0.2.11 (supports UTF-8) and test files are added

test_status=0

echo "Checking test/io/configs/utf-8.config exists (contains UTF-8 characters)..."
if [ -f "test/io/configs/utf-8.config" ]; then
    echo "✓ test/io/configs/utf-8.config exists - fix is applied!"
    echo "Contents:"
    cat test/io/configs/utf-8.config
else
    echo "✗ test/io/configs/utf-8.config does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking test/io/configs/expected/utf-8.config exists (expected output)..."
if [ -f "test/io/configs/expected/utf-8.config" ]; then
    echo "✓ test/io/configs/expected/utf-8.config exists - fix is applied!"
else
    echo "✗ test/io/configs/expected/utf-8.config does not exist - fix not applied"
    test_status=1
fi

echo ""
echo "Checking postgrest.cabal has configurator-pg >= 0.2.11..."
if grep -q "configurator-pg.*>= 0.2.11" postgrest.cabal; then
    echo "✓ postgrest.cabal requires configurator-pg >= 0.2.11 - fix is applied!"
    grep "configurator-pg" postgrest.cabal
else
    echo "✗ postgrest.cabal does not require configurator-pg >= 0.2.11 - fix not applied"
    echo "Current configurator-pg version requirement:"
    grep "configurator-pg" postgrest.cabal || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking stack.yaml has configurator-pg-0.2.11 in extra-deps..."
if grep -q "configurator-pg-0.2.11" stack.yaml; then
    echo "✓ stack.yaml has configurator-pg-0.2.11 - fix is applied!"
    grep "configurator-pg" stack.yaml
else
    echo "✗ stack.yaml does not have configurator-pg-0.2.11 - fix not applied"
    echo "Current extra-deps:"
    grep -A5 "extra-deps:" stack.yaml || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking nix/overlays/haskell-packages.nix has configurator-pg 0.2.11 override..."
if grep -q '"configurator-pg"' nix/overlays/haskell-packages.nix && \
   grep -q '"0.2.11"' nix/overlays/haskell-packages.nix; then
    echo "✓ nix/overlays/haskell-packages.nix has configurator-pg 0.2.11 override - fix is applied!"
else
    echo "✗ nix/overlays/haskell-packages.nix does not have configurator-pg 0.2.11 override - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
