#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

test_status=0

echo "Verifying fix for error codes (PR #2648)..."
echo ""
echo "NOTE: This PR adds new error codes for specific error conditions"
echo "BASE (buggy) has incorrect error codes PGRST118 and PGRST000"
echo "HEAD (fixed) has correct error codes PGRST204 and PGRST003"
echo ""

# Check that Error.hs has the SchemaCacheErrorCode04 definition
echo "Checking src/PostgREST/Error.hs has SchemaCacheErrorCode04..."
if grep -q "| SchemaCacheErrorCode04" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has SchemaCacheErrorCode04 definition"
else
    echo "✗ Error.hs does not have SchemaCacheErrorCode04 - fix not applied"
    test_status=1
fi

# Check that Error.hs has the ConnectionErrorCode03 definition
echo "Checking src/PostgREST/Error.hs has ConnectionErrorCode03..."
if grep -q "| ConnectionErrorCode03" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has ConnectionErrorCode03 definition"
else
    echo "✗ Error.hs does not have ConnectionErrorCode03 - fix not applied"
    test_status=1
fi

# Check that ColumnNotFound uses SchemaCacheErrorCode04
echo "Checking ColumnNotFound uses SchemaCacheErrorCode04..."
if grep -A 3 "toJSON (ColumnNotFound relName colName)" "src/PostgREST/Error.hs" | grep -q "SchemaCacheErrorCode04"; then
    echo "✓ ColumnNotFound uses SchemaCacheErrorCode04"
else
    echo "✗ ColumnNotFound does not use SchemaCacheErrorCode04 - fix not applied"
    test_status=1
fi

# Check that AcquisitionTimeoutUsageError uses ConnectionErrorCode03
echo "Checking AcquisitionTimeoutUsageError uses ConnectionErrorCode03..."
if grep -A 1 "toJSON SQL.AcquisitionTimeoutUsageError" "src/PostgREST/Error.hs" | grep -q "ConnectionErrorCode03"; then
    echo "✓ AcquisitionTimeoutUsageError uses ConnectionErrorCode03"
else
    echo "✗ AcquisitionTimeoutUsageError does not use ConnectionErrorCode03 - fix not applied"
    test_status=1
fi

# Check that buildErrorCode has PGRST204 mapping
echo "Checking buildErrorCode has PGRST204 mapping..."
if grep -A 1 "SchemaCacheErrorCode04" "src/PostgREST/Error.hs" | grep -q '"204"'; then
    echo "✓ buildErrorCode maps SchemaCacheErrorCode04 to 204"
else
    echo "✗ buildErrorCode does not map SchemaCacheErrorCode04 to 204 - fix not applied"
    test_status=1
fi

# Check that buildErrorCode has PGRST003 mapping
echo "Checking buildErrorCode has PGRST003 mapping..."
if grep -A 1 "ConnectionErrorCode03" "src/PostgREST/Error.hs" | grep -q '"003"'; then
    echo "✓ buildErrorCode maps ConnectionErrorCode03 to 003"
else
    echo "✗ buildErrorCode does not map ConnectionErrorCode03 to 003 - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md mentions the fix
echo "Checking CHANGELOG.md mentions error code fix..."
if grep -q "#2648, Fix inaccurate error codes with new ones" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions error code fix"
else
    echo "✗ CHANGELOG.md does not mention error code fix - fix not fully applied"
    test_status=1
fi

# Verify the test files have the correct error codes
echo "Checking test/spec/Feature/Query/InsertSpec.hs has PGRST204..."
if grep -q 'PGRST204' "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ InsertSpec.hs has PGRST204 error code"
else
    echo "✗ InsertSpec.hs does not have PGRST204 error code - fix not applied"
    test_status=1
fi

echo "Checking test/spec/Feature/Query/UpdateSpec.hs has PGRST204..."
if grep -q 'PGRST204' "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ UpdateSpec.hs has PGRST204 error code"
else
    echo "✗ UpdateSpec.hs does not have PGRST204 error code - fix not applied"
    test_status=1
fi

echo ""

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
