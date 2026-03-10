#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

test_status=0

echo "Verifying fix for any/all quantifiers on operators (#1569)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has any/all quantifiers fix entry..."
if grep -q "#1569" "CHANGELOG.md" && grep -q "Allow \`any/all\` modifiers on the \`eq,like,ilike,gt,gte,lt,lte,match,imatch\` operators" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has any/all quantifiers fix entry"
else
    echo "✗ CHANGELOG.md missing any/all quantifiers fix entry - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md mentions array type conversion
echo "Checking CHANGELOG.md mentions array type conversion..."
if grep -q "This converts the input into an array type" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions array type conversion"
else
    echo "✗ CHANGELOG.md missing array type conversion note - fix not applied"
    test_status=1
fi

# Check QueryParams.hs imports parserFail (needed for new error handling)
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs imports are reverted..."
if ! grep -q "import Text.Parsec.Prim.*parserFail" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs imports reverted correctly"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs still has parserFail import - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has OpQuantifier import
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has OpQuantifier import..."
if grep -q "OpQuantifier" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has OpQuantifier import"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing OpQuantifier import - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has QuantOperator import
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has QuantOperator import..."
if grep -q "QuantOperator" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has QuantOperator import"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing QuantOperator import - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has simpleOperator parser function
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has simpleOperator parser..."
if grep -q "simpleOperator :: Parser SimpleOperator" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has simpleOperator parser"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing simpleOperator parser - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has quantOperator parser function
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has quantOperator parser..."
if grep -q "quantOperator :: Parser QuantOperator" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has quantOperator parser"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing quantOperator parser - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has pSimpleOp parser
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pSimpleOp in pOperation..."
if grep -q "pSimpleOp" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has pSimpleOp parser"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing pSimpleOp - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has pQuantOp parser
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pQuantOp in pOperation..."
if grep -q "pQuantOp" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has pQuantOp parser"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing pQuantOp - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has QuantAny and QuantAll parsing
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has QuantAny/QuantAll parsing..."
if grep -q 'QuantAny\|QuantAll' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has QuantAny/QuantAll parsing"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing QuantAny/QuantAll - fix not applied"
    test_status=1
fi

# Check Types.hs has OpQuantifier data type
echo "Checking src/PostgREST/ApiRequest/Types.hs has OpQuantifier data type..."
if grep -q "data OpQuantifier = QuantAny | QuantAll" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs has OpQuantifier data type"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs missing OpQuantifier - fix not applied"
    test_status=1
fi

# Check Types.hs has OpQuant constructor in Operation
echo "Checking src/PostgREST/ApiRequest/Types.hs has OpQuant in Operation..."
if grep -q "OpQuant QuantOperator (Maybe OpQuantifier) SingleVal" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs has OpQuant constructor"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs missing OpQuant - fix not applied"
    test_status=1
fi

# Check Types.hs has QuantOperator data type
echo "Checking src/PostgREST/ApiRequest/Types.hs has QuantOperator data type..."
if grep -q "data QuantOperator" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs has QuantOperator data type"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs missing QuantOperator - fix not applied"
    test_status=1
fi

# Check Plan.hs uses OpQuant OpEqual Nothing pattern
echo "Checking src/PostgREST/Plan.hs uses OpQuant OpEqual Nothing pattern..."
if grep -q "OpQuant OpEqual Nothing" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses OpQuant OpEqual Nothing pattern"
else
    echo "✗ src/PostgREST/Plan.hs not using OpQuant pattern - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs has quantOperator function
echo "Checking src/PostgREST/Query/SqlFragment.hs has quantOperator function..."
if grep -q "quantOperator :: QuantOperator -> SqlFragment" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs has quantOperator function"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing quantOperator - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs has OpQuant case in pgFmtFilter
echo "Checking src/PostgREST/Query/SqlFragment.hs has OpQuant case in pgFmtFilter..."
if grep -q "OpQuant op quant val" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs has OpQuant case"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing OpQuant case - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs has fmtQuant helper function
echo "Checking src/PostgREST/Query/SqlFragment.hs has fmtQuant helper..."
if grep -q "fmtQuant q val" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs has fmtQuant helper"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing fmtQuant - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs generates ANY/ALL SQL
echo "Checking src/PostgREST/Query/SqlFragment.hs generates ANY/ALL SQL..."
if grep -q 'QuantAny.*"ANY("' "src/PostgREST/Query/SqlFragment.hs" && grep -q 'QuantAll.*"ALL("' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs generates ANY/ALL SQL"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing ANY/ALL SQL generation - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs has any/all quantifier tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has any/all quantifier tests..."
if grep -q 'context "any/all quantifiers"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has any/all quantifier tests"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing any/all quantifier tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs has eq(any) test
echo "Checking test/spec/Feature/Query/QuerySpec.hs has eq(any) test..."
if grep -q 'id=eq(any)' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has eq(any) test"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing eq(any) test - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs has gt(all)/gte(all) tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has gt(all)/gte(all) tests..."
if grep -q 'gt(all)' "test/spec/Feature/Query/QuerySpec.hs" && grep -q 'gte(all)' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has gt(all)/gte(all) tests"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing gt(all)/gte(all) tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs has like(any)/ilike(all) tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has like(any)/ilike(all) tests..."
if grep -q 'like(any)' "test/spec/Feature/Query/QuerySpec.hs" && grep -q 'ilike(all)' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has like(any)/ilike(all) tests"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing like(any)/ilike(all) tests - fix not applied"
    test_status=1
fi

# Check QuerySpec.hs has match(any)/imatch(any) tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has match(any)/imatch(any) tests..."
if grep -q 'match(any)' "test/spec/Feature/Query/QuerySpec.hs" && grep -q 'imatch(any)' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has match(any)/imatch(any) tests"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing match(any)/imatch(any) tests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
