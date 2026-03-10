#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md includes the entry for the fix
echo "Checking that CHANGELOG.md includes the fix entry..."
if grep -q "#3061, Apply all function settings as transaction-scoped settings" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md includes the fix entry"
else
    echo "✗ CHANGELOG.md missing the fix entry - fix not applied"
    test_status=1
fi

# Check that App.hs uses pdFuncSettings for function invocation
echo "Checking that App.hs uses pdFuncSettings for RPC calls..."
if grep -q "runQuery (fromMaybe roleIsoLvl \$ pdIsoLvl (Plan.crProc cPlan)) (pdFuncSettings \$ Plan.crProc cPlan)" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses pdFuncSettings for function settings"
else
    echo "✗ App.hs not using pdFuncSettings - fix not applied"
    test_status=1
fi

# Check that Query.hs setPgLocals accepts funcSettings parameter
echo "Checking that Query.hs setPgLocals has funcSettings parameter..."
if grep -q "setPgLocals AppConfig{..} claims role roleSettings funcSettings ApiRequest{..} = lift" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs setPgLocals has funcSettings parameter"
else
    echo "✗ Query.hs setPgLocals missing funcSettings parameter - fix not applied"
    test_status=1
fi

# Check that Query.hs applies function settings
echo "Checking that Query.hs applies function settings..."
if grep -q "funcSettingsSql" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs applies function settings"
else
    echo "✗ Query.hs not applying function settings - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs has FuncSettings type
echo "Checking that SchemaCache/Routine.hs defines FuncSettings type..."
if grep -q "type FuncSettings = \[(Text,Text)\]" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs defines FuncSettings type"
else
    echo "✗ Routine.hs missing FuncSettings type - fix not applied"
    test_status=1
fi

# Check that Routine has pdFuncSettings field
echo "Checking that Routine has pdFuncSettings field..."
if grep -q "pdFuncSettings :: FuncSettings" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine has pdFuncSettings field"
else
    echo "✗ Routine missing pdFuncSettings field - fix not applied"
    test_status=1
fi

# Check that SchemaCache.hs queries for function settings
echo "Checking that SchemaCache.hs queries for function settings from PostgreSQL..."
if grep -q "func_settings.kvs" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs queries for function settings"
else
    echo "✗ SchemaCache.hs not querying function settings - fix not applied"
    test_status=1
fi

# Check that the SQL query includes the func_settings lateral join
echo "Checking that SQL query includes func_settings lateral join..."
if grep -q ") func_settings ON TRUE" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SQL query includes func_settings lateral join"
else
    echo "✗ SQL query missing func_settings lateral join - fix not applied"
    test_status=1
fi

# Check that test files include tests for function settings
echo "Checking that test_io.py includes tests for function settings..."
if grep -q "test_function_settings\|test_read_guc\|get_guc_value" "test/io/test_io.py"; then
    echo "✓ test_io.py includes tests for function settings"
else
    echo "✗ test_io.py missing function settings tests - fix not applied"
    test_status=1
fi

# Check that fixtures.sql includes function with custom settings
echo "Checking that fixtures.sql includes function with custom settings..."
if grep -q "plan_filter\|SET.*TO\|get_guc_value" "test/io/fixtures.sql"; then
    echo "✓ fixtures.sql includes function with custom settings"
else
    echo "✗ fixtures.sql missing function with custom settings - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
