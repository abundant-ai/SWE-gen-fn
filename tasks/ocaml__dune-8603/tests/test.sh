#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/dune-init"
cp "/tests/blackbox-tests/test-cases/dune-init/github7108.t" "test/blackbox-tests/test-cases/dune-init/github7108.t"
mkdir -p "test/blackbox-tests/test-cases/dune-init"
cp "/tests/blackbox-tests/test-cases/dune-init/public-implicit-invalid.t" "test/blackbox-tests/test-cases/dune-init/public-implicit-invalid.t"
mkdir -p "test/blackbox-tests/test-cases/dune-init"
cp "/tests/blackbox-tests/test-cases/dune-init/public-sublibrary.t" "test/blackbox-tests/test-cases/dune-init/public-sublibrary.t"
mkdir -p "test/blackbox-tests/test-cases"
cp "/tests/blackbox-tests/test-cases/github3046.t" "test/blackbox-tests/test-cases/github3046.t"

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

# Run the specific blackbox tests for this PR
echo "Running blackbox tests for dune-init/github7108..."
opam exec -- dune build @test/blackbox-tests/test-cases/dune-init/github7108 2>&1
test1_status=$?
echo "Test github7108 exit code: $test1_status"

echo "Running blackbox tests for dune-init/public-implicit-invalid..."
opam exec -- dune build @test/blackbox-tests/test-cases/dune-init/public-implicit-invalid 2>&1
test2_status=$?
echo "Test public-implicit-invalid exit code: $test2_status"

echo "Running blackbox tests for dune-init/public-sublibrary..."
opam exec -- dune build @test/blackbox-tests/test-cases/dune-init/public-sublibrary 2>&1
test3_status=$?
echo "Test public-sublibrary exit code: $test3_status"

echo "Running blackbox tests for github3046..."
opam exec -- dune build @test/blackbox-tests/test-cases/github3046 2>&1
test4_status=$?
echo "Test github3046 exit code: $test4_status"

# Overall test status - all must pass
if [ $test1_status -eq 0 ] && [ $test2_status -eq 0 ] && [ $test3_status -eq 0 ] && [ $test4_status -eq 0 ]; then
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
