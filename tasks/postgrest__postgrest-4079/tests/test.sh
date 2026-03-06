#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify source code matches HEAD state (fix applied)
# This is PR #4079 which allows db-extra-search-path to accept empty value
# HEAD state (98fa5206aa) = fix applied
# BASE state (with bug.patch) = rejects empty value
# ORACLE state (BASE + fix.patch) = accepts empty value

test_status=0

echo "Verifying source code matches HEAD state (db-extra-search-path accepts empty value)..."
echo ""

echo "Checking that Config.hs includes optStringEmptyable function..."
if grep -q 'optStringEmptyable :: C.Key -> C.Parser C.Config (Maybe Text)' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has optStringEmptyable function - fix applied!"
else
    echo "✗ Config.hs missing optStringEmptyable function - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs includes splitOnCommasEmptyable function..."
if grep -q 'splitOnCommasEmptyable :: Text -> \[Text\]' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has splitOnCommasEmptyable function - fix applied!"
else
    echo "✗ Config.hs missing splitOnCommasEmptyable function - fix not applied"
    test_status=1
fi

echo "Checking that Config.hs uses splitOnCommasEmptyable for db-extra-search-path..."
if grep -q 'maybe \["public"\] splitOnCommasEmptyable <$> optStringEmptyable "db-extra-search-path"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs uses splitOnCommasEmptyable for db-extra-search-path - fix applied!"
else
    echo "✗ Config.hs not using splitOnCommasEmptyable for db-extra-search-path - fix not applied"
    test_status=1
fi

echo "Checking that test file includes test_allow_configs_to_be_set_to_empty..."
if grep -q 'def test_allow_configs_to_be_set_to_empty' "test/io/test_io.py"; then
    echo "✓ test_io.py has test_allow_configs_to_be_set_to_empty - test from HEAD!"
else
    echo "✗ test_io.py missing test_allow_configs_to_be_set_to_empty - test not from HEAD"
    test_status=1
fi

echo "Checking that documentation mentions empty string setting..."
if grep -q 'You can disable this by setting this config to' "docs/references/configuration.rst"; then
    echo "✓ configuration.rst mentions empty string setting - fix applied!"
else
    echo "✗ configuration.rst does not mention empty string setting - fix not applied"
    test_status=1
fi

echo "Checking that CHANGELOG mentions the db-extra-search-path fix..."
if grep -q "Allow \`db-extra-search-path\` to accept empty value" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions db-extra-search-path fix - fix applied!"
else
    echo "✗ CHANGELOG does not mention db-extra-search-path fix - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
