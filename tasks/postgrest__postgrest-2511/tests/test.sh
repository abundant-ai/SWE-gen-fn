#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RelatedQueriesSpec.hs" "test/spec/Feature/Query/RelatedQueriesSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for restoring related orders feature (PR #2511, issue #1414)..."
echo ""
echo "NOTE: This PR restores the 'related orders' feature that allows ordering parent rows by child columns."
echo "HEAD (fixed) should have the related order feature present with all code and tests"
echo "BASE (buggy) has the related order feature removed (regression)"
echo ""

# Check CHANGELOG.md - HEAD should mention related orders feature
echo "Checking CHANGELOG.md mentions related orders feature..."
if grep -q "Add related orders" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions related orders feature"
else
    echo "✗ CHANGELOG.md missing related orders - fix not applied"
    test_status=1
fi

# Check postgrest.cabal - HEAD should have RelatedQueriesSpec
echo "Checking postgrest.cabal includes RelatedQueriesSpec..."
if grep -q "Feature.Query.RelatedQueriesSpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes RelatedQueriesSpec"
else
    echo "✗ postgrest.cabal missing RelatedQueriesSpec - fix not applied"
    test_status=1
fi

# Check ApiRequest/QueryParams.hs - HEAD should have OrderRelationTerm parsing
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pOrderRelationTerm..."
if grep -q "pOrderRelationTerm" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has pOrderRelationTerm"
else
    echo "✗ QueryParams.hs missing pOrderRelationTerm - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has full pOrder with try..."
if grep -q "pOrder = lexeme (try pOrderRelationTerm <|> pOrderTerm)" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has full pOrder with try pOrderRelationTerm"
else
    echo "✗ QueryParams.hs doesn't have full pOrder - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should have OrderRelationTerm in OrderTerm type
echo "Checking src/PostgREST/ApiRequest/Types.hs has OrderRelationTerm..."
if grep -q "OrderRelationTerm" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has OrderRelationTerm"
else
    echo "✗ Types.hs missing OrderRelationTerm - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/ApiRequest/Types.hs has NotToOne error..."
if grep -q "NotToOne" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has NotToOne error"
else
    echo "✗ Types.hs missing NotToOne error - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have NotToOne handling
echo "Checking src/PostgREST/Error.hs has NotToOne handling..."
if grep -q "NotToOne" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has NotToOne handling"
else
    echo "✗ Error.hs missing NotToOne handling - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Error.hs has ApiRequestErrorCode18..."
if grep -q "ApiRequestErrorCode18" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has ApiRequestErrorCode18"
else
    echo "✗ Error.hs missing ApiRequestErrorCode18 - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Error.hs has original NotEmbedded message..."
if grep -q "'.*' is not an embedded resource in this request" "src/PostgREST/Error.hs" && \
   ! grep -q "Cannot apply filter because" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has original NotEmbedded error message"
else
    echo "✗ Error.hs has wrong error message - fix not applied"
    test_status=1
fi

# Check Plan.hs - HEAD should have addRelatedOrders
echo "Checking src/PostgREST/Plan.hs has addRelatedOrders..."
if grep -q "addRelatedOrders" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has addRelatedOrders"
else
    echo "✗ Plan.hs missing addRelatedOrders - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs imports relIsToOne..."
if grep -q "relIsToOne" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs imports relIsToOne"
else
    echo "✗ Plan.hs missing relIsToOne import - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs - HEAD should use relIsToOne function
echo "Checking src/PostgREST/Query/QueryBuilder.hs uses relIsToOne function..."
if grep -q "if relIsToOne rel" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs uses relIsToOne function"
else
    echo "✗ QueryBuilder.hs not using relIsToOne function - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Query/QueryBuilder.hs imports relIsToOne..."
if grep -q "relIsToOne)" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ QueryBuilder.hs imports relIsToOne"
else
    echo "✗ QueryBuilder.hs missing relIsToOne import - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs - HEAD should handle OrderRelationTerm
echo "Checking src/PostgREST/Query/SqlFragment.hs handles OrderRelationTerm..."
if grep -q "OrderRelationTerm" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs handles OrderRelationTerm"
else
    echo "✗ SqlFragment.hs doesn't handle OrderRelationTerm - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Query/SqlFragment.hs has fmtOTerm pattern matching..."
if grep -q "fmtOTerm = " "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has fmtOTerm pattern matching"
else
    echo "✗ SqlFragment.hs missing fmtOTerm - fix not applied"
    test_status=1
fi

# Check Relationship.hs - HEAD should export relIsToOne
echo "Checking src/PostgREST/SchemaCache/Relationship.hs exports relIsToOne..."
if grep -q "relIsToOne" "src/PostgREST/SchemaCache/Relationship.hs"; then
    echo "✓ Relationship.hs exports relIsToOne"
else
    echo "✗ Relationship.hs missing relIsToOne - fix not applied"
    test_status=1
fi

# Check test files - HEAD should have original error messages
echo "Checking test/spec/Feature/Query/QuerySpec.hs has original error messages..."
if grep -q "'.*' is not an embedded resource in this request" "test/spec/Feature/Query/QuerySpec.hs" && \
   ! grep -q "Cannot apply filter because" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has original error messages"
else
    echo "✗ QuerySpec.hs has wrong error messages - fix not applied"
    test_status=1
fi

# Check RelatedQueriesSpec.hs - HEAD should have content
echo "Checking test/spec/Feature/Query/RelatedQueriesSpec.hs has content..."
if [ -f "test/spec/Feature/Query/RelatedQueriesSpec.hs" ]; then
    file_size=$(wc -c < "test/spec/Feature/Query/RelatedQueriesSpec.hs")
    if [ "$file_size" -gt 100 ]; then
        echo "✓ RelatedQueriesSpec.hs has content (present)"
    else
        echo "✗ RelatedQueriesSpec.hs is empty - fix not applied"
        test_status=1
    fi
else
    echo "✗ RelatedQueriesSpec.hs doesn't exist - fix not applied"
    test_status=1
fi

# Check Main.hs - HEAD should import RelatedQueriesSpec
echo "Checking test/spec/Main.hs imports RelatedQueriesSpec..."
if grep -q "Feature.Query.RelatedQueriesSpec" "test/spec/Main.hs"; then
    echo "✓ Main.hs imports RelatedQueriesSpec"
else
    echo "✗ Main.hs missing RelatedQueriesSpec import - fix not applied"
    test_status=1
fi

# Check data.sql - HEAD should have trash table data
echo "Checking test/spec/fixtures/data.sql has trash table data..."
if grep -q "INSERT INTO trash" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql has trash table data"
else
    echo "✗ data.sql missing trash table data - fix not applied"
    test_status=1
fi

# Check schema.sql - HEAD should have trash table definitions
echo "Checking test/spec/fixtures/schema.sql has trash table definitions..."
if grep -q "create table test.trash" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has trash table definitions"
else
    echo "✗ schema.sql missing trash table definitions - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - related orders feature successfully restored"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
