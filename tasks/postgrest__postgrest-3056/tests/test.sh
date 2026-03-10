#!/bin/bash

cd /app/src

export CI=true

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check CHANGELOG for the feature mention
echo "Checking CHANGELOG for #3001 entry..."
if grep -q '#3001.*Add.*statement_timeout.*set on functions' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions #3001 feature"
else
    echo "✗ CHANGELOG missing #3001 entry - fix not applied"
    test_status=1
fi

# Check App.hs for timeout parameter in runQuery calls
echo "Checking App.hs for timeout parameter in ActionInvoke..."
if grep -q 'runQuery (fromMaybe roleIsoLvl \$ pdIsoLvl (Plan.crProc cPlan)) (pdTimeout \$ Plan.crProc cPlan)' "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes pdTimeout for RPC calls"
else
    echo "✗ App.hs missing pdTimeout parameter - fix not applied"
    test_status=1
fi

# Check App.hs runQuery signature includes timeout
echo "Checking App.hs runQuery signature..."
if grep -q 'runQuery isoLvl timeout mode query' "src/PostgREST/App.hs"; then
    echo "✓ App.hs runQuery has timeout parameter"
else
    echo "✗ App.hs runQuery missing timeout parameter - fix not applied"
    test_status=1
fi

# Check Query.hs setPgLocals signature includes timeout
echo "Checking Query.hs setPgLocals signature..."
if grep -q 'ApiRequest -> Maybe Text -> DbHandler ()' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs setPgLocals has Maybe Text parameter"
else
    echo "✗ Query.hs setPgLocals missing timeout parameter - fix not applied"
    test_status=1
fi

# Check Query.hs has timeoutSql
echo "Checking Query.hs for timeoutSql..."
if grep -q 'timeoutSql = maybe mempty' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has timeoutSql"
else
    echo "✗ Query.hs missing timeoutSql - fix not applied"
    test_status=1
fi

# Check Query.hs includes timeoutSql in statement
echo "Checking Query.hs includes timeoutSql in SQL statement..."
if grep -q 'timezoneSql ++ timeoutSql ++ appSettingsSql' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs includes timeoutSql in SQL statement"
else
    echo "✗ Query.hs not including timeoutSql - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs decodeFuncs includes timeout column (should have 2 nullableColumn lines in decodeFuncs)
echo "Checking SchemaCache.hs decodeFuncs for timeout column..."
if [ "$(grep -c '<\*> nullableColumn' "src/PostgREST/SchemaCache.hs")" -ge 2 ]; then
    echo "✓ SchemaCache.hs decodeFuncs includes timeout column"
else
    echo "✗ SchemaCache.hs decodeFuncs missing timeout column - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs SQL query includes statement_timeout
echo "Checking SchemaCache.hs funcsSqlQuery for statement_timeout..."
if grep -q 'statement_timeout' "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs query includes statement_timeout"
else
    echo "✗ SchemaCache.hs query missing statement_timeout - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs has timeout_config unnest
echo "Checking SchemaCache.hs for timeout_config unnest..."
if grep -q "unnest(proconfig) timeout_config ON timeout_config like 'statement_timeout%'" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has timeout_config unnest"
else
    echo "✗ SchemaCache.hs missing timeout_config unnest - fix not applied"
    test_status=1
fi

# Check Routine.hs data type includes pdTimeout
echo "Checking Routine.hs data type for pdTimeout..."
if grep -q ', pdTimeout     :: Maybe Text' "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs data type has pdTimeout field"
else
    echo "✗ Routine.hs data type missing pdTimeout - fix not applied"
    test_status=1
fi

# Check Routine.hs toJSON includes pdTimeout
echo "Checking Routine.hs toJSON for pdTimeout..."
if grep -q '"pdTimeout"     .= tout' "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs toJSON includes pdTimeout"
else
    echo "✗ Routine.hs toJSON missing pdTimeout - fix not applied"
    test_status=1
fi

# Check Routine.hs Ord instance includes tout
echo "Checking Routine.hs Ord instance for tout..."
if grep -q 'tout1.*compare.*tout2' "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs Ord instance includes tout"
else
    echo "✗ Routine.hs Ord instance missing tout - fix not applied"
    test_status=1
fi

# Check fixtures.sql has test functions (check the HEAD version in /tests)
echo "Checking fixtures.sql for one_sec_timeout function..."
if grep -q "create or replace function one_sec_timeout() returns void" "/tests/io/fixtures.sql"; then
    echo "✓ fixtures.sql has one_sec_timeout function"
else
    echo "✗ fixtures.sql missing one_sec_timeout function - fix not applied"
    test_status=1
fi

echo "Checking fixtures.sql for four_sec_timeout function..."
if grep -q "create or replace function four_sec_timeout() returns void" "/tests/io/fixtures.sql"; then
    echo "✓ fixtures.sql has four_sec_timeout function"
else
    echo "✗ fixtures.sql missing four_sec_timeout function - fix not applied"
    test_status=1
fi

# Check test_io.py has test functions (check the HEAD version in /tests)
echo "Checking test_io.py for test_fail_with_3_sec_statement_and_1_sec_statement_timeout..."
if grep -q 'def test_fail_with_3_sec_statement_and_1_sec_statement_timeout' "/tests/io/test_io.py"; then
    echo "✓ test_io.py has test_fail_with_3_sec_statement_and_1_sec_statement_timeout"
else
    echo "✗ test_io.py missing test_fail_with_3_sec_statement_and_1_sec_statement_timeout - fix not applied"
    test_status=1
fi

echo "Checking test_io.py for test_passes_with_3_sec_statement_and_4_sec_statement_timeout..."
if grep -q 'def test_passes_with_3_sec_statement_and_4_sec_statement_timeout' "/tests/io/test_io.py"; then
    echo "✓ test_io.py has test_passes_with_3_sec_statement_and_4_sec_statement_timeout"
else
    echo "✗ test_io.py missing test_passes_with_3_sec_statement_and_4_sec_statement_timeout - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
