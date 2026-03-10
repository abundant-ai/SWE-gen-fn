#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/command"
cp "/tests/command/pdfstandard.md" "test/command/pdfstandard.md"

# Rebuild after copying updated test file
cabal build --enable-tests --disable-optimization

# Run the specific test for the pdfstandard command
cabal test pandoc --test-show-details=direct --test-option='--pattern' --test-option='pdfstandard.md'
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
