#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #3896 which logs 503 client errors to stderr
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the 503 error logging fix..."
if grep -q "Log \`503\` client error to stderr" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions 503 error logging fix - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs logs client errors with QueryErrorCodeHighObs..."
if grep -q 'err@(SQL.SessionUsageError (SQL.QueryError _ _ (SQL.ClientError _)))' "src/PostgREST/AppState.hs" && \
   grep -A2 'err@(SQL.SessionUsageError (SQL.QueryError _ _ (SQL.ClientError _)))' "src/PostgREST/AppState.hs" | grep -q 'observer.*QueryErrorCodeHighObs'; then
    echo "✓ AppState.hs logs client errors with QueryErrorCodeHighObs - fix applied!"
else
    echo "✗ AppState.hs does not log client errors properly - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that AppState.hs includes the comment about client-side errors..."
if grep -q "An error on the client-side, usually indicates problems wth connection" "src/PostgREST/AppState.hs"; then
    echo "✓ AppState.hs includes client error comment - fix applied!"
else
    echo "✗ AppState.hs missing client error comment - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py includes the new test..."
if grep -q "def test_pgrst_log_503_client_error_to_stderr" "test/io/test_io.py"; then
    echo "✓ test_io.py includes test_pgrst_log_503_client_error_to_stderr - fix applied!"
else
    echo "✗ test_io.py missing the new test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
