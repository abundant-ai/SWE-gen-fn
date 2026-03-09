#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/dune-cache"
cp "/tests/blackbox-tests/test-cases/dune-cache/cache-man.t" "test/blackbox-tests/test-cases/dune-cache/cache-man.t"
cp "/tests/blackbox-tests/test-cases/dune-cache/clear.t" "test/blackbox-tests/test-cases/dune-cache/clear.t"

# Run the specific tests for this PR
# Temporarily hide other tests in dune-cache/ to avoid running them
cd test/blackbox-tests/test-cases/dune-cache
for f in *.t; do
  if [ "$f" != "cache-man.t" ] && [ "$f" != "clear.t" ]; then
    mv "$f" "$f.hidden" 2>/dev/null || true
  fi
done
cd /app/src

# Run the tests
dune runtest test/blackbox-tests/test-cases/dune-cache
test_status=$?

# Restore hidden tests
cd test/blackbox-tests/test-cases/dune-cache
for f in *.t.hidden; do
  if [ -f "$f" ]; then
    mv "$f" "${f%.hidden}"
  fi
done
cd /app/src

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
