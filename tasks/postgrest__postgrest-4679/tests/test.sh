#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4679 which refactors observation/logging to emit multiple log lines
# HEAD state (711264a0cda076a3953854bf6be7767d988fc602) = fix applied, observationMessages returns [Text]
# BASE state (with bug.patch) = old observationMessage returns Text

test_status=0

echo "Verifying source code matches HEAD state (observation/logging refactored)..."
echo ""

echo "Checking that src/PostgREST/Observation.hs does NOT have SchemaCacheSummaryObs..."
if grep -q "| SchemaCacheSummaryObs Text" "src/PostgREST/Observation.hs"; then
    echo "✗ src/PostgREST/Observation.hs still has SchemaCacheSummaryObs - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/Observation.hs does not have SchemaCacheSummaryObs - fix applied!"
fi

echo ""
echo "Checking that src/PostgREST/Observation.hs has SchemaCacheLoadedObs with Double and Text..."
if grep -q "| SchemaCacheLoadedObs Double Text" "src/PostgREST/Observation.hs"; then
    echo "✓ src/PostgREST/Observation.hs has SchemaCacheLoadedObs Double Text - fix applied!"
else
    echo "✗ src/PostgREST/Observation.hs does not have SchemaCacheLoadedObs Double Text - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Logger.hs has observationMessages function..."
if grep -q "observationMessages :: Observation -> \[Text\]" "src/PostgREST/Logger.hs"; then
    echo "✓ src/PostgREST/Logger.hs has observationMessages function - fix applied!"
else
    echo "✗ src/PostgREST/Logger.hs does not have observationMessages function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Logger.hs logWithZTime takes [Text]..."
if grep -q "logWithZTime :: LoggerState -> \[Text\] -> IO ()" "src/PostgREST/Logger.hs"; then
    echo "✓ src/PostgREST/Logger.hs logWithZTime takes [Text] - fix applied!"
else
    echo "✗ src/PostgREST/Logger.hs logWithZTime does not take [Text] - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Logger.hs SchemaCacheLoadedObs emits two log lines..."
if grep -A 3 "SchemaCacheLoadedObs resultTime summary" "src/PostgREST/Logger.hs" | grep -q "Schema cache loaded in"; then
    echo "✓ src/PostgREST/Logger.hs SchemaCacheLoadedObs emits proper log messages - fix applied!"
else
    echo "✗ src/PostgREST/Logger.hs SchemaCacheLoadedObs does not emit proper log messages - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/AppState.hs uses uncurry SchemaCacheLoadedObs..."
if grep -q "observer . uncurry SchemaCacheLoadedObs" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs uses uncurry SchemaCacheLoadedObs - fix applied!"
else
    echo "✗ src/PostgREST/AppState.hs does not use uncurry SchemaCacheLoadedObs - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
