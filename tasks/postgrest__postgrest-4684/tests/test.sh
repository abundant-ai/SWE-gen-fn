#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/ConcurrentSpec.hs" "test/spec/Feature/ConcurrentSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #4684 which fixes leaking table and function names in error hints
# HEAD state (d0945d982cb9afc9f67074d083e80deb2694a279) = fix applied, stricter hint filtering
# BASE state (with bug.patch) = old permissive hint filtering

test_status=0

echo "Verifying source code matches HEAD state (stricter hint filtering applied)..."
echo ""

echo "Checking that CHANGELOG.md has entry about fixing the hint leak..."
if grep -q "Fix leaking table and function names when calculating error hint" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry about fixing hint leak - fix applied!"
else
    echo "✗ CHANGELOG.md does not have entry about fixing hint leak - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs has HintType data type..."
if grep -q "data HintType" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has HintType data type - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not have HintType data type - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs has getFuzzyHint function..."
if grep -q "getFuzzyHint :: HintType -> Fuzzy.FuzzySet -> Text -> Maybe Text" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has getFuzzyHint function - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not have getFuzzyHint function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs uses getOneWithMinScore for table hints..."
if grep -q "HintTable.*Fuzzy.getOneWithMinScore minScore" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses getOneWithMinScore for table hints - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not use getOneWithMinScore for table hints - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs uses getOneWithMinScore for procedure hints..."
if grep -q "HintProcedure.*Fuzzy.getOneWithMinScore minScore" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs uses getOneWithMinScore for procedure hints - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not use getOneWithMinScore for procedure hints - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that src/PostgREST/Error.hs defines minScore as 0.75..."
if grep -q "minScore = 0.75 :: Double" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs defines minScore as 0.75 - fix applied!"
else
    echo "✗ src/PostgREST/Error.hs does not define minScore as 0.75 - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
