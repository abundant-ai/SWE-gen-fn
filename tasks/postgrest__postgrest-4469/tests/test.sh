#!/bin/bash

cd /app/src

# Compare the actual files in the repo with the expected files in /tests/
# The expected files have the fix applied (short script names)
# In BASE state: files have long names → diff will show differences → test fails
# After fix.patch: files should have short names → diff shows no differences → test passes

test_status=0

echo "Comparing test/io/big_schema.sql with expected version..."
if diff -q test/io/big_schema.sql /tests/io/big_schema.sql >/dev/null 2>&1; then
    echo "✓ test/io/big_schema.sql matches expected version"
else
    echo "✗ test/io/big_schema.sql differs from expected version"
    echo "Differences:"
    diff -u test/io/big_schema.sql /tests/io/big_schema.sql | head -30
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "Comparing test/pgbench/README.md with expected version..."
    if diff -q test/pgbench/README.md /tests/pgbench/README.md >/dev/null 2>&1; then
        echo "✓ test/pgbench/README.md matches expected version"
    else
        echo "✗ test/pgbench/README.md differs from expected version"
        echo "Differences:"
        diff -u test/pgbench/README.md /tests/pgbench/README.md
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "All documentation files match expected versions!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
