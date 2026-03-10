#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for transaction isolation level feature (#2755)..."
echo ""

# Check CHANGELOG.md has the feature entry
echo "Checking CHANGELOG.md has transaction isolation level feature entry..."
if grep -q "#2468" "CHANGELOG.md" && grep -q "default_transaction_isolation" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has transaction isolation level feature entry"
else
    echo "✗ CHANGELOG.md missing transaction isolation level feature entry - fix not applied"
    test_status=1
fi

# Check App.hs has the toIsolationLevel function
echo "Checking src/PostgREST/App.hs has toIsolationLevel function..."
if grep -q "toIsolationLevel" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has toIsolationLevel function"
else
    echo "✗ src/PostgREST/App.hs missing toIsolationLevel function - fix not applied"
    test_status=1
fi

# Check App.hs runDbHandler takes isoLvl parameter
echo "Checking src/PostgREST/App.hs runDbHandler signature has isoLvl parameter..."
if grep -q "runDbHandler :: AppState.AppState -> Maybe Text -> SQL.Mode" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs runDbHandler has isoLvl parameter"
else
    echo "✗ src/PostgREST/App.hs runDbHandler missing isoLvl parameter - fix not applied"
    test_status=1
fi

# Check App.hs uses toIsolationLevel with isoLvl
echo "Checking src/PostgREST/App.hs uses toIsolationLevel with isoLvl..."
if grep -q "transaction (toIsolationLevel isoLvl) mode" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs uses toIsolationLevel with isoLvl"
else
    echo "✗ src/PostgREST/App.hs not using toIsolationLevel with isoLvl - fix not applied"
    test_status=1
fi

# Check App.hs has roleIsoLvl variable
echo "Checking src/PostgREST/App.hs has roleIsoLvl..."
if grep -q "roleIsoLvl" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has roleIsoLvl"
else
    echo "✗ src/PostgREST/App.hs missing roleIsoLvl - fix not applied"
    test_status=1
fi

# Check App.hs runQuery uses roleIsoLvl
echo "Checking src/PostgREST/App.hs runQuery passes roleIsoLvl..."
if grep -q "runQuery roleIsoLvl" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs runQuery passes roleIsoLvl"
else
    echo "✗ src/PostgREST/App.hs runQuery not passing roleIsoLvl - fix not applied"
    test_status=1
fi

# Check App.hs imports Data.HashMap.Strict
echo "Checking src/PostgREST/App.hs imports Data.HashMap.Strict..."
if grep -q "import qualified Data.HashMap.Strict" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs imports Data.HashMap.Strict"
else
    echo "✗ src/PostgREST/App.hs missing Data.HashMap.Strict import - fix not applied"
    test_status=1
fi

# Check SchemaCache.Routine is imported in App.hs
echo "Checking src/PostgREST/App.hs imports SchemaCache.Routine..."
if grep -q "PostgREST.SchemaCache.Routine" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs imports SchemaCache.Routine"
else
    echo "✗ src/PostgREST/App.hs missing SchemaCache.Routine import - fix not applied"
    test_status=1
fi

# Check Config/Database.hs has updated RoleSettings type
echo "Checking src/PostgREST/Config/Database.hs has nested HashMap RoleSettings..."
if grep -q "type RoleSettings = (HM.HashMap ByteString (HM.HashMap ByteString ByteString))" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs has updated RoleSettings type"
else
    echo "✗ src/PostgREST/Config/Database.hs missing updated RoleSettings type - fix not applied"
    test_status=1
fi

# Check SchemaCache/Routine.hs has pdIsoLvl field
echo "Checking src/PostgREST/SchemaCache/Routine.hs has pdIsoLvl field..."
if grep -q "pdIsoLvl" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs has pdIsoLvl field"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs missing pdIsoLvl field - fix not applied"
    test_status=1
fi

# Check test fixtures have isolation level test setup
echo "Checking test/io/fixtures.sql has isolation level roles..."
if grep -q "postgrest_test_serializable" "test/io/fixtures.sql" && \
   grep -q "default_transaction_isolation = 'serializable'" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has isolation level test roles"
else
    echo "✗ test/io/fixtures.sql missing isolation level test roles - fix not applied"
    test_status=1
fi

# Check test/io/fixtures.sql has isolation level test functions
echo "Checking test/io/fixtures.sql has isolation level test functions..."
if grep -q "serializable_isolation_level()" "test/io/fixtures.sql" && \
   grep -q "repeatable_read_isolation_level()" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has isolation level test functions"
else
    echo "✗ test/io/fixtures.sql missing isolation level test functions - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
