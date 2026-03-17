#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/InsertSpec.hs" "test/Feature/InsertSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/OpenApiSpec.hs" "test/Feature/OpenApiSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/OptionsSpec.hs" "test/Feature/OptionsSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/UpsertSpec.hs" "test/Feature/UpsertSpec.hs"
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/data.sql" "test/fixtures/data.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/privileges.sql" "test/fixtures/privileges.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #2022 which EXCLUDES partitions from schema cache via partition filtering
# HEAD state (c89cd3994c93c96d2677961ebcdad37aa0cf532b) = partition filtering present (partitions EXCLUDED)
# BASE state (with bug.patch) = partition filtering removed (partitions INCLUDED) - BUGGY
# ORACLE state (BASE + fix.patch) = partition filtering restored (partitions EXCLUDED) - FIXED

test_status=0

echo "Verifying source code matches HEAD state (partitions excluded from schema cache)..."
echo ""

echo "Checking that CHANGELOG mentions partitions are no longer in cache..."
if grep -q "#1783, Partitions (created using \`PARTITION OF\`) are no longer included in the schema cache" "CHANGELOG.md"; then
    echo "✓ CHANGELOG entry present - fix applied!"
else
    echo "✗ CHANGELOG entry missing - fix not applied"
    test_status=1
fi

echo "Checking that DbStructure.hs imports PgVersion..."
if grep -q "import.*PostgREST.Config.PgVersion.*PgVersion.*pgVersion100" "src/PostgREST/DbStructure.hs"; then
    echo "✓ PgVersion import present - fix applied!"
else
    echo "✗ PgVersion import missing - fix not applied"
    test_status=1
fi

echo "Checking that relIsNotPartition function exists in DbStructure.hs..."
if grep -q "relIsNotPartition :: PgVersion -> SqlQuery" "src/PostgREST/DbStructure.hs"; then
    echo "✓ relIsNotPartition function present - fix applied!"
else
    echo "✗ relIsNotPartition function missing - fix not applied"
    test_status=1
fi

echo "Checking that queryDbStructure signature has PgVersion parameter..."
if grep -q "queryDbStructure :: \[Schema\] -> \[Schema\] -> PgVersion -> Bool -> SQL.Transaction DbStructure" "src/PostgREST/DbStructure.hs"; then
    echo "✓ queryDbStructure signature has PgVersion - fix applied!"
else
    echo "✗ queryDbStructure signature missing PgVersion - fix not applied"
    test_status=1
fi

echo "Checking that allTables signature has PgVersion parameter..."
if grep -q "allTables :: PgVersion -> Bool -> SQL.Statement () \[Table\]" "src/PostgREST/DbStructure.hs"; then
    echo "✓ allTables signature has PgVersion - fix applied!"
else
    echo "✗ allTables signature missing PgVersion - fix not applied"
    test_status=1
fi

echo "Checking that accessibleTables signature has PgVersion parameter..."
if grep -q "accessibleTables :: PgVersion -> Bool -> SQL.Statement Schema \[Table\]" "src/PostgREST/DbStructure.hs"; then
    echo "✓ accessibleTables signature has PgVersion - fix applied!"
else
    echo "✗ accessibleTables signature missing PgVersion - fix not applied"
    test_status=1
fi

echo "Checking that DbStructure.hs uses relIsNotPartition in SQL queries..."
if grep -q "relIsNotPartition pgVer" "src/PostgREST/DbStructure.hs"; then
    echo "✓ Partition filtering present in SQL queries - fix applied!"
else
    echo "✗ Partition filtering missing from SQL queries - fix not applied"
    test_status=1
fi

echo "Checking that Workers.hs uses actualPgVersion in loadSchemaCache..."
if grep -A 5 "loadSchemaCache appState = do" "src/PostgREST/Workers.hs" | grep -q "actualPgVersion <- AppState.getPgVersion appState"; then
    echo "✓ Workers.hs uses actualPgVersion - fix applied!"
else
    echo "✗ Workers.hs doesn't use actualPgVersion - fix not applied"
    test_status=1
fi

echo "Checking that CLI.hs uses actualPgVersion in dumpSchema..."
if grep -A 5 "dumpSchema appState = do" "src/PostgREST/CLI.hs" | grep -q "actualPgVersion <- AppState.getPgVersion appState"; then
    echo "✓ CLI.hs uses actualPgVersion - fix applied!"
else
    echo "✗ CLI.hs doesn't use actualPgVersion - fix not applied"
    test_status=1
fi

echo "Checking that App.hs uses ctxPgVersion variable..."
if grep -q "handleOpenApi headersOnly tSchema (RequestContext conf@AppConfig{..} dbStructure apiRequest ctxPgVersion)" "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses ctxPgVersion variable - fix applied!"
else
    echo "✗ App.hs doesn't use ctxPgVersion - fix not applied"
    test_status=1
fi

echo "Checking that App.hs passes ctxPgVersion to accessibleTables..."
if grep -q "SQL.statement tSchema (DbStructure.accessibleTables ctxPgVersion configDbPreparedStatements)" "src/PostgREST/App.hs"; then
    echo "✓ App.hs passes ctxPgVersion to accessibleTables - fix applied!"
else
    echo "✗ App.hs doesn't pass ctxPgVersion to accessibleTables - fix not applied"
    test_status=1
fi

echo "Checking that test/Main.hs passes actualPgVersion to queryDbStructure..."
if grep -q "queryDbStructure (toList schemas) extraSearchPath actualPgVersion True" "test/Main.hs"; then
    echo "✓ test/Main.hs passes actualPgVersion - fix applied!"
else
    echo "✗ test/Main.hs doesn't pass actualPgVersion - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
