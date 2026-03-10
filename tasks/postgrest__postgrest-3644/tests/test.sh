#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/big_schema.sql" "test/io/big_schema.sql"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entries for PR #3644
echo "Checking that CHANGELOG.md has the fix entries for PR #3644..."
if grep -q "#3644, Make --dump-schema work with in-database pgrst.db_schemas setting" "CHANGELOG.md" && \
   grep -q "#3644, Show number of timezones in schema cache load report" "CHANGELOG.md" && \
   grep -q "#3644, List correct enum options in OpenApi output when multiple types with same name are present" "CHANGELOG.md" && \
   grep -q "#3644, Fail schema cache lookup with invalid db-schemas config" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #3644 fix entries - fix applied!"
else
    echo "✗ CHANGELOG.md missing PR #3644 fix entries - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CLI.hs has the fix (reReadConfig before dumpSchema)..."
if grep -q "CmdDumpSchema -> do" "src/PostgREST/CLI.hs" && \
   grep -A 1 "CmdDumpSchema -> do" "src/PostgREST/CLI.hs" | grep -q "when configDbConfig.*reReadConfig"; then
    echo "✓ CLI.hs has reReadConfig before dumpSchema - fix applied!"
else
    echo "✗ CLI.hs missing reReadConfig - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Query.hs has the fix (passing [tSchema] instead of tSchema)..."
if grep -q "SQL.statement (\[tSchema\], configDbHoistedTxSettings)" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs passes [tSchema] correctly - fix applied!"
else
    echo "✗ Query.hs doesn't pass [tSchema] - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SqlFragment.hs has the fix (escapeIdent returns Text)..."
if grep -q "escapeIdent :: Text -> Text" "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q 'pgFmtIdent x = SQL.sql . encodeUtf8 $ escapeIdent x' "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q 'escapeIdentList schemas = BS.intercalate ", " $ encodeUtf8 . escapeIdent <$> schemas' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has escapeIdent returning Text - fix applied!"
else
    echo "✗ SqlFragment.hs doesn't have correct escapeIdent signature - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs has the fix (timezone count in summary)..."
if grep -q "show (S.size tzs)" "src/PostgREST/SchemaCache.hs" && \
   grep -q "Timezones" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs shows timezone count - fix applied!"
else
    echo "✗ SchemaCache.hs missing timezone count - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs imports escapeIdent..."
if grep -q "import PostgREST.Query.SqlFragment.*escapeIdent" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs imports escapeIdent - fix applied!"
else
    echo "✗ SchemaCache.hs doesn't import escapeIdent - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs uses escapeIdent in allFunctions..."
if grep -q "map escapeIdent . toList . configDbSchemas" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses escapeIdent in allFunctions - fix applied!"
else
    echo "✗ SchemaCache.hs doesn't use escapeIdent in allFunctions - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs accessibleFuncs signature is updated..."
if grep -q "accessibleFuncs :: Bool -> SQL.Statement (\[Schema\], \[Text\]) RoutineMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs accessibleFuncs has correct signature - fix applied!"
else
    echo "✗ SchemaCache.hs accessibleFuncs signature not updated - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
