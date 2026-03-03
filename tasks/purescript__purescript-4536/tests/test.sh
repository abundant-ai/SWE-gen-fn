#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests/purs/passing"
cp "/tests/purs/passing/4535.purs" "tests/purs/passing/4535.purs"

# Run the specific test using Stack with HSpec filtering
stack test --test-arguments "--match '/Passing examples/4535.purs/'"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
