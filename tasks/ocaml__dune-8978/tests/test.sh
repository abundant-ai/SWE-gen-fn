#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Use the locally built dune binary for testing
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/directory-targets/duplicate-target.t"
cp "/tests/blackbox-tests/test-cases/directory-targets/duplicate-target.t/run.t" "test/blackbox-tests/test-cases/directory-targets/duplicate-target.t/run.t"
mkdir -p "test/blackbox-tests/test-cases/github2061.t"
cp "/tests/blackbox-tests/test-cases/github2061.t/run.t" "test/blackbox-tests/test-cases/github2061.t/run.t"
mkdir -p "test/blackbox-tests/test-cases/promote"
cp "/tests/blackbox-tests/test-cases/promote/dep-on-promoted-target.t" "test/blackbox-tests/test-cases/promote/dep-on-promoted-target.t"
mkdir -p "test/blackbox-tests/test-cases/watching"
cp "/tests/blackbox-tests/test-cases/watching/target-promotion.t" "test/blackbox-tests/test-cases/watching/target-promotion.t"

# Run the specific tests for this PR
# Temporarily hide other tests in promote/ and watching/ to avoid running them
cd test/blackbox-tests/test-cases/promote
for f in *.t; do
  if [ "$f" != "dep-on-promoted-target.t" ]; then
    mv "$f" "$f.hidden" 2>/dev/null || true
  fi
done
cd /app/src

cd test/blackbox-tests/test-cases/watching
for f in *.t; do
  if [ "$f" != "target-promotion.t" ]; then
    mv "$f" "$f.hidden" 2>/dev/null || true
  fi
done
cd /app/src

# Run the tests
dune runtest test/blackbox-tests/test-cases/directory-targets/duplicate-target.t && \
dune runtest test/blackbox-tests/test-cases/github2061.t && \
dune runtest test/blackbox-tests/test-cases/promote && \
dune runtest test/blackbox-tests/test-cases/watching
test_status=$?

# Restore hidden tests
cd test/blackbox-tests/test-cases/promote
for f in *.t.hidden; do
  if [ -f "$f" ]; then
    mv "$f" "${f%.hidden}"
  fi
done
cd /app/src

cd test/blackbox-tests/test-cases/watching
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
