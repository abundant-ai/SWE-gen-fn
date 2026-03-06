#!/bin/bash

cd /app/src

# Set environment variable for golden file generation
export HSPEC_ACCEPT=false

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/Language/PureScript/Ide"
cp "/tests/Language/PureScript/Ide/FilterSpec.hs" "tests/Language/PureScript/Ide/FilterSpec.hs"
mkdir -p "tests/Language/PureScript/Ide"
cp "/tests/Language/PureScript/Ide/ImportsSpec.hs" "tests/Language/PureScript/Ide/ImportsSpec.hs"

# Run the specific IDE test specs
# HSpec pattern matches test descriptions - this will match both FilterSpec and ImportsSpec
stack test --fast --ta "--match Language.PureScript.Ide"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
