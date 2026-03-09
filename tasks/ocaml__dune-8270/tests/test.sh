#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# DON'T copy test files - use whatever is in the repo after patches
# NOP: Has buggy code + test expecting errors (from bug.patch)
# Oracle: Has fixed code + test expecting success (fix.patch applied)

# Clean build artifacts to avoid stale state
rm -rf _build .duneboot.exe _boot

# Rebuild dune after patches have been applied (Oracle applies fix, NOP doesn't)
echo "Rebuilding dune..."
opam exec -- ocaml boot/bootstrap.ml 2>&1
bootstrap_status=$?

if [ $bootstrap_status -ne 0 ]; then
  echo "Bootstrap failed with exit code $bootstrap_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap 2>&1
build_status=$?

if [ $build_status -ne 0 ]; then
  echo "Build failed with exit code $build_status"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Run the specific tests for this PR using the bootstrapped dune
echo "Running tests for PR #8270..."

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
cat > dune << 'EOF'
(env
 (_
  (binaries (dune_wrapper.exe as dune))))

(rule
 (targets dune_wrapper.exe)
 (deps /app/src/_boot/dune.exe)
 (action (copy /app/src/_boot/dune.exe %{targets})))

(cram
 (deps %{bin:strace} %{bin:head} %{bin:dune}))
EOF

# Copy the test file
cp /app/src/test/blackbox-tests/test-cases/github8041.t .

# Run the test with the bootstrapped dune
/app/src/_boot/dune.exe runtest --force --display=short 2>&1
test_status=$?
cd /app/src
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
