#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/expect-tests/dune_rpc_impl"
cp "/tests/expect-tests/dune_rpc_impl/dune" "test/expect-tests/dune_rpc_impl/dune"
mkdir -p "test/expect-tests/dune_rpc_impl"
cp "/tests/expect-tests/dune_rpc_impl/dune_rpc_impl_tests.ml" "test/expect-tests/dune_rpc_impl/dune_rpc_impl_tests.ml"

# To avoid running unrelated tests, move entire subdirectories out of the test-cases directory
# Keep only the expect-tests/dune_rpc_impl directory
mkdir -p /tmp/skipped-tests
cd test/expect-tests
for item in *; do
  if [ "$item" != "dune_rpc_impl" ]; then
    mv "$item" "/tmp/skipped-tests/" 2>/dev/null || true
  fi
done
cd /app/src

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
echo "Running dune_rpc_impl expect tests..."

# Run tests in the expect-tests directory (filtered to only our test directory above)
opam exec -- ./_boot/dune.exe runtest test/expect-tests 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
