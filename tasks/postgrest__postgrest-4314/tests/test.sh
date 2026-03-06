#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Old logging mechanism without OpenAPI SQL logging
# In HEAD (fix applied): New logging mechanism that logs OpenAPI SQL queries

test_status=0

echo "Verifying Haskell source code changes for OpenAPI query logging fix..."
echo ""

echo "Checking CHANGELOG.md for PR mention..."
if grep -q "Fix not logging OpenAPI queries when \`log-query=main-query\` is enabled" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions OpenAPI query logging fix - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention OpenAPI query logging fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/App.hs for mainQuery and QueryObs pattern..."
if grep -q "let mainQ = Query.mainQuery plan conf apiReq authResult configDbPreRequest" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has mainQuery construction - fix is applied!"
else
    echo "✗ App.hs does not have mainQuery construction - fix not applied"
    test_status=1
fi

if grep -q "obsQuery s = when (configLogQuery /= LogQueryDisabled) \$ observer \$ QueryObs mainQ s" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has QueryObs observer pattern - fix is applied!"
else
    echo "✗ App.hs does not have QueryObs observer pattern - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for RecordWildCards extension..."
if grep -q "{-# LANGUAGE RecordWildCards #-}" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs has RecordWildCards language extension - fix is applied!"
else
    echo "✗ Logger.hs does not have RecordWildCards extension - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for MainQuery import..."
if grep -q "import PostgREST.Query       (MainQuery (..))" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs imports MainQuery - fix is applied!"
else
    echo "✗ Logger.hs does not import MainQuery - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for QueryObs pattern matching..."
if grep -q "QueryObs gq status -> do" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs has QueryObs pattern matching - fix is applied!"
else
    echo "✗ Logger.hs does not have QueryObs pattern matching - fix not applied"
    test_status=1
fi

if grep -q "logMainQ loggerState gq" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs calls logMainQ function - fix is applied!"
else
    echo "✗ Logger.hs does not call logMainQ function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Logger.hs for logMainQ function definition..."
if grep -q "logMainQ :: LoggerState -> MainQuery -> IO ()" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs has logMainQ function signature - fix is applied!"
else
    echo "✗ Logger.hs does not have logMainQ function signature - fix not applied"
    test_status=1
fi

if grep -q "logMainQ loggerState MainQuery{mqOpenAPI=(x, y, z),..}" "src/PostgREST/Logger.hs"; then
    echo "✓ Logger.hs logMainQ extracts OpenAPI queries - fix is applied!"
else
    echo "✗ Logger.hs logMainQ does not extract OpenAPI queries - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Observation.hs for QueryObs constructor..."
if grep -q "| QueryObs MainQuery Status" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs has QueryObs constructor - fix is applied!"
else
    echo "✗ Observation.hs does not have QueryObs constructor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Observation.hs for showOnSingleLine export..."
if grep -q "showOnSingleLine" "src/PostgREST/Observation.hs" && grep -q "showOnSingleLine :: Char -> Text -> Text" "src/PostgREST/Observation.hs"; then
    echo "✓ Observation.hs exports and defines showOnSingleLine - fix is applied!"
else
    echo "✗ Observation.hs does not export/define showOnSingleLine correctly - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
