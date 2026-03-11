#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Rebuild hledger after oracle applies fix.patch (Haskell is compiled)
cabal install --jobs=$(nproc) --installdir=/root/.local/bin --install-method=copy --overwrite-policy=always \
    --ghc-options="-j$(nproc)" \
    hledger

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test/register"
cp "/tests/hledger/test/register/sort.test" "hledger/test/register/sort.test"

# Run the specific test file with shelltestrunner
shelltest --execdir hledger/test/register/sort.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
