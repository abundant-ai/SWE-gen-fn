#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for transaction mode refactoring (PR #2641)..."
echo ""
echo "NOTE: This PR moves transaction mode handling from Query module to Plan types"
echo "HEAD (fixed) should have txMode in Plan types (mrTxMode, crTxMode, readPlanTxMode, etc.)"
echo "BASE (buggy) has txMode in Query module with mode parameter in handleRequest"
echo ""

# Check Query.hs - HEAD should NOT have txMode function exported
echo "Checking src/PostgREST/Query.hs does NOT export txMode function..."
if ! grep -q ", txMode" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs does not export txMode function"
else
    echo "✗ Query.hs still exports txMode function - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should NOT pass mode parameter from Query.txMode to handleRequest
echo "Checking src/PostgREST/App.hs does NOT pass Query.txMode to handleRequest..."
if ! grep -q "Query.txMode apiRequest" "src/PostgREST/App.hs"; then
    echo "✓ App.hs does not pass Query.txMode to handleRequest"
else
    echo "✗ App.hs still passes Query.txMode to handleRequest - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should NOT have SQL.Mode as separate parameter in handleRequest signature
echo "Checking src/PostgREST/App.hs handleRequest signature does NOT have separate mode parameter..."
if ! grep -q "handleRequest :: AuthResult -> AppConfig -> AppState.AppState -> SQL.Mode -> Bool -> Bool" "src/PostgREST/App.hs"; then
    echo "✓ App.hs handleRequest does not have separate SQL.Mode parameter"
else
    echo "✗ App.hs handleRequest still has separate SQL.Mode parameter - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should use runQuery WITH mode argument
echo "Checking src/PostgREST/App.hs uses runQuery with mode argument..."
if grep -q "runQuery mode query =" "src/PostgREST/App.hs"; then
    echo "✓ App.hs runQuery defined with mode parameter"
else
    echo "✗ App.hs runQuery missing mode parameter - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should export readPlanTxMode
echo "Checking src/PostgREST/Plan.hs exports readPlanTxMode..."
if grep -q "readPlanTxMode" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs exports readPlanTxMode"
else
    echo "✗ Plan.hs does not export readPlanTxMode - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should export inspectPlanTxMode
echo "Checking src/PostgREST/Plan.hs exports inspectPlanTxMode..."
if grep -q "inspectPlanTxMode" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs exports inspectPlanTxMode"
else
    echo "✗ Plan.hs does not export inspectPlanTxMode - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have mrTxMode field in MutateReadPlan
echo "Checking src/PostgREST/Plan.hs MutateReadPlan has mrTxMode field..."
if grep -q "mrTxMode" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs MutateReadPlan has mrTxMode field"
else
    echo "✗ Plan.hs MutateReadPlan missing mrTxMode field - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have crTxMode field in CallReadPlan
echo "Checking src/PostgREST/Plan.hs CallReadPlan has crTxMode field..."
if grep -q "crTxMode" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs CallReadPlan has crTxMode field"
else
    echo "✗ Plan.hs CallReadPlan missing crTxMode field - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have callReadPlan WITH InvokeMethod parameter
echo "Checking src/PostgREST/Plan.hs callReadPlan signature has InvokeMethod..."
if grep -q "callReadPlan :: ProcDescription -> AppConfig -> SchemaCache -> ApiRequest -> InvokeMethod -> Either Error CallReadPlan" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs callReadPlan takes InvokeMethod parameter"
else
    echo "✗ Plan.hs callReadPlan missing InvokeMethod parameter - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should have separate infoProcResponse function
echo "Checking src/PostgREST/Response.hs has infoProcResponse function..."
if grep -q "infoProcResponse ::" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has separate infoProcResponse function"
else
    echo "✗ Response.hs missing separate infoProcResponse - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should have separate infoIdentResponse function
echo "Checking src/PostgREST/Response.hs has infoIdentResponse function..."
if grep -q "infoIdentResponse ::" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has separate infoIdentResponse function"
else
    echo "✗ Response.hs missing separate infoIdentResponse - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should have separate infoRootResponse
echo "Checking src/PostgREST/Response.hs has infoRootResponse function..."
if grep -q "infoRootResponse ::" "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has separate infoRootResponse function"
else
    echo "✗ Response.hs missing separate infoRootResponse - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should call Plan functions for txMode
echo "Checking src/PostgREST/App.hs uses Plan.readPlanTxMode..."
if grep -q "Plan.readPlanTxMode" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses Plan.readPlanTxMode"
else
    echo "✗ App.hs does not use Plan.readPlanTxMode - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should call Plan.mrTxMode
echo "Checking src/PostgREST/App.hs uses Plan.mrTxMode..."
if grep -q "Plan.mrTxMode" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses Plan.mrTxMode"
else
    echo "✗ App.hs does not use Plan.mrTxMode - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - transaction mode properly moved to Plan types"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
