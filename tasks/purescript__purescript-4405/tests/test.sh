#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet.out" "tests/purs/failing/DuplicateDeclarationsInLet.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet.purs" "tests/purs/failing/DuplicateDeclarationsInLet.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet2.out" "tests/purs/failing/DuplicateDeclarationsInLet2.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet2.purs" "tests/purs/failing/DuplicateDeclarationsInLet2.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet3.out" "tests/purs/failing/DuplicateDeclarationsInLet3.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/DuplicateDeclarationsInLet3.purs" "tests/purs/failing/DuplicateDeclarationsInLet3.purs"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific failing tests
# HSpec pattern matches test descriptions - this will match the three DuplicateDeclarationsInLet tests
stack test --fast --ta "--match DuplicateDeclarationsInLet"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
