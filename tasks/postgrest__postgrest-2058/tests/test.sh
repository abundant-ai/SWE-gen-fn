#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for void RPC return type (PR #2058)..."
echo ""
echo "This PR ensures that RPCs returning VOID respond with 204 No Content without Content-Type header."
echo "The bug was that void RPCs would return 200 OK with either \"\" or null body and Content-Type header."
echo "The fix makes them return 204 No Content with no body and no Content-Type header."
echo ""

echo "Checking App.hs has the fix applied..."
if [ -f "src/PostgREST/App.hs" ]; then
    echo "✓ src/PostgREST/App.hs exists"

    # After fix: handleInvoke should check for void and return 204 without Content-Type
    # Look for the pattern: if Proc.procReturnsVoid proc then response HTTP.status204
    if grep -q "if Proc.procReturnsVoid proc then" "src/PostgREST/App.hs"; then
        echo "✓ App.hs checks for void return type (fix applied)"

        # Check that 204 response uses empty headers [] instead of contentTypeHeaders
        if grep -A 1 "if Proc.procReturnsVoid proc then" "src/PostgREST/App.hs" | grep -q "response HTTP.status204 \["; then
            echo "✓ App.hs uses empty headers [] for 204 response (fix applied)"
        else
            echo "✗ App.hs not using empty headers for 204 response (fix not applied)"
            test_status=1
        fi
    else
        echo "✗ App.hs not checking for void return type (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking Proc.hs has the fix applied..."
if [ -f "src/PostgREST/DbStructure/Proc.hs" ]; then
    echo "✓ src/PostgREST/DbStructure/Proc.hs exists"

    # After fix: should have procReturnsVoid function
    if grep -q "procReturnsVoid :: ProcDescription -> Bool" "src/PostgREST/DbStructure/Proc.hs"; then
        echo "✓ Proc.hs has procReturnsVoid function (fix applied)"
    else
        echo "✗ Proc.hs missing procReturnsVoid function (fix not applied)"
        test_status=1
    fi

    # After fix: pdReturnType should be Maybe RetType (not just RetType)
    if grep -q "pdReturnType  :: Maybe RetType" "src/PostgREST/DbStructure/Proc.hs"; then
        echo "✓ Proc.hs uses Maybe RetType for pdReturnType (fix applied)"
    else
        echo "✗ Proc.hs not using Maybe RetType (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/DbStructure/Proc.hs not found"
    test_status=1
fi

echo ""
echo "Checking DbStructure.hs has the fix applied..."
if [ -f "src/PostgREST/DbStructure.hs" ]; then
    echo "✓ src/PostgREST/DbStructure.hs exists"

    # After fix: should query for rettype_is_void column
    if grep -q "rettype_is_void" "src/PostgREST/DbStructure.hs"; then
        echo "✓ DbStructure.hs queries for rettype_is_void (fix applied)"
    else
        echo "✗ DbStructure.hs not querying for rettype_is_void (fix not applied)"
        test_status=1
    fi

    # After fix: parseRetType should handle isVoid parameter
    if grep -q "parseRetType.*isVoid" "src/PostgREST/DbStructure.hs"; then
        echo "✓ DbStructure.hs parseRetType handles void (fix applied)"
    else
        echo "✗ DbStructure.hs parseRetType not handling void (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/DbStructure.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files expect 204 No Content for void RPCs..."

# RpcSpec.hs should expect 204 with no Content-Type for void
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ]; then
    echo "✓ test/spec/Feature/Query/RpcSpec.hs exists (HEAD version)"
    if grep -q "returns 204, no Content-Type header and no content for void" "test/spec/Feature/Query/RpcSpec.hs"; then
        echo "✓ RpcSpec.hs expects 204 for void RPC (matches fixed code)"

        # Check it expects matchHeaderAbsent hContentType (within 7 lines of ret_void)
        if grep -A 7 "ret_void" "test/spec/Feature/Query/RpcSpec.hs" | grep -q "matchHeaderAbsent hContentType"; then
            echo "✓ RpcSpec.hs checks for absent Content-Type header"
        else
            echo "✗ RpcSpec.hs not checking for absent Content-Type"
            test_status=1
        fi
    else
        echo "✗ RpcSpec.hs not expecting 204 for void RPC"
        test_status=1
    fi
else
    echo "✗ test/spec/Feature/Query/RpcSpec.hs not found"
    test_status=1
fi

# InsertSpec.hs should have matchHeaderAbsent hContentType for 204 responses
if [ -f "test/spec/Feature/Query/InsertSpec.hs" ]; then
    echo "✓ test/spec/Feature/Query/InsertSpec.hs exists (HEAD version)"
    if grep -q "matchHeaderAbsent hContentType" "test/spec/Feature/Query/InsertSpec.hs"; then
        echo "✓ InsertSpec.hs checks for absent Content-Type header (matches fixed code)"
    else
        echo "✗ InsertSpec.hs missing Content-Type absence checks"
        test_status=1
    fi
else
    echo "✗ test/spec/Feature/Query/InsertSpec.hs not found"
    test_status=1
fi

# test_io.py should expect 204 for void RPCs
if [ -f "test/io/test_io.py" ]; then
    echo "✓ test/io/test_io.py exists (HEAD version)"
    # Check that tests expect 204 status codes (the fix changes 200 to 204)
    if grep -q "assert response.status_code == 204" "test/io/test_io.py"; then
        echo "✓ test_io.py expects 204 status codes (matches fixed code)"
    else
        echo "✗ test_io.py not expecting 204 status codes"
        test_status=1
    fi
else
    echo "✗ test/io/test_io.py not found"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
