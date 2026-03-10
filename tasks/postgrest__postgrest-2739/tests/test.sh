#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/AndOrParamsSpec.hs" "test/spec/Feature/Query/AndOrParamsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"

test_status=0

echo "Verifying fix for isdistinct operator feature (#2501)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has isdistinct operator fix entry..."
if grep -q "#2501" "CHANGELOG.md" && grep -q "Allow filtering by\`IS DISTINCT FROM\` using the \`isdistinct\` operator" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has isdistinct operator fix entry"
else
    echo "✗ CHANGELOG.md missing isdistinct operator fix entry - fix not applied"
    test_status=1
fi

# Check Types.hs has IsDistinctFrom data constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has IsDistinctFrom..."
if grep -q "| IsDistinctFrom SingleVal" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs has IsDistinctFrom data constructor"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs missing IsDistinctFrom - fix not applied"
    test_status=1
fi

# Check QueryParams.hs has pIsDist parser
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs has pIsDist parser..."
if grep -q "pIsDist = IsDistinctFrom" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs has pIsDist parser"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs missing pIsDist parser - fix not applied"
    test_status=1
fi

# Check QueryParams.hs includes pIsDist in pOperation
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs includes pIsDist in pOperation..."
if grep -q "pOperation = pIn <|> pIs <|> pIsDist" "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs includes pIsDist in pOperation"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs not including pIsDist - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs has IS DISTINCT FROM SQL generation
echo "Checking src/PostgREST/Query/SqlFragment.hs has IS DISTINCT FROM SQL generation..."
if grep -q "IsDistinctFrom val -> pgFmtField table fld <> \" IS DISTINCT FROM \" <> unknownLiteral val" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ src/PostgREST/Query/SqlFragment.hs has IS DISTINCT FROM SQL generation"
else
    echo "✗ src/PostgREST/Query/SqlFragment.hs missing IS DISTINCT FROM SQL generation - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct tests
echo "Checking test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct tests..."
if grep -q 'it "can handle isdistinct"' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct tests"
else
    echo "✗ test/spec/Feature/Query/AndOrParamsSpec.hs missing isdistinct tests - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct test with arr
echo "Checking test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct test with arr..."
if grep -q 'arr.isdistinct.{1,2}' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct test with arr"
else
    echo "✗ test/spec/Feature/Query/AndOrParamsSpec.hs missing isdistinct test with arr - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct with range
echo "Checking test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct test with range..."
if grep -q 'range=isdistinct.\[1,3\]' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ test/spec/Feature/Query/AndOrParamsSpec.hs has isdistinct test with range"
else
    echo "✗ test/spec/Feature/Query/AndOrParamsSpec.hs missing isdistinct test with range - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/AndOrParamsSpec.hs has negated isdistinct test
echo "Checking test/spec/Feature/Query/AndOrParamsSpec.hs has negated isdistinct test..."
if grep -q 'it "isdistinct can be negated"' "test/spec/Feature/Query/AndOrParamsSpec.hs"; then
    echo "✓ test/spec/Feature/Query/AndOrParamsSpec.hs has negated isdistinct test"
else
    echo "✗ test/spec/Feature/Query/AndOrParamsSpec.hs missing negated isdistinct test - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/QuerySpec.hs has isdistinct tests
echo "Checking test/spec/Feature/Query/QuerySpec.hs has isdistinct tests..."
if grep -q 'it "matches with IS DISTINCT FROM"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has isdistinct tests"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing isdistinct tests - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/QuerySpec.hs has isdistinct query
echo "Checking test/spec/Feature/Query/QuerySpec.hs has isdistinct query..."
if grep -q 'a=isdistinct.2' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has isdistinct query"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing isdistinct query - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/QuerySpec.hs has negated isdistinct test
echo "Checking test/spec/Feature/Query/QuerySpec.hs has negated isdistinct test..."
if grep -q 'it "matches with IS DISTINCT FROM using not operator"' "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ test/spec/Feature/Query/QuerySpec.hs has negated isdistinct test"
else
    echo "✗ test/spec/Feature/Query/QuerySpec.hs missing negated isdistinct test - fix not applied"
    test_status=1
fi

# Check test/spec/fixtures/data.sql has the null range entry
echo "Checking test/spec/fixtures/data.sql has null range entry..."
if grep -q "INSERT INTO ranges VALUES (5, null);" "test/spec/fixtures/data.sql"; then
    echo "✓ test/spec/fixtures/data.sql has null range entry"
else
    echo "✗ test/spec/fixtures/data.sql missing null range entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
