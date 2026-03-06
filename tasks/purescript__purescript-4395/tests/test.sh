#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/TestCompiler.hs" "tests/TestCompiler.hs"
mkdir -p "tests"
cp "/tests/TestSourceMaps.hs" "tests/TestSourceMaps.hs"
mkdir -p "tests"
cp "/tests/TestUtils.hs" "tests/TestUtils.hs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance10.out" "tests/purs/failing/FoldableInstance10.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance10.purs" "tests/purs/failing/FoldableInstance10.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance5.out" "tests/purs/failing/FoldableInstance5.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance6.out" "tests/purs/failing/FoldableInstance6.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance7.out" "tests/purs/failing/FoldableInstance7.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance8.out" "tests/purs/failing/FoldableInstance8.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance9.out" "tests/purs/failing/FoldableInstance9.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance9.purs" "tests/purs/failing/FoldableInstance9.purs"

# Rebuild test suite to discover newly copied test files
stack build --fast --test --no-run-tests

# Run the specific FoldableInstance tests
# HSpec pattern matches test descriptions - this will match the FoldableInstance tests
stack test --fast --ta "--match FoldableInstance"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
