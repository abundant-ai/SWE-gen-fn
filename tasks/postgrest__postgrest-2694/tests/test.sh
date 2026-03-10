#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/OpenApi"
cp "/tests/spec/Feature/OpenApi/RootSpec.hs" "test/spec/Feature/OpenApi/RootSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for db-root-spec stability..."
echo ""
echo "NOTE: This PR REMOVES unstable db-root-spec implementation to make it stable."
echo "HEAD should have CHANGELOG entry but NO jsonDbS code."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2694 entry (bug.patch removes it)
echo "Checking CHANGELOG.md has PR #2694 entry..."
if grep -q "#2694, Make \`db-root-spec\` stable" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2694 entry"
else
    echo "✗ CHANGELOG.md missing PR #2694 entry - fix not applied"
    test_status=1
fi

# Check AppState.hs - HEAD should NOT have stateJsonDbS (bug.patch adds them back)
echo "Checking src/PostgREST/AppState.hs should NOT have stateJsonDbS..."
if ! grep -q "stateJsonDbS" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs does not have stateJsonDbS field (correctly removed)"
else
    echo "✗ src/PostgREST/AppState.hs still has stateJsonDbS - fix not applied"
    test_status=1
fi

if ! grep -q "getJsonDbS" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs does not have getJsonDbS function (correctly removed)"
else
    echo "✗ src/PostgREST/AppState.hs still has getJsonDbS - fix not applied"
    test_status=1
fi

if ! grep -q "putJsonDbS" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs does not have putJsonDbS function (correctly removed)"
else
    echo "✗ src/PostgREST/AppState.hs still has putJsonDbS - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should NOT pass jsonDbS parameter (bug.patch adds it back)
echo "Checking src/PostgREST/App.hs should NOT have jsonDbS parameter..."
if ! grep -q "jsonDbS <- AppState.getJsonDbS appState" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs does not retrieve jsonDbS (correctly removed)"
else
    echo "✗ src/PostgREST/App.hs still retrieves jsonDbS - fix not applied"
    test_status=1
fi

if ! grep -q "postgrestResponse appState appConf maybeSchemaCache jsonDbS pgVer authResult req" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs does not pass jsonDbS (correctly removed)"
else
    echo "✗ src/PostgREST/App.hs still passes jsonDbS - fix not applied"
    test_status=1
fi

# Check Query.hs - HEAD should NOT have jsonDbS parameter and specSql (bug.patch adds them back)
echo "Checking src/PostgREST/Query.hs should NOT have jsonDbS and specSql..."
if ! grep -q "setPgLocals conf claims role req jsonDbS actualPgVersion" "src/PostgREST/Query.hs"; then
    echo "✓ src/PostgREST/Query.hs setPgLocals does not have jsonDbS parameter (correctly removed)"
else
    echo "✗ src/PostgREST/Query.hs setPgLocals still has jsonDbS - fix not applied"
    test_status=1
fi

if ! grep -q 'specSql = case iTarget req of' "src/PostgREST/Query.hs"; then
    echo "✓ src/PostgREST/Query.hs does not have specSql logic (correctly removed)"
else
    echo "✗ src/PostgREST/Query.hs still has specSql - fix not applied"
    test_status=1
fi

if ! grep -q 'TargetProc{tpIsRootSpec=True} -> \[setConfigLocal mempty ("request.spec", jsonDbS)\]' "src/PostgREST/Query.hs"; then
    echo "✓ src/PostgREST/Query.hs does not set request.spec (correctly removed)"
else
    echo "✗ src/PostgREST/Query.hs still sets request.spec - fix not applied"
    test_status=1
fi

# Check Workers.hs - HEAD should NOT encode and store schema cache as JSON (bug.patch adds this back)
echo "Checking src/PostgREST/Workers.hs should NOT have JSON encoding..."
if ! (grep -q "Data.Aeson.*as JSON" "src/PostgREST/Workers.hs" && grep -q "Data.ByteString.Lazy.*as LBS" "src/PostgREST/Workers.hs"); then
    echo "✓ src/PostgREST/Workers.hs does not import JSON/LBS modules for schema encoding (correctly removed)"
else
    echo "✗ src/PostgREST/Workers.hs still has JSON/LBS imports - fix not applied"
    test_status=1
fi

if ! grep -q "AppState.putJsonDbS appState . LBS.toStrict.*JSON.encode sCache" "src/PostgREST/Workers.hs"; then
    echo "✓ src/PostgREST/Workers.hs does not store JSON-encoded schema cache (correctly removed)"
else
    echo "✗ src/PostgREST/Workers.hs still stores JSON schema - fix not applied"
    test_status=1
fi

# Check RootSpec.hs - HEAD should NOT have "accepts application/json" test (bug.patch adds it back)
echo "Checking test/spec/Feature/OpenApi/RootSpec.hs..."
if ! grep -q "accepts application/json" "test/spec/Feature/OpenApi/RootSpec.hs"; then
    echo "✓ test/spec/Feature/OpenApi/RootSpec.hs does not have 'accepts application/json' test (correctly removed)"
else
    echo "✗ test/spec/Feature/OpenApi/RootSpec.hs still has application/json test - fix not applied"
    test_status=1
fi

# Check Main.hs - HEAD should NOT initialize jsonDbS (bug.patch adds this back)
echo "Checking test/spec/Main.hs should NOT initialize jsonDbS..."
if ! grep -q "AppState.putJsonDbS appState" "test/spec/Main.hs"; then
    echo "✓ test/spec/Main.hs does not initialize jsonDbS (correctly removed)"
else
    echo "✗ test/spec/Main.hs still initializes jsonDbS - fix not applied"
    test_status=1
fi

if ! (grep -q "Data.Aeson.*as JSON" "test/spec/Main.hs" && grep -q "JSON.encode.*SchemaCache" "test/spec/Main.hs"); then
    echo "✓ test/spec/Main.hs does not use JSON encoding for schema (correctly removed)"
else
    echo "✗ test/spec/Main.hs still uses JSON encoding - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should NOT have updated root_spec function (bug.patch adds accept parameter and logic back)
echo "Checking test/spec/fixtures/schema.sql should NOT have root_spec changes..."
if ! grep -q "accept text;" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql does not have accept variable (correctly removed)"
else
    echo "✗ test/spec/fixtures/schema.sql still has accept variable - fix not applied"
    test_status=1
fi

if ! grep -q "current_setting('request.spec', true)" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql does not read request.spec setting (correctly removed)"
else
    echo "✗ test/spec/fixtures/schema.sql still reads request.spec - fix not applied"
    test_status=1
fi

if ! grep -q "when 'application/json' then" "test/spec/fixtures/schema.sql"; then
    echo "✓ test/spec/fixtures/schema.sql does not handle application/json accept header (correctly removed)"
else
    echo "✗ test/spec/fixtures/schema.sql still handles application/json - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
