#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for connection recovery and fatal error handling (#2813)..."
echo ""

# Check CHANGELOG.md has the fix entries
echo "Checking CHANGELOG.md has fix entries..."
if grep -q "#2781, Start automatic connection recovery when pool connections are closed with pg_terminate_backend" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has #2781 entry"
else
    echo "✗ CHANGELOG.md missing #2781 entry - fix not applied"
    test_status=1
fi

if grep -q '#2801, Stop retrying connection when "no password supplied"' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has #2801 entry"
else
    echo "✗ CHANGELOG.md missing #2801 entry - fix not applied"
    test_status=1
fi

# Check that LambdaCase language extension was removed from App.hs (no longer needed)
echo "Checking src/PostgREST/App.hs removed LambdaCase extension..."
if grep -q "{-# LANGUAGE LambdaCase" "src/PostgREST/App.hs"; then
    echo "✗ src/PostgREST/App.hs still has LambdaCase - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/App.hs removed LambdaCase extension"
fi

# Check that whenLeft import was removed from App.hs (moved to AppState.hs)
echo "Checking src/PostgREST/App.hs imports..."
if grep -q "import Data.Either.Combinators.*whenLeft" "src/PostgREST/App.hs"; then
    echo "✗ src/PostgREST/App.hs still imports whenLeft - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/App.hs removed whenLeft from imports"
fi

# Check that Hasql.Pool import was removed from App.hs
echo "Checking src/PostgREST/App.hs removed Hasql.Pool import..."
if grep -q "import qualified Hasql.Pool" "src/PostgREST/App.hs"; then
    echo "✗ src/PostgREST/App.hs still imports Hasql.Pool - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/App.hs removed Hasql.Pool import"
fi

# Check runDbHandler signature changed to use SQL.IsolationLevel
echo "Checking src/PostgREST/App.hs runDbHandler signature..."
if grep -q "runDbHandler :: AppState.AppState -> SQL.IsolationLevel -> SQL.Mode" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs has runDbHandler with SQL.IsolationLevel"
else
    echo "✗ src/PostgREST/App.hs missing updated runDbHandler signature - fix not applied"
    test_status=1
fi

# Check that AppState.hs has checkIsFatal function
echo "Checking src/PostgREST/AppState.hs has checkIsFatal function..."
if grep -q "checkIsFatal :: SQL.UsageError -> Maybe Text" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs has checkIsFatal function"
else
    echo "✗ src/PostgREST/AppState.hs missing checkIsFatal function - fix not applied"
    test_status=1
fi

# Check that checkIsFatal checks for "no password supplied"
echo "Checking src/PostgREST/AppState.hs checkIsFatal handles no password supplied..."
if grep -q '"no password supplied"' "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs checks for 'no password supplied'"
else
    echo "✗ src/PostgREST/AppState.hs missing 'no password supplied' check - fix not applied"
    test_status=1
fi

# Check that AppState.hs imports Data.Either.Combinators with whenLeft
echo "Checking src/PostgREST/AppState.hs imports whenLeft..."
if grep -q "import.*Data.Either.Combinators.*whenLeft" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs imports whenLeft"
else
    echo "✗ src/PostgREST/AppState.hs missing whenLeft import - fix not applied"
    test_status=1
fi

# Check that AppState.hs imports Data.ByteString.Char8
echo "Checking src/PostgREST/AppState.hs imports Data.ByteString.Char8..."
if grep -q "import qualified Data.ByteString.Char8" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs imports Data.ByteString.Char8"
else
    echo "✗ src/PostgREST/AppState.hs missing Data.ByteString.Char8 import - fix not applied"
    test_status=1
fi

# Check that usePool now handles AcquisitionTimeoutUsageError
echo "Checking src/PostgREST/AppState.hs usePool handles acquisition timeout..."
if grep -A 5 "usePool :: AppState -> SQL.Session" "src/PostgREST/AppState.hs" | grep -q "AcquisitionTimeoutUsageError"; then
    echo "✓ src/PostgREST/AppState.hs usePool handles AcquisitionTimeoutUsageError"
else
    echo "✗ src/PostgREST/AppState.hs usePool missing acquisition timeout handling - fix not applied"
    test_status=1
fi

# Check that Config.hs has RoleIsolationLvl
echo "Checking src/PostgREST/Config.hs has RoleIsolationLvl..."
if grep -q "RoleIsolationLvl" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has RoleIsolationLvl"
else
    echo "✗ src/PostgREST/Config.hs missing RoleIsolationLvl - fix not applied"
    test_status=1
fi

# Check that Config.hs AppConfig has configRoleIsoLvl field
echo "Checking src/PostgREST/Config.hs AppConfig has configRoleIsoLvl..."
if grep -q "configRoleIsoLvl" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configRoleIsoLvl field"
else
    echo "✗ src/PostgREST/Config.hs missing configRoleIsoLvl - fix not applied"
    test_status=1
fi

# Check that readAppConfig signature updated with RoleIsolationLvl parameter
echo "Checking src/PostgREST/Config.hs readAppConfig signature..."
if grep -q "readAppConfig :: .* -> RoleSettings -> RoleIsolationLvl -> IO" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs readAppConfig has RoleIsolationLvl parameter"
else
    echo "✗ src/PostgREST/Config.hs readAppConfig missing RoleIsolationLvl parameter - fix not applied"
    test_status=1
fi

# Check that Config/Database.hs exports RoleIsolationLvl and toIsolationLevel
echo "Checking src/PostgREST/Config/Database.hs exports..."
if grep -q "RoleIsolationLvl" "src/PostgREST/Config/Database.hs" && grep -q "toIsolationLevel" "src/PostgREST/Config/Database.hs"; then
    echo "✓ src/PostgREST/Config/Database.hs exports RoleIsolationLvl and toIsolationLevel"
else
    echo "✗ src/PostgREST/Config/Database.hs missing exports - fix not applied"
    test_status=1
fi

# Check that CLI.hs readAppConfig call updated with mempty for roleIsolationLvl
echo "Checking src/PostgREST/CLI.hs readAppConfig call..."
if grep -q "readAppConfig mempty cliPath Nothing mempty mempty" "src/PostgREST/CLI.hs"; then
    echo "✓ src/PostgREST/CLI.hs updated readAppConfig call"
else
    echo "✗ src/PostgREST/CLI.hs readAppConfig call not updated - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs was updated (the test file from /tests)
echo "Checking test/spec/SpecHelper.hs is present..."
if [ -f "test/spec/SpecHelper.hs" ]; then
    echo "✓ test/spec/SpecHelper.hs is present"
else
    echo "✗ test/spec/SpecHelper.hs missing"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
