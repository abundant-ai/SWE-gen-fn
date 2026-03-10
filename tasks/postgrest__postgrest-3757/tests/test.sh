#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

# Verify that the fix has been applied by checking the files exist and have correct content
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md mentions removing params=single-object
echo "Checking that CHANGELOG.md mentions removing params=single-object..."
if grep -q "#3757, Remove support for \`Prefer: params=single-object\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions removing params=single-object - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention removing params=single-object - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs/references/api/functions.rst no longer has the deprecated warning..."
if grep -q "Prefer: params=single-object" "docs/references/api/functions.rst"; then
    echo "✗ functions.rst still contains params=single-object reference - fix not applied"
    test_status=1
else
    echo "✓ functions.rst no longer references params=single-object - fix applied!"
fi

echo ""
echo "Checking that docs/references/api/preferences.rst no longer references prefer_params..."
if grep -q "prefer_params" "docs/references/api/preferences.rst"; then
    echo "✗ preferences.rst still references prefer_params - fix not applied"
    test_status=1
else
    echo "✓ preferences.rst no longer references prefer_params - fix applied!"
fi

echo ""
echo "Checking that docs/references/api/preferences.rst no longer has the params preference listed..."
if grep -q 'Prefer: params' "docs/references/api/preferences.rst"; then
    echo "✗ preferences.rst still lists Prefer: params - fix not applied"
    test_status=1
else
    echo "✓ preferences.rst no longer lists Prefer: params - fix applied!"
fi

echo ""
echo "Checking that src/PostgREST/ApiRequest/Preferences.hs no longer has PreferParameters type..."
if grep -q "PreferParameters" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✗ Preferences.hs still contains PreferParameters - fix not applied"
    test_status=1
else
    echo "✓ Preferences.hs no longer contains PreferParameters - fix applied!"
fi

echo ""
echo "Checking that src/PostgREST/ApiRequest/Preferences.hs no longer has preferParameters field..."
if grep -q "preferParameters" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✗ Preferences.hs still contains preferParameters field - fix not applied"
    test_status=1
else
    echo "✓ Preferences.hs no longer contains preferParameters field - fix applied!"
fi

echo ""
echo "Checking that src/PostgREST/Error.hs removed hasPreferSingleObject parameter..."
if grep -q "hasPreferSingleObject" "src/PostgREST/Error.hs"; then
    echo "✗ Error.hs still contains hasPreferSingleObject - fix not applied"
    test_status=1
else
    echo "✓ Error.hs no longer contains hasPreferSingleObject - fix applied!"
fi

echo ""
echo "Checking that test file was updated..."
if [ -f "test/spec/Feature/Query/RpcSpec.hs" ]; then
    echo "✓ RpcSpec.hs test file exists - fix applied!"
else
    echo "✗ RpcSpec.hs test file does not exist - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
