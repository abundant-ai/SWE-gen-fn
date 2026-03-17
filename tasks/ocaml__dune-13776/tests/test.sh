#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/home/duneuser/.opam/4.14.1
export PATH="/home/duneuser/.opam/4.14.1/bin:${PATH}"
export DUNE_ROCQ_TEST=enable
export DUNE_ROCQ_NATIVE_TEST=enable

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/convert-opam-commands.t" "test/blackbox-tests/test-cases/pkg/convert-opam-commands.t"
mkdir -p "test/blackbox-tests/test-cases/pkg/depexts"
cp "/tests/blackbox-tests/test-cases/pkg/depexts/unknown-variable.t" "test/blackbox-tests/test-cases/pkg/depexts/unknown-variable.t"
mkdir -p "test/blackbox-tests/test-cases/pkg/opam-var"
cp "/tests/blackbox-tests/test-cases/pkg/opam-var/absent-pkg-installed.t" "test/blackbox-tests/test-cases/pkg/opam-var/absent-pkg-installed.t"

# Rebuild dune to reflect the current code state (buggy for NOP, fixed for Oracle)
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

# Run the specific blackbox tests for PR #13776
echo "Running tests for PR #13776..."
opam exec -- ./_boot/dune.exe test \
  test/blackbox-tests/test-cases/pkg/convert-opam-commands.t \
  test/blackbox-tests/test-cases/pkg/depexts/unknown-variable.t \
  test/blackbox-tests/test-cases/pkg/opam-var/absent-pkg-installed.t 2>&1
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 | sudo tee /logs/verifier/reward.txt > /dev/null
else
  echo 0 | sudo tee /logs/verifier/reward.txt > /dev/null
fi
exit "$test_status"
