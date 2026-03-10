#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for fuzzy matching hints (PR #2575)..."
echo ""
echo "NOTE: This PR adds fuzzyset dependency and fuzzy matching logic for better error hints"
echo "HEAD (fixed) should HAVE fuzzyset dependency and fuzzy matching code"
echo "BASE (buggy) does NOT have fuzzyset or fuzzy matching - only generic hints"
echo ""

# Check postgrest.cabal - HEAD should HAVE fuzzyset dependency
echo "Checking postgrest.cabal has fuzzyset dependency..."
if grep -q "fuzzyset" "postgrest.cabal"; then
    echo "✓ postgrest.cabal has fuzzyset dependency"
else
    echo "✗ postgrest.cabal missing fuzzyset dependency - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should import Data.FuzzySet
echo "Checking src/PostgREST/Error.hs imports Data.FuzzySet..."
if grep -q "Data.FuzzySet" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs imports Data.FuzzySet"
else
    echo "✗ Error.hs does not import Data.FuzzySet - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE noRpcHint function
echo "Checking src/PostgREST/Error.hs has noRpcHint function..."
if grep -q "noRpcHint" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has noRpcHint function"
else
    echo "✗ Error.hs missing noRpcHint function - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should HAVE Fuzzy.fromList or Fuzzy.getOne calls
echo "Checking src/PostgREST/Error.hs has Fuzzy calls..."
if grep -q "Fuzzy\." "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has Fuzzy function calls"
else
    echo "✗ Error.hs missing Fuzzy function calls - fix not applied"
    test_status=1
fi

# Check ApiRequest.hs - HEAD should pass extra parameters for fuzzy matching
echo "Checking src/PostgREST/ApiRequest.hs passes parameters to NoRpc for fuzzy matching..."
if grep -q "NoRpc.*lookupProcName" "src/PostgREST/ApiRequest.hs" || grep -q "NoRpc (qiSchema qi) (qiName qi) (S.toList argumentsKeys) paramsAsSingleObject contentMediaType isInvPost (HM.keys allProcs) lookupProcName" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes extra parameters to NoRpc"
else
    echo "✗ ApiRequest.hs does not pass extra parameters - fix not applied"
    test_status=1
fi

# Check ApiRequest/Types.hs - HEAD should have extended NoRpc constructor
echo "Checking src/PostgREST/ApiRequest/Types.hs has extended NoRpc constructor..."
if grep -q "NoRpc Text Text \[Text\] Bool MediaType Bool \[QualifiedIdentifier\] \[ProcDescription\]" "src/PostgREST/ApiRequest/Types.hs"; then
    echo "✓ ApiRequest/Types.hs has extended NoRpc constructor"
else
    echo "✗ ApiRequest/Types.hs does not have extended NoRpc constructor - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have fuzzy matching hint logic, not just generic hint
echo "Checking src/PostgREST/Error.hs has fuzzy matching hint logic..."
if grep -q "Perhaps you meant to call the function" "src/PostgREST/Error.hs" || grep -q "noRpcHint schema procName argumentKeys allProcs overloadedProcs" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has fuzzy matching hint logic"
else
    echo "✗ Error.hs missing fuzzy matching hint logic - fix not applied"
    test_status=1
fi

# Check test/doc/Main.hs - HEAD should include src/PostgREST/Error.hs (for doctests)
echo "Checking test/doc/Main.hs includes Error.hs in doctests..."
if grep -q '"src/PostgREST/Error.hs"' "test/doc/Main.hs"; then
    echo "✓ test/doc/Main.hs includes Error.hs in doctests"
else
    echo "✗ test/doc/Main.hs missing Error.hs in doctests - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should have fuzzy matching hint tests
echo "Checking test/spec/Feature/Query/RpcSpec.hs has fuzzy matching hint tests..."
if grep -q "Perhaps you meant to call the function" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✓ RpcSpec.hs has fuzzy matching hint tests"
else
    echo "✗ RpcSpec.hs missing fuzzy matching hint tests - fix not applied"
    test_status=1
fi

# Check RpcSpec.hs - HEAD should NOT have only generic hints everywhere
echo "Checking test/spec/Feature/Query/RpcSpec.hs has variety of hints (not just generic)..."
hint_count=$(grep -c "Perhaps you meant to call the function" "test/spec/Feature/Query/RpcSpec.hs" || echo "0")
if [ "$hint_count" -ge 2 ]; then
    echo "✓ RpcSpec.hs has multiple fuzzy matching hints"
else
    echo "✗ RpcSpec.hs does not have enough fuzzy matching hints - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - fuzzy matching hints added successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
