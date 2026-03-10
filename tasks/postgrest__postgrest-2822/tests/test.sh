#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/CorsSpec.hs" "test/spec/Feature/CorsSpec.hs"

test_status=0

echo "Verifying fix for OPTIONS not accepting all available media types (#2822)..."
echo ""

# The fix changes ActionInfo to accept defaultMediaTypes instead of only [MTTextCSV]
# This allows OPTIONS requests to accept application/json and other media types

# Check src/PostgREST/ApiRequest.hs has ActionInfo -> defaultMediaTypes
echo "Checking src/PostgREST/ApiRequest.hs for ActionInfo -> defaultMediaTypes..."
if grep -q "ActionInfo.*-> defaultMediaTypes" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs has ActionInfo -> defaultMediaTypes"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing ActionInfo -> defaultMediaTypes - fix not applied"
    test_status=1
fi

# Check that ActionInfo does NOT have [MTTextCSV] (the buggy behavior)
echo "Checking src/PostgREST/ApiRequest.hs that ActionInfo is not restricted to MTTextCSV..."
if grep -q "ActionInfo.*-> \[MTTextCSV\]" "src/PostgREST/ApiRequest.hs"; then
    echo "✗ src/PostgREST/ApiRequest.hs still has ActionInfo -> [MTTextCSV] - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/ApiRequest.hs does not restrict ActionInfo to MTTextCSV"
fi

# Check that ActionMutate _ -> defaultMediaTypes is present
echo "Checking src/PostgREST/ApiRequest.hs for ActionMutate _ -> defaultMediaTypes..."
if grep -q "ActionMutate.*-> defaultMediaTypes" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs has ActionMutate _ -> defaultMediaTypes"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing ActionMutate _ -> defaultMediaTypes - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/CorsSpec.hs has test for application/json
echo "Checking test/spec/Feature/CorsSpec.hs has test for application/json..."
if grep -q 'Accept", "application/json"' "test/spec/Feature/CorsSpec.hs"; then
    echo "✓ test/spec/Feature/CorsSpec.hs has test for application/json"
else
    echo "✗ test/spec/Feature/CorsSpec.hs missing test for application/json - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/CorsSpec.hs has test for application/geo+json
echo "Checking test/spec/Feature/CorsSpec.hs has test for application/geo+json..."
if grep -q 'Accept", "application/geo+json"' "test/spec/Feature/CorsSpec.hs"; then
    echo "✓ test/spec/Feature/CorsSpec.hs has test for application/geo+json"
else
    echo "✗ test/spec/Feature/CorsSpec.hs missing test for application/geo+json - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/CorsSpec.hs has OPTIONS request to /items with application/json
echo "Checking test/spec/Feature/CorsSpec.hs has OPTIONS request to /items..."
if grep -q 'methodOptions "/items"' "test/spec/Feature/CorsSpec.hs" && grep -A 2 'methodOptions "/items"' "test/spec/Feature/CorsSpec.hs" | grep -q 'application/json'; then
    echo "✓ test/spec/Feature/CorsSpec.hs has OPTIONS /items with application/json"
else
    echo "✗ test/spec/Feature/CorsSpec.hs missing OPTIONS /items test - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/CorsSpec.hs has OPTIONS request to /shops with application/geo+json
echo "Checking test/spec/Feature/CorsSpec.hs has OPTIONS request to /shops..."
if grep -q 'methodOptions "/shops"' "test/spec/Feature/CorsSpec.hs" && grep -A 2 'methodOptions "/shops"' "test/spec/Feature/CorsSpec.hs" | grep -q 'application/geo+json'; then
    echo "✓ test/spec/Feature/CorsSpec.hs has OPTIONS /shops with application/geo+json"
else
    echo "✗ test/spec/Feature/CorsSpec.hs missing OPTIONS /shops test - fix not applied"
    test_status=1
fi

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has fix entry..."
if grep -q "#2821, Fix OPTIONS not accepting all available media types" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
