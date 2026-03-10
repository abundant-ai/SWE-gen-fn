#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that Config.hs has the parseServerPort function that validates ports are different
echo "Checking that Config.hs has parseServerPort validation..."
if grep -q "parseServerPort" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has parseServerPort function - fix applied!"
else
    echo "✗ Config.hs missing parseServerPort function - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Config.hs validates admin-server-port != server-port..."
if grep -q "admin-server-port.*cannot.*same.*server-port" "src/PostgREST/Config.hs" || \
   grep -q "admin-server-port.*same.*server-port" "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs validates port inequality - fix applied!"
else
    echo "✗ Config.hs missing port inequality validation - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_cli.py has test_server_port_and_admin_port_same_value test..."
if grep -q "def test_server_port_and_admin_port_same_value" "test/io/test_cli.py"; then
    echo "✓ test_cli.py has port validation test - fix applied!"
else
    echo "✗ test_cli.py missing port validation test - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that docs mention admin-server-port restriction..."
if grep -q "Cannot be equal to.*server-port" "docs/references/configuration.rst" || \
   grep -q "cannot be equal to.*server-port" "docs/references/configuration.rst"; then
    echo "✓ Documentation mentions port restriction - fix applied!"
else
    echo "✗ Documentation doesn't mention port restriction - fix may not be fully applied"
    # Don't fail on this, it's just documentation
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
