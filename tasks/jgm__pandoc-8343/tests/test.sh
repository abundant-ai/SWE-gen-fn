#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "pandoc-lua-engine/test/Tests/Lua"
cp "/tests/pandoc-lua-engine/test/Tests/Lua/Writer.hs" "pandoc-lua-engine/test/Tests/Lua/Writer.hs"

# Rebuild after copying updated test file
cabal build --enable-tests --disable-optimization

# Run the specific test for the Lua Writer module
# Using tasty-pattern to run only tests matching "Custom writers"
cabal test pandoc-lua-engine --test-show-details=direct --test-option='--pattern' --test-option='Custom writers'
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
