#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RangeSpec.hs" "test/spec/Feature/Query/RangeSpec.hs"

test_status=0

echo "Verifying fix for adding error body when offset is out of bounds (PR #2472)..."
echo ""
echo "NOTE: This PR adds detailed error messages for range errors"
echo "BASE (buggy) does NOT have detailed error handling (returns empty array)"
echo "HEAD (fixed) HAS detailed 'Requested range not satisfiable' with specific details"
echo ""

# Check Error.hs - HEAD should have detailed error message
echo "Checking src/PostgREST/Error.hs has detailed error message..."
if grep -q '"message" \.= ("Requested range not satisfiable" :: Text)' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has 'Requested range not satisfiable' message"
else
    echo "✗ Error.hs does not have detailed error message - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have OutOfBounds case
echo "Checking src/PostgREST/Error.hs has OutOfBounds case..."
if grep -q "OutOfBounds" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has OutOfBounds case"
else
    echo "✗ Error.hs does not have OutOfBounds case - fix not applied"
    test_status=1
fi

# Check Error.hs - HEAD should have case expression with detailed messages
echo "Checking src/PostgREST/Error.hs has detailed error cases..."
if grep -q "NegativeLimit" "src/PostgREST/Error.hs" && grep -q "LowerGTUpper" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs has detailed error cases (NegativeLimit, LowerGTUpper, OutOfBounds)"
else
    echo "✗ Error.hs does not have detailed error cases - fix not applied"
    test_status=1
fi

# Check Request/Types.hs - HEAD should have RangeError data type
echo "Checking src/PostgREST/Request/Types.hs exports RangeError..."
if grep -q "RangeError" "src/PostgREST/Request/Types.hs"; then
    echo "✓ Request/Types.hs exports RangeError"
else
    echo "✗ Request/Types.hs does not export RangeError - fix not applied"
    test_status=1
fi

# Check App.hs - HEAD should have rsOrErrBody logic
echo "Checking src/PostgREST/App.hs has rsOrErrBody logic..."
if grep -q "rsOrErrBody" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has rsOrErrBody logic"
else
    echo "✗ App.hs does not have rsOrErrBody logic - fix not applied"
    test_status=1
fi

# Check RangeSpec.hs - HEAD should have detailed "Requested range not satisfiable" tests
echo "Checking test/spec/Feature/Query/RangeSpec.hs has detailed error tests..."
if grep -q "Requested range not satisfiable" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has detailed error message tests"
else
    echo "✗ RangeSpec.hs does not have detailed error tests - fix not applied"
    test_status=1
fi

# Check RangeSpec.hs - HEAD should have OutOfBounds error details
echo "Checking test/spec/Feature/Query/RangeSpec.hs has OutOfBounds details..."
if grep -q "An offset of.*was requested, but there are only" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has OutOfBounds error details"
else
    echo "✗ RangeSpec.hs does not have OutOfBounds details - fix not applied"
    test_status=1
fi

# Check RangeSpec.hs - HEAD should have "lower boundary must be lower" (correct typo fix)
echo "Checking test/spec/Feature/Query/RangeSpec.hs has correct boundary message..."
if grep -q "The lower boundary must be lower than or equal to the upper boundary" "test/spec/Feature/Query/RangeSpec.hs"; then
    echo "✓ RangeSpec.hs has correct boundary message (typo fixed)"
else
    echo "✗ RangeSpec.hs does not have correct boundary message - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - detailed error messages added"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
