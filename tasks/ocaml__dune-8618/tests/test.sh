#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "otherlibs/stdune/test"
cp "/tests/otherlibs/stdune/test/bytes_unit_tests.ml" "otherlibs/stdune/test/bytes_unit_tests.ml"
mkdir -p "test/blackbox-tests/test-cases/dune-cache"
cp "/tests/blackbox-tests/test-cases/dune-cache/cache-man.t" "test/blackbox-tests/test-cases/dune-cache/cache-man.t"
mkdir -p "test/expect-tests/dune_sexp"
cp "/tests/expect-tests/dune_sexp/dune" "test/expect-tests/dune_sexp/dune"
mkdir -p "test/expect-tests/dune_sexp"
cp "/tests/expect-tests/dune_sexp/dune_sexp_tests.ml" "test/expect-tests/dune_sexp/dune_sexp_tests.ml"

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

# Run the specific tests for this PR
echo "Running blackbox tests for dune-cache..."
opam exec -- dune build @test/blackbox-tests/test-cases/dune-cache/cache-man 2>&1
blackbox_status=$?
echo "Blackbox test exit code: $blackbox_status"

# Run expect tests for dune_sexp module
echo "Running expect tests for dune_sexp..."
opam exec -- dune runtest test/expect-tests/dune_sexp 2>&1
expect_status=$?
echo "Expect test exit code: $expect_status"

# Run unit tests for stdune bytes
echo "Running unit tests for stdune bytes..."
opam exec -- dune runtest otherlibs/stdune/test 2>&1
stdune_status=$?
echo "Stdune test exit code: $stdune_status"

# Overall test status - all must pass
if [ $blackbox_status -eq 0 ] && [ $expect_status -eq 0 ] && [ $stdune_status -eq 0 ]; then
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
