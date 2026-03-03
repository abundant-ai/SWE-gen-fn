#!/bin/bash
set -e  # Exit on error

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/command"
cp "/tests/command/10152.md" "test/command/10152.md"

# Build the test suite (this was moved from Dockerfile to avoid build timeout)
echo "Building pandoc test suite..."
cabal build --enable-tests --disable-optimization -j4 pandoc:test:test-pandoc || {
    echo "Build failed!" >&2
    echo 0 > /logs/verifier/reward.txt
    exit 1
}

# Run the specific test file using cabal test with pattern matching
# The test suite will look for test files in the test/command directory
# We use -p to pattern match the specific test name "10152"
echo "Running test 10152..."
cabal test --enable-tests --disable-optimization --test-show-details=direct \
  --test-options="--hide-successes --ansi-tricks=false -p 10152" pandoc:test:test-pandoc
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
