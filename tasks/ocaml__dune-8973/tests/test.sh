#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/pkg/lock-directory-regeneration-safety.t"
cp "/tests/blackbox-tests/test-cases/pkg/lock-directory-regeneration-safety.t/run.t" "test/blackbox-tests/test-cases/pkg/lock-directory-regeneration-safety.t/run.t"
mkdir -p "test/blackbox-tests/test-cases/pkg"
cp "/tests/blackbox-tests/test-cases/pkg/solver-vars-in-lockdir-metadata.t" "test/blackbox-tests/test-cases/pkg/solver-vars-in-lockdir-metadata.t"
mkdir -p "test/expect-tests/dune_pkg"
cp "/tests/expect-tests/dune_pkg/dune_pkg_unit_tests.ml" "test/expect-tests/dune_pkg/dune_pkg_unit_tests.ml"

# Run the specific tests for this PR
# Move other tests out of pkg/ temporarily to avoid running them
mkdir -p /tmp/hidden-tests
cd test/blackbox-tests/test-cases/pkg

# Move all .t files and directories except the ones we want to test
shopt -s nullglob
for item in *.t; do
  if [ "$item" != "lock-directory-regeneration-safety.t" ] && [ "$item" != "solver-vars-in-lockdir-metadata.t" ]; then
    mv "$item" "/tmp/hidden-tests/$item" 2>/dev/null || true
  fi
done
shopt -u nullglob

cd /app/src

# Run the blackbox tests
dune runtest test/blackbox-tests/test-cases/pkg 2>&1
test_status=$?

# Restore hidden tests
shopt -s nullglob
for item in /tmp/hidden-tests/*; do
  if [ -e "$item" ]; then
    mv "$item" "test/blackbox-tests/test-cases/pkg/" 2>/dev/null || true
  fi
done
shopt -u nullglob

# Also run the expect test
if [ $test_status -eq 0 ]; then
  dune runtest test/expect-tests/dune_pkg
  test_status=$?
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
