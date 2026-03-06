#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Hadolint/Config"
cp "/tests/Hadolint/Config/CommandlineSpec.hs" "test/Hadolint/Config/CommandlineSpec.hs"
mkdir -p "test/Hadolint/Config"
cp "/tests/Hadolint/Config/ConfigfileSpec.hs" "test/Hadolint/Config/ConfigfileSpec.hs"
mkdir -p "test/Hadolint/Config"
cp "/tests/Hadolint/Config/ConfigurationSpec.hs" "test/Hadolint/Config/ConfigurationSpec.hs"
mkdir -p "test/Hadolint/Config"
cp "/tests/Hadolint/Config/EnvironmentSpec.hs" "test/Hadolint/Config/EnvironmentSpec.hs"
mkdir -p "test/Hadolint/Rule"
cp "/tests/Hadolint/Rule/DL1001Spec.hs" "test/Hadolint/Rule/DL1001Spec.hs"

# Rebuild to incorporate the updated test files
cabal build all -j$(nproc) 2>&1 | tail -20
test_status=$?

if [ $test_status -ne 0 ]; then
  echo "Build failed after copying test files"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Find and run the test binary
TEST_BIN=$(find dist-newstyle -name hadolint-unit-tests -type f -executable | head -1)
if [ -z "$TEST_BIN" ]; then
  echo "Test binary not found!"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run only the specific test files for this PR
# Using hspec's --match flag to filter to specific test modules
$TEST_BIN --match "/Hadolint.Config.Commandline/" \
          --match "/Hadolint.Config.Configfile/" \
          --match "/Hadolint.Config.Configuration/" \
          --match "/Hadolint.Config.Environment/" \
          --match "/Hadolint.Rule.DL1001/"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
