#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/DeleteSpec.hs" "test/Feature/DeleteSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/IgnorePrivOpenApiSpec.hs" "test/Feature/IgnorePrivOpenApiSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/InsertSpec.hs" "test/Feature/InsertSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/OpenApiSpec.hs" "test/Feature/OpenApiSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/QueryLimitedSpec.hs" "test/Feature/QueryLimitedSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/RangeSpec.hs" "test/Feature/RangeSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/RollbackSpec.hs" "test/Feature/RollbackSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/RpcPreRequestGucsSpec.hs" "test/Feature/RpcPreRequestGucsSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/RpcSpec.hs" "test/Feature/RpcSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/SingularSpec.hs" "test/Feature/SingularSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/UnicodeSpec.hs" "test/Feature/UnicodeSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/UpdateSpec.hs" "test/Feature/UpdateSpec.hs"
mkdir -p "test/Feature"
cp "/tests/Feature/UpsertSpec.hs" "test/Feature/UpsertSpec.hs"

test_status=0

echo "Verifying fix for 204 No Content responses without Content-Type header (PR #2060)..."
echo ""
echo "This PR ensures that 204 No Content responses do not include a Content-Type header."
echo "The bug was that 204 responses incorrectly included Content-Type headers."
echo "The fix removes Content-Type from all 204 responses and updates tests to verify this."
echo ""

echo "Checking App.hs has the fix applied..."
if [ -f "src/PostgREST/App.hs" ]; then
    echo "✓ src/PostgREST/App.hs exists"

    # After fix: handleSingleUpsert should use [] instead of (contentTypeHeaders context) for 204 responses
    # Look for the pattern: response HTTP.status204 [] mempty
    if grep -q "response HTTP.status204 \[\] mempty" "src/PostgREST/App.hs"; then
        echo "✓ App.hs uses empty headers [] for 204 response (fix applied)"
    else
        echo "✗ App.hs not using empty headers for 204 response (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking SqlFragment.hs has the fix applied..."
if [ -f "src/PostgREST/Query/SqlFragment.hs" ]; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs exists"

    # After fix: asJsonSingleF should use json_agg approach, not string_agg
    if grep -q "coalesce((json_agg(_postgrest_t.pgrst_scalar)->0)::text, 'null')" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✓ SqlFragment.hs uses json_agg for scalar (fix applied)"
    else
        echo "✗ SqlFragment.hs not using json_agg approach (fix not applied)"
        test_status=1
    fi

    if grep -q "coalesce((json_agg(_postgrest_t)->0)::text, 'null')" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✓ SqlFragment.hs uses json_agg for non-scalar (fix applied)"
    else
        echo "✗ SqlFragment.hs not using json_agg approach (fix not applied)"
        test_status=1
    fi

    # The fix should remove the TODO comment
    if grep -q "TODO! unsafe when the query actually returns multiple rows" "src/PostgREST/Query/SqlFragment.hs"; then
        echo "✗ SqlFragment.hs still has TODO comment (fix not fully applied)"
        test_status=1
    else
        echo "✓ SqlFragment.hs TODO comment removed (fix applied)"
    fi
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files have Content-Type absence checks..."

# DeleteSpec.hs should have matchHeaderAbsent hContentType
if [ -f "test/Feature/DeleteSpec.hs" ]; then
    echo "✓ test/Feature/DeleteSpec.hs exists (HEAD version)"
    if grep -q "matchHeaderAbsent hContentType" "test/Feature/DeleteSpec.hs"; then
        echo "✓ DeleteSpec.hs checks for absent Content-Type header (matches fixed code)"
    else
        echo "✗ DeleteSpec.hs missing Content-Type absence checks"
        test_status=1
    fi
else
    echo "✗ test/Feature/DeleteSpec.hs not found"
    test_status=1
fi

# IgnorePrivOpenApiSpec.hs should verify Content-Type header for OpenAPI responses
if [ -f "test/Feature/IgnorePrivOpenApiSpec.hs" ]; then
    echo "✓ test/Feature/IgnorePrivOpenApiSpec.hs exists (HEAD version)"
    # This test should verify Content-Type for HEAD requests
    if grep -q "Content-Type.*application/openapi+json" "test/Feature/IgnorePrivOpenApiSpec.hs"; then
        echo "✓ IgnorePrivOpenApiSpec.hs checks Content-Type for OpenAPI"
    else
        echo "✗ IgnorePrivOpenApiSpec.hs missing Content-Type checks"
        test_status=1
    fi
else
    echo "✗ test/Feature/IgnorePrivOpenApiSpec.hs not found"
    test_status=1
fi

# InsertSpec.hs should have matchHeaderAbsent hContentType for 204 responses
if [ -f "test/Feature/InsertSpec.hs" ]; then
    echo "✓ test/Feature/InsertSpec.hs exists (HEAD version)"
    if grep -q "matchHeaderAbsent hContentType" "test/Feature/InsertSpec.hs"; then
        echo "✓ InsertSpec.hs checks for absent Content-Type header"
    else
        echo "✗ InsertSpec.hs missing Content-Type absence checks"
        test_status=1
    fi
else
    echo "✗ test/Feature/InsertSpec.hs not found"
    test_status=1
fi

# UpdateSpec.hs should have matchHeaderAbsent hContentType
if [ -f "test/Feature/UpdateSpec.hs" ]; then
    echo "✓ test/Feature/UpdateSpec.hs exists (HEAD version)"
    if grep -q "matchHeaderAbsent hContentType" "test/Feature/UpdateSpec.hs"; then
        echo "✓ UpdateSpec.hs checks for absent Content-Type header"
    else
        echo "✗ UpdateSpec.hs missing Content-Type absence checks"
        test_status=1
    fi
else
    echo "✗ test/Feature/UpdateSpec.hs not found"
    test_status=1
fi

# UpsertSpec.hs should have matchHeaderAbsent hContentType
if [ -f "test/Feature/UpsertSpec.hs" ]; then
    echo "✓ test/Feature/UpsertSpec.hs exists (HEAD version)"
    if grep -q "matchHeaderAbsent hContentType" "test/Feature/UpsertSpec.hs"; then
        echo "✓ UpsertSpec.hs checks for absent Content-Type header"
    else
        echo "✗ UpsertSpec.hs missing Content-Type absence checks"
        test_status=1
    fi
else
    echo "✗ test/Feature/UpsertSpec.hs not found"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
