#!/bin/bash

cd /app/src

# Set environment variables for golden file testing
export HSPEC_ACCEPT=false
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance1.out" "tests/purs/failing/FoldableInstance1.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance1.purs" "tests/purs/failing/FoldableInstance1.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance10.out" "tests/purs/failing/FoldableInstance10.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance10.purs" "tests/purs/failing/FoldableInstance10.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance2.out" "tests/purs/failing/FoldableInstance2.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance2.purs" "tests/purs/failing/FoldableInstance2.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance3.out" "tests/purs/failing/FoldableInstance3.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance3.purs" "tests/purs/failing/FoldableInstance3.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance4.out" "tests/purs/failing/FoldableInstance4.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance4.purs" "tests/purs/failing/FoldableInstance4.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance5.out" "tests/purs/failing/FoldableInstance5.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance5.purs" "tests/purs/failing/FoldableInstance5.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance6.out" "tests/purs/failing/FoldableInstance6.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance6.purs" "tests/purs/failing/FoldableInstance6.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance7.out" "tests/purs/failing/FoldableInstance7.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance7.purs" "tests/purs/failing/FoldableInstance7.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance8.out" "tests/purs/failing/FoldableInstance8.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance8.purs" "tests/purs/failing/FoldableInstance8.purs"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance9.out" "tests/purs/failing/FoldableInstance9.out"
mkdir -p "tests/purs/failing"
cp "/tests/purs/failing/FoldableInstance9.purs" "tests/purs/failing/FoldableInstance9.purs"
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/DerivingFoldable.purs" "tests/purs/passing/DerivingFoldable.purs"
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/DerivingFunctor.purs" "tests/purs/passing/DerivingFunctor.purs"

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
