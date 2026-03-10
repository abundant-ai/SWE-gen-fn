#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"

test_status=0

echo "Verifying fix for doctest setup..."
echo ""

# Check that QueryParams.hs has the doctest setup section REMOVED (in buggy state it should have it, in fix it should be gone)
echo "Checking src/PostgREST/ApiRequest/QueryParams.hs for doctest setup removal..."
if ! grep -q '-- \$setup' "src/PostgREST/ApiRequest/QueryParams.hs" && \
   ! grep -q 'deriving instance Show QPError' "src/PostgREST/ApiRequest/QueryParams.hs"; then
    echo "✓ src/PostgREST/ApiRequest/QueryParams.hs doctest setup removed (fix applied)"
else
    echo "✗ src/PostgREST/ApiRequest/QueryParams.hs still has doctest setup - fix not applied"
    test_status=1
fi

# Check that Types.hs has deriving Show added back
echo "Checking src/PostgREST/ApiRequest/Types.hs for deriving Show on ApiRequestError..."
if grep -A 25 'data ApiRequestError' "src/PostgREST/ApiRequest/Types.hs" | grep -q 'deriving Show'; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs ApiRequestError has deriving Show"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs ApiRequestError missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/ApiRequest/Types.hs for deriving Show on QPError..."
if grep -q 'data QPError = QPError Text Text' "src/PostgREST/ApiRequest/Types.hs" && \
   grep -A 1 'data QPError = QPError Text Text' "src/PostgREST/ApiRequest/Types.hs" | grep -q 'deriving Show'; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs QPError has deriving Show"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs QPError missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/ApiRequest/Types.hs for deriving Show on RangeError..."
if grep -A 10 'data RangeError' "src/PostgREST/ApiRequest/Types.hs" | grep -q 'deriving Show'; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs RangeError has deriving Show"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs RangeError missing deriving Show - fix not applied"
    test_status=1
fi

# Check that FilterNullEmbed is removed from Filter data type
echo "Checking src/PostgREST/ApiRequest/Types.hs for FilterNullEmbed removal from Filter..."
if ! grep -q '| FilterNullEmbed Bool FieldName' "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Types.hs FilterNullEmbed constructor removed from Filter"
else
    echo "✗ src/PostgREST/ApiRequest/Types.hs FilterNullEmbed still present - fix not applied"
    test_status=1
fi

# Check that Plan.hs has the doctest setup and examples added
echo "Checking src/PostgREST/Plan.hs for doctest setup..."
if grep -q '\$setup' "src/PostgREST/Plan.hs" && \
   grep -q 'import Data.Ranged.Ranges (fullRange)' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has doctest setup section"
else
    echo "✗ src/PostgREST/Plan.hs missing doctest setup - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs for addNullEmbedFilters doctest examples..."
if grep -q "Don't do anything to the filter if there's no embedding" "src/PostgREST/Plan.hs" && \
   grep -q '>>> ReadPlan.where_ . rootLabel <\$> addNullEmbedFilters (readPlanTree nullOp \[\])' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has addNullEmbedFilters doctest examples"
else
    echo "✗ src/PostgREST/Plan.hs missing doctest examples - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs for updated addNullEmbedFilters implementation..."
if grep -q 'newNullFilters :: \[ReadPlan\] -> CoercibleLogicTree -> Either ApiRequestError CoercibleLogicTree' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has updated addNullEmbedFilters with newNullFilters helper"
else
    echo "✗ src/PostgREST/Plan.hs addNullEmbedFilters not updated - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/Plan.hs for FilterNullEmbed case removal from resolveFilter..."
if ! grep -q 'resolveFilter _ (FilterNullEmbed isNot fieldName) = CoercibleFilterNullEmbed isNot fieldName' "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs resolveFilter FilterNullEmbed case removed"
else
    echo "✗ src/PostgREST/Plan.hs resolveFilter still has FilterNullEmbed case - fix not applied"
    test_status=1
fi

# Check that Routine.hs has deriving Show added to types
echo "Checking src/PostgREST/SchemaCache/Routine.hs for deriving Show on PgType..."
if grep -A 3 'data PgType' "src/PostgREST/SchemaCache/Routine.hs" | grep -q 'deriving.*Show'; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs PgType has deriving Show"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs PgType missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Routine.hs for deriving Show on RetType..."
if grep -A 3 'data RetType' "src/PostgREST/SchemaCache/Routine.hs" | grep -q 'deriving.*Show'; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs RetType has deriving Show"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs RetType missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Routine.hs for deriving Show on FuncVolatility..."
if grep -A 5 'data FuncVolatility' "src/PostgREST/SchemaCache/Routine.hs" | grep -q 'deriving.*Show'; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs FuncVolatility has deriving Show"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs FuncVolatility missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Routine.hs for deriving Show on Routine..."
if grep -A 10 'data Routine = Function' "src/PostgREST/SchemaCache/Routine.hs" | grep -q 'deriving.*Show'; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs Routine has deriving Show"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs Routine missing deriving Show - fix not applied"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache/Routine.hs for deriving Show on RoutineParam..."
if grep -A 6 'data RoutineParam = RoutineParam' "src/PostgREST/SchemaCache/Routine.hs" | grep -q 'deriving.*Show'; then
    echo "✓ src/PostgREST/SchemaCache/Routine.hs RoutineParam has deriving Show"
else
    echo "✗ src/PostgREST/SchemaCache/Routine.hs RoutineParam missing deriving Show - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
