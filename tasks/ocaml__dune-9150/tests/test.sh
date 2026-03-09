#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/opam-package-with-files-install.t" "test/blackbox-tests/test-cases/pkg/opam-package-with-files-install.t"

# Run the specific cram test for this PR
opam exec -- ./_boot/dune.exe build @test/blackbox-tests/test-cases/pkg/opam-package-with-files-install
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
