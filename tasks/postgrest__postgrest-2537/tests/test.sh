#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AndOrParamsSpec.hs" "test/spec/Feature/Query/AndOrParamsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"

test_status=0

echo "Verifying fix for query string parsing (PR #2537)..."
echo ""
echo "NOTE: This PR fixes query string parsing to be stricter and more consistent."
echo "It handles whitespace in field names, bracket syntax errors, and ambiguous select syntax."
echo "HEAD (fixed) should have stricter parsing with proper SelectItem types"
echo "BASE (buggy) has permissive parsing that silently accepts invalid syntax"
echo ""

# Check CHANGELOG.md - HEAD should HAVE the entries for the parsing fixes
echo "Checking CHANGELOG.md mentions query parsing fixes..."
if grep -q "#2362, Fix error message when \[\] is used inside select" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2362 (bracket syntax fix)"
else
    echo "✗ CHANGELOG.md missing #2362 entry - fix not applied"
    test_status=1
fi

if grep -q "#2475, Disallow !inner on computed columns" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2475 (disallow !inner)"
else
    echo "✗ CHANGELOG.md missing #2475 entry - fix not applied"
    test_status=1
fi

if grep -q "#2285, Ignore leading and trailing spaces in column names" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions #2285 (whitespace handling)"
else
    echo "✗ CHANGELOG.md missing #2285 entry - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md for the Changed section entry
echo "Checking CHANGELOG.md has Changed section entry for #2537..."
if grep -q "#2537, Stricter parsing of query string" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has Changed section entry for #2537"
else
    echo "✗ CHANGELOG.md missing Changed section entry for #2537 - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should import SelectItem(..)
echo "Checking src/PostgREST/ApiRequest.hs imports SelectItem(..)..."
if grep -A 2 "import PostgREST.ApiRequest.Types" "src/PostgREST/ApiRequest.hs" | grep -q "SelectItem (..)"; then
    echo "✓ ApiRequest.hs imports SelectItem(..)"
else
    echo "✗ ApiRequest.hs doesn't import SelectItem(..) - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should use SelectField pattern matching
echo "Checking src/PostgREST/ApiRequest.hs uses SelectField pattern..."
if grep -q 'fstFieldName \[Node SelectField{selField=("\*", _)}' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs uses SelectField pattern matching"
else
    echo "✗ ApiRequest.hs doesn't use SelectField pattern - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should import SelectItem(..)
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs imports SelectItem(..)..."
if grep "QPError (..)" "src/PostgREST/ApiRequest/QueryParams.hs" | grep -q "SelectItem (..)"; then
    echo "✓ QueryParams.hs imports SelectItem(..)"
else
    echo "✗ QueryParams.hs doesn't import SelectItem(..) - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have deriving Show SelectItem
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has Show SelectItem..."
if grep -q "deriving instance Show SelectItem" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has Show SelectItem deriving"
else
    echo "✗ QueryParams.hs missing Show SelectItem - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should have pFieldForest with proper SelectItem construction
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pFieldForest documentation..."
if grep -q "Parse select= into a Forest of SelectItems" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs has pFieldForest documentation"
else
    echo "✗ QueryParams.hs missing pFieldForest documentation - fix not applied"
    test_status=1
fi

# Check QueryParams.hs - HEAD should show SelectField in doctest examples
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs doctests show SelectField..."
if grep -q 'SelectField {selField = ("name",\[\])' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ QueryParams.hs doctests show SelectField"
else
    echo "✗ QueryParams.hs doctests don't show SelectField - fix not applied"
    test_status=1
fi

# Check Types.hs - HEAD should define SelectItem data type
echo "Checking src/PostgREST/ApiRequest/Types.hs defines SelectItem type..."
if grep -q "data SelectItem" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs defines SelectItem data type"
else
    echo "✗ Types.hs doesn't define SelectItem data type - fix not applied"
    test_status=1
fi

# Check Types.hs - HEAD should have SelectField constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has SelectField constructor..."
if grep -q "SelectField" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has SelectField constructor"
else
    echo "✗ Types.hs doesn't have SelectField constructor - fix not applied"
    test_status=1
fi

# Check Types.hs - HEAD should have SelectRelation constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has SelectRelation constructor..."
if grep -q "SelectRelation" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ Types.hs has SelectRelation constructor"
else
    echo "✗ Types.hs doesn't have SelectRelation constructor - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - query string parsing fix applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
