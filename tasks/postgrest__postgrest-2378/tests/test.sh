#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/OptionsSpec.hs" "test/spec/Feature/OptionsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for OPTIONS method support on RPC and root path (PR #2378)..."
echo ""
echo "NOTE: This PR adds OPTIONS method support for RPC endpoints and root path"
echo "BASE (buggy) rejects OPTIONS on RPC with 405"
echo "HEAD (fixed) returns 200 with appropriate Allow header based on function volatility"
echo ""

# Check that handleInfo supports all target types (TargetProc, TargetDefaultSpec, TargetIdent)
echo "Checking src/PostgREST/App.hs handleInfo function supports all targets..."
if grep -A 10 "handleInfo target RequestContext" "src/PostgREST/App.hs" | grep -q "TargetProc pd _"; then
    echo "✓ handleInfo handles TargetProc"
else
    echo "✗ handleInfo does not handle TargetProc - fix not applied"
    test_status=1
fi

if grep -A 10 "handleInfo target RequestContext" "src/PostgREST/App.hs" | grep -q "TargetDefaultSpec"; then
    echo "✓ handleInfo handles TargetDefaultSpec (root path)"
else
    echo "✗ handleInfo does not handle TargetDefaultSpec - fix not applied"
    test_status=1
fi

# Check that TargetProc OPTIONS returns different Allow headers based on volatility
echo "Checking handleInfo returns volatility-based Allow headers for RPC..."
if grep -A 2 "TargetProc pd _" "src/PostgREST/App.hs" | grep -q "pdVolatility pd == Volatile"; then
    echo "✓ handleInfo checks function volatility"
else
    echo "✗ handleInfo does not check function volatility - fix not applied"
    test_status=1
fi

if grep -A 2 "pdVolatility pd == Volatile" "src/PostgREST/App.hs" | grep -q '"OPTIONS,POST"'; then
    echo "✓ Volatile functions allow OPTIONS,POST"
else
    echo "✗ Volatile functions do not have correct Allow header - fix not applied"
    test_status=1
fi

if grep "pdVolatility pd == Volatile" "src/PostgREST/App.hs" -A 3 | grep -q '"OPTIONS,GET,HEAD,POST"'; then
    echo "✓ Non-volatile functions allow OPTIONS,GET,HEAD,POST"
else
    echo "✗ Non-volatile functions do not have correct Allow header - fix not applied"
    test_status=1
fi

# Check that TargetDefaultSpec returns OPTIONS,GET,HEAD
echo "Checking handleInfo returns correct Allow header for root path..."
if grep -A 2 "TargetDefaultSpec" "src/PostgREST/App.hs" | grep -q '"OPTIONS,GET,HEAD"'; then
    echo "✓ Root path allows OPTIONS,GET,HEAD"
else
    echo "✗ Root path does not have correct Allow header - fix not applied"
    test_status=1
fi

# Check that ApiRequest allows OPTIONS for RPC
echo "Checking src/PostgREST/Request/ApiRequest.hs allows OPTIONS for RPC..."
if grep "pathIsProc && method" "src/PostgREST/Request/ApiRequest.hs" | grep "notElem"; then
    # Check that OPTIONS IS in the notElem list (meaning it's allowed)
    if grep "pathIsProc && method" "src/PostgREST/Request/ApiRequest.hs" | grep -q 'notElem.*"OPTIONS"'; then
        echo "✓ ApiRequest allows OPTIONS for RPC (in allowed methods list)"
    else
        echo "✗ ApiRequest does not include OPTIONS in allowed methods - fix not applied"
        test_status=1
    fi
else
    echo "✗ ApiRequest does not have RPC method check - fix not applied"
    test_status=1
fi

# Check test files reflect the fix

# Check that test_io.py expects OPTIONS on RPC to return 200
echo "Checking test/io/test_io.py expects OPTIONS on RPC to succeed..."
if grep -A 5 "OPTIONS on RPC" "test/io/test_io.py" | grep -q "status_code == 200"; then
    echo "✓ test_io.py expects OPTIONS on RPC to return 200"
else
    echo "✗ test_io.py does not expect OPTIONS on RPC to succeed - fix not applied"
    test_status=1
fi

# Check that test_io.py expects OPTIONS on root to return 200
echo "Checking test/io/test_io.py expects OPTIONS on root to succeed..."
if grep -A 5 'OPTIONS on root' "test/io/test_io.py" | grep -q "status_code == 200"; then
    echo "✓ test_io.py expects OPTIONS on root to return 200"
else
    echo "✗ test_io.py does not expect OPTIONS on root to succeed - fix not applied"
    test_status=1
fi

# Check that OptionsSpec.hs includes tests for RPC functions
echo "Checking test/spec/Feature/OptionsSpec.hs includes RPC function tests..."
if grep -q "context \"a function\"" "test/spec/Feature/OptionsSpec.hs"; then
    echo "✓ OptionsSpec.hs includes function context"
else
    echo "✗ OptionsSpec.hs does not include function tests - fix not applied"
    test_status=1
fi

# Check for volatile function test
if grep -A 5 "volatile function" "test/spec/Feature/OptionsSpec.hs" | grep -q '"OPTIONS,POST"'; then
    echo "✓ OptionsSpec.hs tests volatile function allows OPTIONS,POST"
else
    echo "✗ OptionsSpec.hs does not test volatile function correctly - fix not applied"
    test_status=1
fi

# Check for stable/immutable function test
if grep -A 5 "stable function\|immutable function" "test/spec/Feature/OptionsSpec.hs" | grep -q '"OPTIONS,GET,HEAD,POST"'; then
    echo "✓ OptionsSpec.hs tests stable/immutable function allows OPTIONS,GET,HEAD,POST"
else
    echo "✗ OptionsSpec.hs does not test stable/immutable function correctly - fix not applied"
    test_status=1
fi

# Check for root endpoint test
echo "Checking test/spec/Feature/OptionsSpec.hs includes root endpoint test..."
if grep -q 'context "root endpoint"' "test/spec/Feature/OptionsSpec.hs"; then
    echo "✓ OptionsSpec.hs includes root endpoint context"
else
    echo "✗ OptionsSpec.hs does not include root endpoint test - fix not applied"
    test_status=1
fi

if grep -A 5 "root endpoint" "test/spec/Feature/OptionsSpec.hs" | grep -q '"OPTIONS,GET,HEAD"'; then
    echo "✓ OptionsSpec.hs tests root endpoint allows OPTIONS,GET,HEAD"
else
    echo "✗ OptionsSpec.hs does not test root endpoint correctly - fix not applied"
    test_status=1
fi

# Check that OptionsSpec.hs includes 404 test for unknown table
echo "Checking test/spec/Feature/OptionsSpec.hs includes 404 test..."
if grep -q "fails with 404 for an unknown table" "test/spec/Feature/OptionsSpec.hs"; then
    echo "✓ OptionsSpec.hs includes 404 test for unknown table"
else
    echo "✗ OptionsSpec.hs does not include 404 test - fix not applied"
    test_status=1
fi

# Check that RpcSpec.hs removes OPTIONS 405 expectation
echo "Checking test/spec/Feature/Query/RpcSpec.hs removes OPTIONS 405 test..."
if grep -q "OPTIONS fails" "test/spec/Feature/Query/RpcSpec.hs"; then
    echo "✗ RpcSpec.hs still has OPTIONS fails test - fix not applied"
    test_status=1
else
    echo "✓ RpcSpec.hs removes OPTIONS 405 test"
fi

# Check CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the OPTIONS fix..."
if grep -q "#2378" "CHANGELOG.md" && grep -q "OPTIONS" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the OPTIONS method fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - OPTIONS method support applied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
