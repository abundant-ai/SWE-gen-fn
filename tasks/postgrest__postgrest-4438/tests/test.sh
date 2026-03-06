#!/bin/bash

cd /app/src

# Compare the actual source files in the repo with the expected files with the fix applied
# The expected versions are in /tests (extracted from HEAD commit)
# In BASE state: files use dumpQi (no proper quoting) → diff will show differences → test fails
# After fix.patch: files use quoteQi (proper quoting) → diff shows no differences → test passes

test_status=0

echo "Comparing src/PostgREST/AppState.hs with expected version..."
if diff -q src/PostgREST/AppState.hs /tests/src/PostgREST/AppState.hs >/dev/null 2>&1; then
    echo "✓ src/PostgREST/AppState.hs matches expected version"
else
    echo "✗ src/PostgREST/AppState.hs differs from expected version"
    echo "Differences:"
    diff -u src/PostgREST/AppState.hs /tests/src/PostgREST/AppState.hs | head -50
    test_status=1
fi

echo "Comparing src/PostgREST/SchemaCache/Identifiers.hs with expected version..."
if diff -q src/PostgREST/SchemaCache/Identifiers.hs /tests/src/PostgREST/SchemaCache/Identifiers.hs >/dev/null 2>&1; then
    echo "✓ src/PostgREST/SchemaCache/Identifiers.hs matches expected version"
else
    echo "✗ src/PostgREST/SchemaCache/Identifiers.hs differs from expected version"
    echo "Differences:"
    diff -u src/PostgREST/SchemaCache/Identifiers.hs /tests/src/PostgREST/SchemaCache/Identifiers.hs | head -50
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "Haskell source files correctly use quoteQi for proper identifier quoting!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
