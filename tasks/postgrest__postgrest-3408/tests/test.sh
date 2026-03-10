#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that App.hs run function doesn't take observer parameter
echo "Checking that App.hs run function signature is fixed..."
if grep -q "^run :: AppState -> IO ()" "src/PostgREST/App.hs"; then
    echo "✓ App.hs run function signature fixed (no observer parameter)"
else
    echo "✗ App.hs run function still has observer parameter - fix not applied"
    test_status=1
fi

# Check that App.hs has configObserver in run function
echo "Checking that App.hs retrieves configObserver from AppConfig..."
if grep -q "conf@AppConfig{configObserver=observer" "src/PostgREST/App.hs"; then
    echo "✓ App.hs retrieves configObserver from AppConfig - fix applied!"
else
    echo "✗ App.hs doesn't retrieve configObserver from AppConfig - fix not applied"
    test_status=1
fi

# Check that Admin.hs runAdmin function doesn't take observer parameter
echo "Checking that Admin.hs runAdmin function signature is fixed..."
if grep -q "^runAdmin :: AppConfig -> AppState -> Warp.Settings -> IO ()" "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs runAdmin function signature fixed (no observer parameter)"
else
    echo "✗ Admin.hs runAdmin still has observer parameter - fix not applied"
    test_status=1
fi

# Check that postgrest function doesn't take observer parameter
echo "Checking that App.hs postgrest function signature is fixed..."
if grep -q "^postgrest :: LogLevel -> AppState.AppState -> IO () -> Wai.Application" "src/PostgREST/App.hs"; then
    echo "✓ App.hs postgrest function signature fixed (no observer parameter)"
else
    echo "✗ App.hs postgrest still has observer parameter - fix not applied"
    test_status=1
fi

# Check that postgrestResponse function doesn't take observer parameter
echo "Checking that App.hs postgrestResponse function signature is fixed..."
# Check if the observer parameter line exists in the function signature
if grep -A 10 "^postgrestResponse" "src/PostgREST/App.hs" | grep -q "  -> (Observation -> IO ())"; then
    echo "✗ App.hs postgrestResponse still has observer parameter - fix not applied"
    test_status=1
else
    echo "✓ App.hs postgrestResponse function signature fixed (no observer parameter)"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
