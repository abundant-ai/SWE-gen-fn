#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/postgrest.py" "test/io/postgrest.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for PostgreSQL authentication failure handling (PR #2625)..."
echo ""
echo "NOTE: This PR fixes authentication error handling to immediately exit on password failures"
echo "HEAD (fixed) should have test_fail_with_invalid_password test and use isPrefixOf for auth check"
echo "BASE (buggy) doesn't have the test and uses isInfixOf"
echo ""

# Check Error.hs - HEAD should use isPrefixOf instead of isInfixOf for auth failure detection
echo "Checking src/PostgREST/Error.hs uses isPrefixOf instead of isInfixOf..."
if grep -q "isPrefixOf" "src/PostgREST/Error.hs" && ! grep -q '"FATAL:  password authentication failed" \`isInfixOf\`' "src/PostgREST/Error.hs"; then
    echo "✓ Error.hs uses isPrefixOf (not isInfixOf)"
else
    echo "✗ Error.hs still uses isInfixOf or missing isPrefixOf - fix not applied"
    test_status=1
fi

# Check test_io.py - HEAD should have test_fail_with_invalid_password test
echo "Checking test/io/test_io.py has test_fail_with_invalid_password test..."
if grep -q "def test_fail_with_invalid_password" "test/io/test_io.py"; then
    echo "✓ test_io.py has test_fail_with_invalid_password test"
else
    echo "✗ test_io.py missing test_fail_with_invalid_password - fix not applied"
    test_status=1
fi

# Check test_io.py - HEAD test should use wait_for_readiness=False
echo "Checking test/io/test_io.py test_fail_with_invalid_password uses wait_for_readiness=False..."
if grep -A5 "def test_fail_with_invalid_password" "test/io/test_io.py" | grep -q "wait_for_readiness=False"; then
    echo "✓ test_io.py test uses wait_for_readiness=False"
else
    echo "✗ test_io.py test doesn't use wait_for_readiness=False - fix not applied"
    test_status=1
fi

# Check postgrest.py - HEAD should have wait_for_readiness parameter
echo "Checking test/io/postgrest.py has wait_for_readiness parameter..."
if grep -A10 "^def run(" "test/io/postgrest.py" | grep -q "wait_for_readiness=True"; then
    echo "✓ postgrest.py has wait_for_readiness parameter"
else
    echo "✗ postgrest.py missing wait_for_readiness parameter - fix not applied"
    test_status=1
fi

# Check postgrest.py - HEAD should have wait_until_exit function
echo "Checking test/io/postgrest.py has wait_until_exit function..."
if grep -q "def wait_until_exit" "test/io/postgrest.py"; then
    echo "✓ postgrest.py has wait_until_exit function"
else
    echo "✗ postgrest.py missing wait_until_exit function - fix not applied"
    test_status=1
fi

# Check nix config - HEAD should have HBA_FILE configuration for password auth
echo "Checking nix/tools/withTools.nix has HBA_FILE configuration..."
if grep -q 'HBA_FILE=' "nix/tools/withTools.nix" && grep -q 'some_protected_user password' "nix/tools/withTools.nix"; then
    echo "✓ withTools.nix has HBA_FILE configuration for password authentication"
else
    echo "✗ withTools.nix missing HBA_FILE configuration - fix not applied"
    test_status=1
fi

# Check nix config - HEAD should use hba_file in pg_ctl start options
echo "Checking nix/tools/withTools.nix uses hba_file in pg_ctl start..."
if grep -q 'hba_file=$HBA_FILE' "nix/tools/withTools.nix"; then
    echo "✓ withTools.nix uses hba_file in pg_ctl start"
else
    echo "✗ withTools.nix doesn't use hba_file - fix not applied"
    test_status=1
fi

# Check CHANGELOG - HEAD should mention the fix for #2622
echo "Checking CHANGELOG.md mentions fix for authentication failure..."
if grep -q "#2622" "CHANGELOG.md" && grep -q "authentication failure" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions the fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - authentication failure handling properly fixed"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
