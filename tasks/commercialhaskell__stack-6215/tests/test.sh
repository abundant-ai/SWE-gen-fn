#!/bin/bash

cd /app/src

# Oracle agent should apply solution/fix.patch before test.sh runs
# Check if the fix has been applied by looking for a marker from the patch
if grep -q "spacedBulletedList" src/Stack/Prelude.hs; then
    echo "=== FIX APPLIED: spacedBulletedList found in Stack.Prelude ==="
else
    echo "=== FIX NOT APPLIED: spacedBulletedList not found in Stack.Prelude ==="
    echo "This means the code is in BASE (buggy) state"
fi

# Copy HEAD test files from /tests (overwrites BASE state)
# Copy the entire test directories including files subdirectories
echo "=== Copying test 3685 ==="
cp -rv "/tests/integration/tests/3685-config-yaml-for-allow-newer" "test/integration/tests/"
echo "=== Checking if copy worked ==="
head -5 "test/integration/tests/3685-config-yaml-for-allow-newer/Main.hs"
echo "=== Copying test 4897 ==="
cp -rv "/tests/integration/tests/4897-boot-package-pruned" "test/integration/tests/"

# Rebuild the integration test suite to pick up the copied test file changes
# This picks up both the patched source code changes and the new test files
stack build --flag stack:integration-tests --test --no-run-tests --fast 2>&1

# Add GHC bin directory to PATH so runghc is available
export PATH=$(stack path --compiler-bin):$PATH

# The integration test runner expects to find the stack executable in the same directory
# Copy the stack executable to the same directory as the integration test executable
DIST_DIR=$(stack path --dist-dir)
INT_TEST_DIR=$DIST_DIR/build/stack-integration-test
STACK_BIN=$(stack path --local-install-root)/bin/stack

# Copy stack executable to integration test directory
cp $STACK_BIN $INT_TEST_DIR/stack

# Run both integration tests using the --match filter
# The integration test runner will output results to stdout
$INT_TEST_DIR/stack-integration-test --match "3685-config-yaml-for-allow-newer" 2>&1
test1_status=$?

$INT_TEST_DIR/stack-integration-test --match "4897-boot-package-pruned" 2>&1
test2_status=$?

# Both tests must pass
if [ $test1_status -eq 0 ] && [ $test2_status -eq 0 ]; then
  test_status=0
else
  test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
