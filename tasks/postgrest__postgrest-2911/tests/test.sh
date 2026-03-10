#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying full response control when raising exceptions fix..."
echo ""

# Check that CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for exception response control fix entry..."
if grep -q '#2492, Allow full response control when raising exceptions' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has exception response control fix entry"
else
    echo "✗ CHANGELOG.md missing exception response control fix entry - fix not applied"
    test_status=1
fi

# Check that Error.hs has the required imports
echo "Checking Error.hs for Data.CaseInsensitive import..."
if grep -q 'import qualified Data.CaseInsensitive' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has Data.CaseInsensitive import"
else
    echo "✗ Error.hs missing Data.CaseInsensitive import - fix not applied"
    test_status=1
fi

echo "Checking Error.hs for Data.Map.Internal import..."
if grep -q 'import qualified Data.Map.Internal' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has Data.Map.Internal import"
else
    echo "✗ Error.hs missing Data.Map.Internal import - fix not applied"
    test_status=1
fi

# Check that Error.hs has the custom headers logic
echo "Checking Error.hs for custom headers logic..."
if grep -q 'headers (PgError _ (SQL.SessionUsageError (SQL.QueryError _ _ (SQL.ResultError (SQL.ServerError "PGRST"' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has custom headers logic"
else
    echo "✗ Error.hs missing custom headers logic - fix not applied"
    test_status=1
fi

# Check for the intoHeader helper function
echo "Checking Error.hs for intoHeader helper function..."
if grep -q 'intoHeader (k,v) = (CI.mk' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has intoHeader helper function"
else
    echo "✗ Error.hs missing intoHeader helper function - fix not applied"
    test_status=1
fi

# Check that Aeson imports include (.:) and (.:?)
echo "Checking Error.hs for required Aeson operators..."
if grep -q 'import Data.Aeson.*((.:), (.:?), (.=))' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has required Aeson operators"
else
    echo "✗ Error.hs missing required Aeson operators - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
