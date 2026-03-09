#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "otherlibs/dune-site/test"
cp "/tests/otherlibs/dune-site/test/run.t" "otherlibs/dune-site/test/run.t"
mkdir -p "otherlibs/dune-site/test"
cp "/tests/otherlibs/dune-site/test/run_2_9.t" "otherlibs/dune-site/test/run_2_9.t"
mkdir -p "test/blackbox-tests/test-cases"
cp "/tests/blackbox-tests/test-cases/ignore-promoted-internal-rules.t" "test/blackbox-tests/test-cases/ignore-promoted-internal-rules.t"

# Create a minimal test directory for the ignore-promoted-internal-rules test
# This allows us to run just this test without running all blackbox tests
mkdir -p "test/minimal-blackbox"
cp "/tests/blackbox-tests/test-cases/ignore-promoted-internal-rules.t" "test/minimal-blackbox/ignore-promoted-internal-rules.t"
cat > "test/minimal-blackbox/dune" <<'EOF'
(cram
 (deps
  (package dune)))
EOF

# Use the bootstrapped dune binary for testing (already built in Dockerfile)
export PATH="/app/src/_build/install/default/bin:${PATH}"

# Run the specific tests for this PR
# We run both dune-site tests and the minimal blackbox test for ignore-promoted-internal-rules
echo "Running dune-site tests and ignore-promoted-internal-rules test..."
opam exec -- ./_boot/dune.exe build @otherlibs/dune-site/test/runtest @test/minimal-blackbox/runtest 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
