#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy fixed test files from /tests to overwrite buggy test from bug.patch
# This ensures the test expects correct behavior
# NOP: Has buggy code + correct test expectations → test FAILS
# Oracle: Has fixed code + correct test expectations → test PASSES
mkdir -p /app/src/test/blackbox-tests/test-cases/pkg
cp /tests/blackbox-tests/test-cases/pkg/substitute.t /app/src/test/blackbox-tests/test-cases/pkg/substitute.t

# Rebuild dune to reflect the current code state (buggy for NOP, fixed for Oracle)
# Note: We need to use the fully-built dune, not just bootstrap, because the Substs
# module requires opam libraries which aren't available during bootstrap.
echo "Rebuilding dune..."

# Clean build directory to avoid stale artifacts from the buggy build in Dockerfile
rm -rf _build

# Build the full dune using the bootstrapped dune
opam exec -- ./_boot/dune.exe build @install --release 2>&1
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Build failed with exit code $build_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Use the fully built dune binary for running tests
DUNE_BIN="_build/install/default/bin/dune"

# Run the specific tests for this PR using the bootstrapped dune
echo "Running tests for PR #8225..."

# Create isolated test directory for the specific test (cram tests need proper dune setup)
mkdir -p /tmp/test-isolated
cd /tmp/test-isolated

# Create dune-project
cat > dune-project << 'EOF'
(lang dune 3.9)
(package (name test-isolated))
EOF

# Create dune file with proper binaries setup
# CRITICAL: Set up dune binary in PATH so cram test can find it
cat > dune <<EOF
(env
 (_
  (binaries (dune_wrapper.exe as dune))))

(rule
 (targets dune_wrapper.exe)
 (deps /app/src/$DUNE_BIN)
 (action (copy /app/src/$DUNE_BIN %{targets})))

(cram
 (deps %{bin:strace} %{bin:head} %{bin:dune}))
EOF

# Copy the test file
cp /app/src/test/blackbox-tests/test-cases/pkg/substitute.t .

# Run the test with the fully built dune
/app/src/$DUNE_BIN runtest --force --display=short 2>&1
test_status=$?
cd /app/src
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
