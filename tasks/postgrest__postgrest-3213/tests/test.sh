#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/memory"
cp "/tests/memory/memory-tests.sh" "test/memory/memory-tests.sh"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for schema cache stats logging
echo "Checking that CHANGELOG.md includes the fix entry for schema cache stats..."
if grep -q "#3171, Log schema cache stats to stderr" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry for schema cache stats logging"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that AppState.hs imports timeItT
echo "Checking that AppState.hs imports timeItT..."
if grep -q "import.*System.TimeIt.*timeItT" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports timeItT from System.TimeIt"
else
    echo "✗ AppState.hs missing timeItT import - fix not applied"
    test_status=1
fi

# Check that AppState.hs imports Numeric module
echo "Checking that AppState.hs imports Numeric (showFFloat)..."
if grep -q "import Numeric" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs imports Numeric module"
else
    echo "✗ AppState.hs missing Numeric import - fix not applied"
    test_status=1
fi

# Check that AppState.hs imports showSummary from SchemaCache (handles multi-line import)
echo "Checking that AppState.hs imports showSummary from SchemaCache..."
if grep -A 2 "import PostgREST.SchemaCache" "src/PostgREST/AppState.hs" | grep -q "showSummary"; then
    echo "✓ AppState.hs imports showSummary from SchemaCache"
else
    echo "✗ AppState.hs missing showSummary import - fix not applied"
    test_status=1
fi

# Check that loadSchemaCache uses timeItT to measure query time (check with multi-line pattern)
echo "Checking that loadSchemaCache uses timeItT..."
if grep -q "(resultTime, result)" "src/PostgREST/AppState.hs" && grep -B 1 -A 1 "timeItT" "src/PostgREST/AppState.hs" | grep -q "querySchemaCache"; then
    echo "✓ loadSchemaCache uses timeItT to measure query time"
else
    echo "✗ loadSchemaCache not using timeItT - fix not applied"
    test_status=1
fi

# Check that loadSchemaCache logs the query time
echo "Checking that loadSchemaCache logs query time..."
if grep -q "Schema cache queried in.*showMillis resultTime.*milliseconds" "src/PostgREST/AppState.hs"; then
    echo "✓ loadSchemaCache logs schema cache query time"
else
    echo "✗ loadSchemaCache missing query time logging - fix not applied"
    test_status=1
fi

# Check that loadSchemaCache logs the schema cache summary
echo "Checking that loadSchemaCache logs schema cache summary..."
if grep -q "Schema cache loaded.*showSummary sCache" "src/PostgREST/AppState.hs"; then
    echo "✓ loadSchemaCache logs schema cache summary"
else
    echo "✗ loadSchemaCache missing summary logging - fix not applied"
    test_status=1
fi

# Check that showMillis helper function is defined
echo "Checking that showMillis helper function is defined..."
if grep -q "showMillis :: Double -> Text" "src/PostgREST/AppState.hs"; then
    echo "✓ showMillis helper function is defined"
else
    echo "✗ showMillis helper function missing - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs exports showSummary
echo "Checking that SchemaCache.hs exports showSummary..."
if grep -q ", showSummary" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs exports showSummary"
else
    echo "✗ SchemaCache.hs not exporting showSummary - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs imports Data.Text qualified
echo "Checking that SchemaCache.hs imports Data.Text..."
if grep -q "import qualified Data.Text" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs imports Data.Text"
else
    echo "✗ SchemaCache.hs missing Data.Text import - fix not applied"
    test_status=1
fi

# Check that showSummary function is implemented
echo "Checking that showSummary function is implemented..."
if grep -q "showSummary :: SchemaCache -> Text" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ showSummary function signature exists"
else
    echo "✗ showSummary function missing - fix not applied"
    test_status=1
fi

# Check that showSummary uses T.intercalate
echo "Checking that showSummary implementation uses T.intercalate..."
if grep -A 6 "showSummary (SchemaCache tbls rels routs reps mediaHdlrs" "src/PostgREST/SchemaCache.hs" | grep -q "T.intercalate"; then
    echo "✓ showSummary uses T.intercalate to format output"
else
    echo "✗ showSummary implementation incorrect - fix not applied"
    test_status=1
fi

# Check that showSummary includes counts for Relations, Relationships, Functions, etc.
echo "Checking that showSummary includes entity counts..."
if grep -A 6 "showSummary (SchemaCache" "src/PostgREST/SchemaCache.hs" | grep -q "Relations" && \
   grep -A 6 "showSummary (SchemaCache" "src/PostgREST/SchemaCache.hs" | grep -q "Relationships" && \
   grep -A 6 "showSummary (SchemaCache" "src/PostgREST/SchemaCache.hs" | grep -q "Functions"; then
    echo "✓ showSummary includes entity counts (Relations, Relationships, Functions)"
else
    echo "✗ showSummary missing entity counts - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
