#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
cp "/tests/spec/fixtures/privileges.sql" "test/spec/fixtures/privileges.sql"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for dollar sign($) in column names (PR #2395)..."
echo ""
echo "NOTE: This PR allows columns with dollar sign($) without double quoting"
echo "BASE (buggy) requires double quotes for columns with $"
echo "HEAD (fixed) allows $ in column names as PostgreSQL does"
echo ""

# Check that pIdentifierChar function is defined (includes $)
echo "Checking src/PostgREST/Request/QueryParams.hs defines pIdentifierChar with $..."
if grep -q "pIdentifierChar :: Parser Char" "src/PostgREST/Request/QueryParams.hs"; then
    echo "✓ pIdentifierChar function is defined"
    # Check that it includes dollar sign
    if grep -q 'pIdentifierChar = letter <|> digit <|> oneOf "_ \$"' "src/PostgREST/Request/QueryParams.hs"; then
        echo "✓ pIdentifierChar includes dollar sign ($)"
    else
        echo "✗ pIdentifierChar does not include dollar sign - fix not applied"
        test_status=1
    fi
else
    echo "✗ pIdentifierChar function not defined - fix not applied"
    test_status=1
fi

# Check that pFieldName uses pIdentifierChar
echo "Checking pFieldName uses pIdentifierChar..."
if grep -q "many1 pIdentifierChar" "src/PostgREST/Request/QueryParams.hs"; then
    echo "✓ pFieldName uses pIdentifierChar"
else
    echo "✗ pFieldName does not use pIdentifierChar - fix not applied"
    test_status=1
fi

# Check that cast parser uses pIdentifierChar
echo "Checking cast parser uses pIdentifierChar..."
if grep -A 1 "cast' <- optionMaybe" "src/PostgREST/Request/QueryParams.hs" | grep -q "many pIdentifierChar"; then
    echo "✓ Cast parser uses pIdentifierChar"
else
    echo "✗ Cast parser does not use pIdentifierChar - fix not applied"
    test_status=1
fi

# Check that language parser uses pIdentifierChar
echo "Checking language parser uses pIdentifierChar..."
if grep -q "many pIdentifierChar" "src/PostgREST/Request/QueryParams.hs" | grep -q "lang"; then
    echo "✓ Language parser uses pIdentifierChar"
else
    # This might be in a different line, let's check differently
    if grep -B 1 -A 1 "lang <- optionMaybe" "src/PostgREST/Request/QueryParams.hs" | grep -q "many pIdentifierChar"; then
        echo "✓ Language parser uses pIdentifierChar"
    else
        echo "✗ Language parser does not use pIdentifierChar - fix not applied"
        test_status=1
    fi
fi

# Check test fixture includes table with dollar signs
echo "Checking test/spec/fixtures/schema.sql includes do\$llar\$s table..."
if grep -q "CREATE TABLE do\$llar\$s" "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql includes do\$llar\$s table"
else
    echo "✗ schema.sql does not include do\$llar\$s table - fix not applied"
    test_status=1
fi

# Check test fixture data includes rows for dollar signs table
echo "Checking test/spec/fixtures/data.sql includes data for do\$llar\$s..."
if grep -q "INSERT INTO do\$llar\$s" "test/spec/fixtures/data.sql"; then
    echo "✓ data.sql includes data for do\$llar\$s table"
else
    echo "✗ data.sql does not include data for do\$llar\$s - fix not applied"
    test_status=1
fi

# Check test fixture privileges grant access to dollar signs table
echo "Checking test/spec/fixtures/privileges.sql grants access to do\$llar\$s..."
if grep -q "do\$llar\$s" "test/spec/fixtures/privileges.sql"; then
    echo "✓ privileges.sql includes do\$llar\$s table"
else
    echo "✗ privileges.sql does not include do\$llar\$s - fix not applied"
    test_status=1
fi

# Check QuerySpec includes test for dollar signs
echo "Checking test/spec/Feature/Query/QuerySpec.hs includes dollar sign test..."
if grep -q "will select and filter a column that has dollars" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs includes dollar sign test"
else
    echo "✗ QuerySpec.hs does not include dollar sign test - fix not applied"
    test_status=1
fi

# Check CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the dollar sign fix..."
if grep -q "#2395" "CHANGELOG.md" && grep -q "dollar sign" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the dollar sign fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - dollar sign support applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
