#!/bin/bash

cd /app/src

# Set up opam environment for running tests
export OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
export PATH="/root/.opam/4.14.1/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/blackbox-tests/test-cases/install/install-glob"
cp "/tests/blackbox-tests/test-cases/install/install-glob/install-glob-relative.t" "test/blackbox-tests/test-cases/install/install-glob/install-glob-relative.t"
cp "/tests/blackbox-tests/test-cases/install/install-glob/install-glob-with-prefix.t" "test/blackbox-tests/test-cases/install/install-glob/install-glob-with-prefix.t"
mkdir -p "test/blackbox-tests/test-cases"
cp "/tests/blackbox-tests/test-cases/start-install-dst-with-parent-error.t" "test/blackbox-tests/test-cases/start-install-dst-with-parent-error.t"

# To avoid running unrelated tests, move entire subdirectories out of the test-cases directory
# Keep only the install directory and our specific test file
mkdir -p /tmp/skipped-tests
cd test/blackbox-tests/test-cases
for item in *; do
  if [ "$item" != "install" ] && [ "$item" != "start-install-dst-with-parent-error.t" ] && [ "$item" != "dune" ]; then
    mv "$item" "/tmp/skipped-tests/" 2>/dev/null || true
  fi
done
cd /app/src

# Within install/install-glob, keep only our 2 test files
cd test/blackbox-tests/test-cases/install/install-glob
for item in *; do
  if [ "$item" != "install-glob-relative.t" ] && [ "$item" != "install-glob-with-prefix.t" ]; then
    mkdir -p /tmp/skipped-tests/install-glob
    mv "$item" "/tmp/skipped-tests/install-glob/" 2>/dev/null || true
  fi
done
cd /app/src

# Also remove other subdirectories within install/ if they exist
cd test/blackbox-tests/test-cases/install
for item in */; do
  if [ "$item" != "install-glob/" ]; then
    mkdir -p /tmp/skipped-tests/install
    mv "$item" "/tmp/skipped-tests/install/" 2>/dev/null || true
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
echo "Running install and parent-error blackbox tests..."

# Run tests in the blackbox-tests/test-cases directory (filtered to only our 3 test files above)
opam exec -- ./_boot/dune.exe runtest test/blackbox-tests/test-cases 2>&1
test_status=$?
echo "Test exit code: $test_status"

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
