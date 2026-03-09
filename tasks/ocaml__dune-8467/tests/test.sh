#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Rebuild dune after patches have been applied (Oracle applies fix, NOP doesn't)
echo "Rebuilding dune..."
opam exec -- ocaml boot/bootstrap.ml 2>&1
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap 2>&1

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/default-exported-env.t" "test/blackbox-tests/test-cases/pkg/default-exported-env.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/helpers.sh" "test/blackbox-tests/test-cases/pkg/helpers.sh"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/install-action.t" "test/blackbox-tests/test-cases/pkg/install-action.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/install-missing-entry.t" "test/blackbox-tests/test-cases/pkg/install-missing-entry.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/installed-binary.t" "test/blackbox-tests/test-cases/pkg/installed-binary.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/per-context.t" "test/blackbox-tests/test-cases/pkg/per-context.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/substitute.t" "test/blackbox-tests/test-cases/pkg/substitute.t"

# Use the bootstrapped dune binary for testing (already built in Dockerfile)
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific tests for this PR using dune's test runner
echo "Running pkg tests..."
opam exec -- ./_boot/dune.exe build @test/blackbox-tests/test-cases/pkg/runtest 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
