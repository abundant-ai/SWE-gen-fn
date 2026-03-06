#!/bin/bash

cd /app/src

# Compare the actual file in the repo with the expected file in /tests/
# The expected file has the fix applied (IPv6 address handling)
# In BASE state: file has old IPv4-focused logic → diff will show differences → test fails
# After fix.patch: file should have IPv6 handling → diff shows no differences → test passes

test_status=0

echo "Comparing test/io/postgrest.py with expected version..."
if diff -q test/io/postgrest.py /tests/io/postgrest.py >/dev/null 2>&1; then
    echo "✓ test/io/postgrest.py matches expected version"
else
    echo "✗ test/io/postgrest.py differs from expected version"
    echo "Differences:"
    diff -u test/io/postgrest.py /tests/io/postgrest.py | head -50
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "Python test file matches expected version with IPv6 fix!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
