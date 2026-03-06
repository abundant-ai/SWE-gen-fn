#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ErrorSpec.hs" "test/spec/Feature/Query/ErrorSpec.hs"

# Verify source code matches HEAD state (fix applied)
# This is PR #3955 which adds Proxy-Status header for error responses
# HEAD state (f3086893) = fix applied, Proxy-Status header included in error responses
# BASE state (with bug.patch) = no Proxy-Status header

test_status=0

echo "Verifying source code matches HEAD state (Proxy-Status header fix applied)..."
echo ""

echo "Checking that CHANGELOG.md has Proxy-Status header entry..."
if grep -q "#2967, Add \`Proxy-Status\` header for better error response" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has Proxy-Status header entry - fix applied!"
else
    echo "✗ CHANGELOG.md does not have Proxy-Status header entry - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst documents Proxy-Status header..."
if grep -q "proxy-status_header" "docs/references/errors.rst" && grep -q "Proxy-Status Header" "docs/references/errors.rst"; then
    echo "✓ errors.rst documents Proxy-Status header - fix applied!"
else
    echo "✗ errors.rst does not document Proxy-Status header - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst has postgresql_errors anchor..."
if grep -q ".. _postgresql_errors:" "docs/references/errors.rst"; then
    echo "✓ errors.rst has postgresql_errors anchor - fix applied!"
else
    echo "✗ errors.rst does not have postgresql_errors anchor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that errors.rst has custom_errors anchor..."
if grep -q ".. _custom_errors:" "docs/references/errors.rst"; then
    echo "✓ errors.rst has custom_errors anchor - fix applied!"
else
    echo "✗ errors.rst does not have custom_errors anchor - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that observability.rst references Proxy-Status header..."
if grep -q "Proxy-Status Header" "docs/references/observability.rst" && grep -q "See :ref:\`proxy-status_header\`" "docs/references/observability.rst"; then
    echo "✓ observability.rst references Proxy-Status header - fix applied!"
else
    echo "✗ observability.rst does not reference Proxy-Status header - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs defines proxyStatusHeader function..."
if grep -q "proxyStatusHeader :: Text -> Header" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs defines proxyStatusHeader - fix applied!"
else
    echo "✗ Error.hs does not define proxyStatusHeader - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses proxyStatusHeader in ApiRequestError headers..."
if grep -q "headers (ApiRequestError err)  = proxyStatusHeader (code err) : headers err" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses proxyStatusHeader for ApiRequestError - fix applied!"
else
    echo "✗ Error.hs does not use proxyStatusHeader for ApiRequestError - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses proxyStatusHeader in JwtErr headers..."
if grep -q "headers (JwtErr err)           = proxyStatusHeader (code err) : headers err" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses proxyStatusHeader for JwtErr - fix applied!"
else
    echo "✗ Error.hs does not use proxyStatusHeader for JwtErr - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses proxyStatusHeader in PgErr headers..."
if grep -q "headers (PgErr err)            = proxyStatusHeader (code err) : headers err" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses proxyStatusHeader for PgErr - fix applied!"
else
    echo "✗ Error.hs does not use proxyStatusHeader for PgErr - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Error.hs uses proxyStatusHeader in NoSchemaCacheError headers..."
if grep -q "headers err@NoSchemaCacheError = proxyStatusHeader (code err) : mempty" "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses proxyStatusHeader for NoSchemaCacheError - fix applied!"
else
    echo "✗ Error.hs does not use proxyStatusHeader for NoSchemaCacheError - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has test_proxy_status_header test..."
if grep -q "def test_proxy_status_header" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_proxy_status_header - fix applied!"
else
    echo "✗ test_io.py does not have test_proxy_status_header - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ErrorSpec.hs imports SpecHelper..."
if grep -q "import SpecHelper" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs imports SpecHelper - fix applied!"
else
    echo "✗ ErrorSpec.hs does not import SpecHelper - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that ErrorSpec.hs has proxy-status header tests..."
if grep -q "includes the proxy-status header on the response" "test/spec/Feature/Query/ErrorSpec.hs"; then
    echo "✓ ErrorSpec.hs has proxy-status header tests - fix applied!"
else
    echo "✗ ErrorSpec.hs does not have proxy-status header tests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
