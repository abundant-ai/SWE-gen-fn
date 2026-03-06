#!/bin/bash

cd /app/src

# Set CI flag for consistent test behavior
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Changes are reverted (old behavior)
# In HEAD (fix applied): Changes are present (new behavior)

test_status=0

echo "Verifying Haskell source code changes for schema cache error handling..."
echo ""

echo "Checking src/PostgREST/App.hs for connWorker condition with isJust maybeSchemaCache..."
if grep -q "when (isServiceUnavailable response && isJust maybeSchemaCache) connWorker" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has conditional connWorker check - fix is applied!"
else
    echo "✗ App.hs does not have conditional connWorker check - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/App.hs for SchemaCacheEmptyObs observer call..."
if grep -q "lift \$ observer SchemaCacheEmptyObs" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has SchemaCacheEmptyObs observer call - fix is applied!"
else
    echo "✗ App.hs does not have SchemaCacheEmptyObs observer call - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Observation.hs for SchemaCacheEmptyObs data constructor..."
if grep -q "| SchemaCacheEmptyObs" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has SchemaCacheEmptyObs data constructor - fix is applied!"
else
    echo "✗ Observation.hs does not have SchemaCacheEmptyObs data constructor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for SchemaCacheEmptyObs logging..."
if grep -q "o@SchemaCacheEmptyObs ->" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs has SchemaCacheEmptyObs logging - fix is applied!"
else
    echo "✗ Logger.hs does not have SchemaCacheEmptyObs logging - fix not applied"
    test_status=1
fi

echo ""
echo "Checking CHANGELOG.md for PR #4367 mention..."
if grep -q "#4367" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions PR #4367 - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention PR #4367 - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
