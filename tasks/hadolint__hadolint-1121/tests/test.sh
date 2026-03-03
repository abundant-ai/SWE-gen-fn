#!/bin/bash

cd /app/src

# Set Hspec environment for colored output
export HSPEC_OPTIONS="--color"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Hadolint/Rule"
cp "/tests/Hadolint/Rule/DL3033Spec.hs" "test/Hadolint/Rule/DL3033Spec.hs"
mkdir -p "test/Hadolint/Rule"
cp "/tests/Hadolint/Rule/DL3041Spec.hs" "test/Hadolint/Rule/DL3041Spec.hs"

# Run only the specific test files using cabal test with pattern matching
# Hspec allows running specific test modules using --match pattern
cabal test hadolint-unit-tests --test-option=--match --test-option="DL3033" --test-option=--match --test-option="DL3041" --test-show-details=direct
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
