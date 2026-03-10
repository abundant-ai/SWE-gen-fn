#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that PostgREST.Observation module is added to postgrest.cabal
echo "Checking that postgrest.cabal includes PostgREST.Observation..."
if grep -q "PostgREST.Observation" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PostgREST.Observation module"
else
    echo "✗ postgrest.cabal missing PostgREST.Observation module - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Observation.hs exists
echo "Checking that src/PostgREST/Observation.hs exists..."
if [ -f "src/PostgREST/Observation.hs" ]; then
    echo "✓ src/PostgREST/Observation.hs exists"
else
    echo "✗ src/PostgREST/Observation.hs missing - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Admin.hs imports PostgREST.Observation
echo "Checking that src/PostgREST/Admin.hs imports PostgREST.Observation..."
if grep -q "import PostgREST.Observation" "src/PostgREST/Admin.hs"; then
    echo "✓ src/PostgREST/Admin.hs imports PostgREST.Observation"
else
    echo "✗ src/PostgREST/Admin.hs missing PostgREST.Observation import - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/App.hs imports PostgREST.Observation
echo "Checking that src/PostgREST/App.hs imports PostgREST.Observation..."
if grep -q "import PostgREST.Observation" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs imports PostgREST.Observation"
else
    echo "✗ src/PostgREST/App.hs missing PostgREST.Observation import - fix not applied"
    test_status=1
fi

# Check that runAdmin function signature includes observer parameter
echo "Checking that runAdmin function signature includes observer parameter..."
if grep -q "runAdmin :: AppConfig -> AppState -> Warp.Settings -> (Observation -> IO ()) -> IO ()" "src/PostgREST/Admin.hs"; then
    echo "✓ runAdmin function signature includes observer parameter"
else
    echo "✗ runAdmin function signature missing observer parameter - fix not applied"
    test_status=1
fi

# Check that postgrest function signature includes observer parameter
echo "Checking that postgrest function signature includes observer parameter..."
if grep -q "postgrest :: AppConfig -> AppState.AppState -> IO () -> (Observation -> IO ()) -> Wai.Application" "src/PostgREST/App.hs"; then
    echo "✓ postgrest function signature includes observer parameter"
else
    echo "✗ postgrest function signature missing observer parameter - fix not applied"
    test_status=1
fi

# Check that AppState module no longer exports logWithZTime
echo "Checking that AppState module no longer exports logWithZTime..."
if grep -q "logWithZTime" "src/PostgREST/AppState.hs"; then
    echo "✗ AppState still exports logWithZTime - fix not applied properly"
    test_status=1
else
    echo "✓ AppState no longer exports logWithZTime"
fi

# Check that observer is used instead of logWithZTime in App.hs
echo "Checking that observer $ AppStartObs is used in App.hs..."
if grep -q "observer \$ AppStartObs" "src/PostgREST/App.hs"; then
    echo "✓ observer $ AppStartObs is used in App.hs"
else
    echo "✗ observer $ AppStartObs not found - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
