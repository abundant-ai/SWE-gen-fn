#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/helpers.sh" "test/blackbox-tests/test-cases/pkg/helpers.sh"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/outdated.t" "test/blackbox-tests/test-cases/pkg/outdated.t"
mkdir -p "test/expect-tests/dune_pkg_outdated"
cp "/tests/expect-tests/dune_pkg_outdated/dune" "test/expect-tests/dune_pkg_outdated/dune"
mkdir -p "test/expect-tests/dune_pkg_outdated"
cp "/tests/expect-tests/dune_pkg_outdated/dune_pkg_outdated_test.ml" "test/expect-tests/dune_pkg_outdated/dune_pkg_outdated_test.ml"
mkdir -p "test/expect-tests/dune_pkg_outdated"
cp "/tests/expect-tests/dune_pkg_outdated/dune_pkg_outdated_test.mli" "test/expect-tests/dune_pkg_outdated/dune_pkg_outdated_test.mli"

# Rebuild dune if source files were modified (by Oracle agent)
# This ensures we test the current code state
echo "Rebuilding dune to reflect any code changes..."
echo "Starting bootstrap..."
opam exec -- ocaml boot/bootstrap.ml 2>&1 || { echo "Bootstrap failed with code $?"; exit 1; }
echo "Bootstrap done. Building dune..."
opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap 2>&1 || { echo "Build failed with code $?"; exit 1; }
echo "Build done. Building test utils..."
opam exec -- ./_boot/dune.exe build test/blackbox-tests/utils/dune_cmd.exe test/blackbox-tests/utils/dunepp.exe 2>&1 || { echo "Test utils build failed with code $?"; exit 1; }
echo "Rebuild complete!"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific tests for this PR (both blackbox and expect tests for dune_pkg_outdated)
echo "Running tests for dune_pkg_outdated..."
# Run expect tests
opam exec -- dune build @test/expect-tests/dune_pkg_outdated/runtest 2>&1
test_status=$?
echo "Expect test exit code: $test_status"

# If expect tests passed, also run blackbox test for pkg/outdated.t
if [ $test_status -eq 0 ]; then
  echo "Running blackbox test for pkg/outdated.t..."
  opam exec -- dune build @test/blackbox-tests/test-cases/pkg/outdated 2>&1
  test_status=$?
  echo "Blackbox test exit code: $test_status"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
