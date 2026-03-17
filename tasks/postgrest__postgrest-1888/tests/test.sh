#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #1888 which adds support for disabling prepared statements
# HEAD state (277ab063fe16582902ca7f21ee71ef7311f9096a) = fix for prepared statements - FIXED
# BASE state (with bug.patch) = no prepared statement control - BUGGY
# ORACLE state (BASE + fix.patch) = prepared statements can be disabled - FIXED

test_status=0

echo "Verifying source code matches HEAD state (fix for prepared statements support)..."
echo ""

echo "Checking that postgrest.cabal requires hasql-transaction >= 1.0.1..."
if grep -q 'hasql-transaction.*>= 1.0.1 && < 1.1' "postgrest.cabal"; then
    echo "✓ postgrest.cabal has hasql-transaction >= 1.0.1 - fix applied!"
else
    echo "✗ postgrest.cabal missing hasql-transaction >= 1.0.1 - fix not applied"
    test_status=1
fi

echo "Checking that App.hs runDbHandler accepts prepared parameter..."
if grep -q 'runDbHandler :: SQL.Pool -> SQL.Mode -> Auth.JWTClaims -> Bool -> DbHandler a -> Handler IO a' "src/PostgREST/App.hs"; then
    echo "✓ App.hs runDbHandler has prepared parameter - fix applied!"
else
    echo "✗ App.hs runDbHandler missing prepared parameter - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses conditional transaction based on prepared flag..."
if grep -q 'let transaction = if prepared then SQL.transaction else SQL.unpreparedTransaction in' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses conditional transaction - fix applied!"
else
    echo "✗ App.hs doesn't use conditional transaction - fix not applied"
    test_status=1
fi

echo "Checking that CLI.hs uses conditional transaction based on configDbPreparedStatements..."
if grep -q 'let transaction = if configDbPreparedStatements then HT.transaction else HT.unpreparedTransaction in' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs uses conditional transaction - fix applied!"
else
    echo "✗ CLI.hs doesn't use conditional transaction - fix not applied"
    test_status=1
fi

echo "Checking that Config/Database.hs queryDbSettings accepts prepared parameter..."
if grep -q 'queryDbSettings :: P.Pool -> Bool -> IO (Either P.UsageError \[(Text, Text)\])' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs queryDbSettings has prepared parameter - fix applied!"
else
    echo "✗ Config/Database.hs queryDbSettings missing prepared parameter - fix not applied"
    test_status=1
fi

echo "Checking that Error.hs has proper error handling for prepared statement errors..."
if grep -q 'checkIsFatal (PgError _ (P.SessionError (H.QueryError _ _ (H.ResultError serverError))))' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has proper prepared statement error handling - fix applied!"
else
    echo "✗ Error.hs missing proper error handling - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
