#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ServerTimingSpec.hs" "test/spec/Feature/Query/ServerTimingSpec.hs"

# Verify that the fix has been applied by checking test file and source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check App.hs for parse timing calculation
echo "Checking App.hs for parse timing calculation..."
if grep -q "calcTiming configServerTimingEnabled" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has parse timing calculation"
else
    echo "✗ App.hs missing parse timing calculation - fix not applied"
    test_status=1
fi

# Check App.hs for jwtAndParseTiming list
echo "Checking App.hs for jwtAndParseTiming list..."
if grep -q "jwtAndParseTiming" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has jwtAndParseTiming"
else
    echo "✗ App.hs missing jwtAndParseTiming - fix not applied"
    test_status=1
fi

# Check App.hs for SMParse metric
echo "Checking App.hs for SMParse metric..."
if grep -q "SMParse" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has SMParse metric"
else
    echo "✗ App.hs missing SMParse metric - fix not applied"
    test_status=1
fi

# Check App.hs handleRequest signature with list parameter
echo "Checking App.hs handleRequest signature..."
if grep -q "handleRequest :: AuthResult -> AppConfig -> AppState.AppState -> Bool -> Bool -> PgVersion -> ApiRequest -> SchemaCache -> \[(ServerMetric, Maybe Double)\] -> Handler IO Wai.Response" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has correct handleRequest signature with list"
else
    echo "✗ App.hs missing correct handleRequest signature - fix not applied"
    test_status=1
fi

# Check App.hs for SMTransaction (not SMQuery)
echo "Checking App.hs for SMTransaction metric..."
if grep -q "SMTransaction" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has SMTransaction metric"
else
    echo "✗ App.hs missing SMTransaction metric - fix not applied"
    test_status=1
fi

# Make sure old SMQuery is NOT present (should be renamed to SMTransaction)
echo "Checking App.hs for absence of old SMQuery metric..."
if ! grep -q "SMQuery" "src/PostgREST/App.hs"; then
    echo "✓ App.hs does not have old SMQuery metric"
else
    echo "✗ App.hs still has old SMQuery metric - fix not applied"
    test_status=1
fi

# Check App.hs for txTime variable (not rsTime)
echo "Checking App.hs for txTime variable..."
if grep -q "txTime'" "src/PostgREST/App.hs"; then
    echo "✓ App.hs has txTime variable"
else
    echo "✗ App.hs missing txTime variable - fix not applied"
    test_status=1
fi

# Check ServerTimingSpec.hs for test expectations
echo "Checking ServerTimingSpec.hs for test expectations..."
if grep -q 'matchServerTimingHasTiming \["jwt", "parse", "plan", "transaction", "render"\]' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has correct test expectations"
else
    echo "✗ ServerTimingSpec.hs missing correct test expectations - fix not applied"
    test_status=1
fi

# Check ServerTimingSpec.hs has multiple test cases
echo "Checking ServerTimingSpec.hs for get request test..."
if grep -q 'it "works with get request"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has get request test"
else
    echo "✗ ServerTimingSpec.hs missing get request test - fix not applied"
    test_status=1
fi

echo "Checking ServerTimingSpec.hs for post request test..."
if grep -q 'it "works with post request"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has post request test"
else
    echo "✗ ServerTimingSpec.hs missing post request test - fix not applied"
    test_status=1
fi

echo "Checking ServerTimingSpec.hs for patch request test..."
if grep -q 'it "works with patch request"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has patch request test"
else
    echo "✗ ServerTimingSpec.hs missing patch request test - fix not applied"
    test_status=1
fi

echo "Checking ServerTimingSpec.hs for put request test..."
if grep -q 'it "works with put request"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has put request test"
else
    echo "✗ ServerTimingSpec.hs missing put request test - fix not applied"
    test_status=1
fi

echo "Checking ServerTimingSpec.hs for delete request test..."
if grep -q 'it "works with delete request"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has delete request test"
else
    echo "✗ ServerTimingSpec.hs missing delete request test - fix not applied"
    test_status=1
fi

echo "Checking ServerTimingSpec.hs for rpc call test..."
if grep -q 'it "works with rpc call"' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has rpc call test"
else
    echo "✗ ServerTimingSpec.hs missing rpc call test - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
