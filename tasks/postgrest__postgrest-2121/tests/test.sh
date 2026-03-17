#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io"
cp "/tests/io/db_config.sql" "test/io/db_config.sql"

test_status=0

echo "Verifying fix for database configuration parsing when '=' is present in value (PR #2121)..."
echo ""
echo "This PR fixes PostgREST to correctly parse database configuration values containing '='."
echo "The bug was using split_part which only got the second part, truncating values."
echo "The fix uses substr to get everything after the first '='."
echo ""

echo "Checking Database.hs has substr-based parsing (fix applied)..."
if [ -f "src/PostgREST/Config/Database.hs" ]; then
    # The fix uses substr(setting, 1, strpos(setting, '=') - 1) for key
    # and substr(setting, strpos(setting, '=') + 1) for value
    if grep -q "substr(setting, strpos(setting, '=') + 1)" "src/PostgREST/Config/Database.hs"; then
        echo "✓ Database.hs uses substr for value extraction (fix applied)"
    else
        echo "✗ Database.hs does not use substr for value extraction (not fixed)"
        test_status=1
    fi

    # Also check that split_part is NOT being used (that's the buggy version)
    if grep -q "split_part(setting, '=', 2)" "src/PostgREST/Config/Database.hs"; then
        echo "✗ Database.hs still uses split_part (bug present)"
        test_status=1
    else
        echo "✓ Database.hs does not use split_part (bug removed)"
    fi
else
    echo "✗ Database.hs not found"
    test_status=1
fi

echo ""
echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#2120.*Fix reading database configuration.*=" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions fix for PR #2120 (fix applied)"
    else
        echo "✗ CHANGELOG.md does not mention fix (not documented)"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

test_file1="test/io/configs/expected/no-defaults-with-db.config"
if [ -f "$test_file1" ]; then
    echo "✓ $test_file1 exists (HEAD version)"
    # The HEAD version should have the value with '=' preserved
    if grep -q 'jwt-secret = "OVERRIDE=REALLY=REALLY=REALLY=REALLY=VERY=SAFE"' "$test_file1"; then
        echo "✓ $test_file1 has correct jwt-secret with '=' preserved"
    else
        echo "✗ $test_file1 does not have expected jwt-secret value"
        test_status=1
    fi
else
    echo "✗ $test_file1 not found - HEAD file not copied!"
    test_status=1
fi

test_file2="test/io/db_config.sql"
if [ -f "$test_file2" ]; then
    echo "✓ $test_file2 exists (HEAD version)"
    # The HEAD version should have values with '=' preserved
    if grep -q "pgrst.jwt_secret = 'OVERRIDE=REALLY=REALLY=REALLY=REALLY=VERY=SAFE'" "$test_file2"; then
        echo "✓ $test_file2 has correct jwt_secret with '=' preserved"
    else
        echo "✗ $test_file2 does not have expected jwt_secret value"
        test_status=1
    fi
else
    echo "✗ $test_file2 not found - HEAD file not copied!"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
