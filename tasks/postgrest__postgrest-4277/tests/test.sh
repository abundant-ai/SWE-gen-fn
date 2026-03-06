#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SpreadQueriesSpec.hs" "test/spec/Feature/Query/SpreadQueriesSpec.hs"

# Verify the fix by checking Haskell source code changes
# In BASE (bug.patch applied): Spread embeds use Maybe, metrics endpoint missing Content-Type
# In HEAD (fix applied): Spread embeds use list, metrics endpoint has Content-Type header

test_status=0

echo "Verifying source code changes for spread queries and metrics endpoint fixes..."
echo ""

echo "Checking src/PostgREST/Query/QueryBuilder.hs for spread embed fixes..."
if grep -q "relSelectToSnippet :: RelSelectField -> \[SQL.Snippet\]" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs has relSelectToSnippet returning [SQL.Snippet] - fix is applied!"
else
    echo "✗ QueryBuilder.hs does not have relSelectToSnippet returning [SQL.Snippet] - fix not applied"
    test_status=1
fi

if grep -q "join \$ map relSelectToSnippet relSelect" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses join with map for spread embeds - fix is applied!"
else
    echo "✗ QueryBuilder.hs does not use join with map for spread embeds - fix not applied"
    test_status=1
fi

echo ""
echo "Checking src/PostgREST/Admin.hs for metrics Content-Type header fix..."
if grep -q "toContentType MTTextPlain" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs metrics endpoint includes Content-Type header - fix is applied!"
else
    echo "✗ Admin.hs metrics endpoint missing Content-Type header - fix not applied"
    test_status=1
fi

if grep -q "import PostgREST.MediaType.*toContentType" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs imports MediaType module - fix is applied!"
else
    echo "✗ Admin.hs does not import MediaType module - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
