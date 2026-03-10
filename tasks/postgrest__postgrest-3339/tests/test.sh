#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that nix/overlays/haskell-packages.nix has fuzzyset version pinned to 0.2.4
echo "Checking that nix/overlays/haskell-packages.nix pins fuzzyset to 0.2.4..."
if grep -q 'ver = "0.2.4";' "nix/overlays/haskell-packages.nix" && grep -q 'pkg = "fuzzyset";' "nix/overlays/haskell-packages.nix"; then
    echo "✓ nix/overlays/haskell-packages.nix pins fuzzyset to 0.2.4"
else
    echo "✗ nix/overlays/haskell-packages.nix does not pin fuzzyset to 0.2.4 - fix not applied"
    test_status=1
fi

# Check that postgrest.cabal has fuzzyset version constraint with upper bound < 0.3
echo "Checking that postgrest.cabal has fuzzyset >= 0.2.4 && < 0.3..."
if grep -q 'fuzzyset.*>= 0.2.4 && < 0.3' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has fuzzyset >= 0.2.4 && < 0.3"
else
    echo "✗ postgrest.cabal missing correct fuzzyset constraint - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs imports Data.FuzzySet (not Data.FuzzySet.Simple)
echo "Checking that src/PostgREST/Error.hs imports Data.FuzzySet..."
if grep -q 'import qualified Data.FuzzySet.*as Fuzzy' "src/PostgREST/Error.hs" && ! grep -q 'import qualified Data.FuzzySet.Simple' "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs imports Data.FuzzySet"
else
    echo "✗ src/PostgREST/Error.hs imports incorrect module - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs uses getOne instead of findOne
echo "Checking that src/PostgREST/Error.hs uses Fuzzy.getOne..."
if grep -q 'Fuzzy.getOne' "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses Fuzzy.getOne"
else
    echo "✗ src/PostgREST/Error.hs does not use Fuzzy.getOne - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs uses get instead of find
echo "Checking that src/PostgREST/Error.hs uses Fuzzy.get..."
if grep -q 'Fuzzy.get' "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses Fuzzy.get"
else
    echo "✗ src/PostgREST/Error.hs does not use Fuzzy.get - fix not applied"
    test_status=1
fi

# Check that stack.yaml has fuzzyset-0.2.4
echo "Checking that stack.yaml has fuzzyset-0.2.4..."
if grep -q 'fuzzyset-0.2.4' "stack.yaml"; then
    echo "✓ stack.yaml has fuzzyset-0.2.4"
else
    echo "✗ stack.yaml missing fuzzyset-0.2.4 - fix not applied"
    test_status=1
fi

# Check that stack.yaml.lock has fuzzyset-0.2.4 SHA
echo "Checking that stack.yaml.lock has fuzzyset-0.2.4 SHA..."
if grep -q 'fuzzyset-0.2.4@sha256:f1b6de8bf33277bf6255207541d65028f1f1ea93af5541b654c86b5674995485' "stack.yaml.lock"; then
    echo "✓ stack.yaml.lock has correct fuzzyset-0.2.4 SHA"
else
    echo "✗ stack.yaml.lock missing correct fuzzyset-0.2.4 SHA - fix not applied"
    test_status=1
fi

test_status=$test_status

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
