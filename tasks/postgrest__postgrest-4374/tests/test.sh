#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/aliases.config" "test/io/configs/expected/aliases.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-numeric.config" "test/io/configs/expected/boolean-numeric.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/boolean-string.config" "test/io/configs/expected/boolean-string.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/defaults.config" "test/io/configs/expected/defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key1.config" "test/io/configs/expected/jwt-role-claim-key1.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key2.config" "test/io/configs/expected/jwt-role-claim-key2.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key3.config" "test/io/configs/expected/jwt-role-claim-key3.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key4.config" "test/io/configs/expected/jwt-role-claim-key4.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/jwt-role-claim-key5.config" "test/io/configs/expected/jwt-role-claim-key5.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults-with-db.config" "test/io/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/no-defaults.config" "test/io/configs/expected/no-defaults.config"
mkdir -p "test/io/configs/expected"
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults-env.yaml" "test/io/configs/no-defaults-env.yaml"
mkdir -p "test/io/configs"
cp "/tests/io/configs/no-defaults.config" "test/io/configs/no-defaults.config"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify the fix for changing log-query from string to boolean
# In BASE state: log-query is a string value like "disabled"
# After fix: log-query is a boolean value (false)

test_status=0

echo "Checking test/io/configs/expected/defaults.config has log-query = false (boolean)..."
if grep -q "^log-query = false$" "test/io/configs/expected/defaults.config"; then
    echo "✓ defaults.config has log-query = false - fix is applied!"
else
    echo "✗ defaults.config does not have log-query = false - fix not applied"
    echo "Current log-query line:"
    grep "log-query" test/io/configs/expected/defaults.config || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking test/io/configs/expected/aliases.config has log-query = false (boolean)..."
if grep -q "^log-query = false$" "test/io/configs/expected/aliases.config"; then
    echo "✓ aliases.config has log-query = false - fix is applied!"
else
    echo "✗ aliases.config does not have log-query = false - fix not applied"
    echo "Current log-query line:"
    grep "log-query" test/io/configs/expected/aliases.config || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking test/io/configs/expected/no-defaults-with-db-other-authenticator.config has log-query = true (boolean)..."
if grep -q "^log-query = true$" "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"; then
    echo "✓ no-defaults-with-db-other-authenticator.config has log-query = true - fix is applied!"
else
    echo "✗ no-defaults-with-db-other-authenticator.config does not have log-query = true - fix not applied"
    echo "Current log-query line:"
    grep "log-query" test/io/configs/expected/no-defaults-with-db-other-authenticator.config || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking docs/references/configuration.rst has Type: Boolean..."
if grep -A 5 "^log-query" docs/references/configuration.rst | grep -q "**Type**.*Boolean"; then
    echo "✓ configuration.rst has log-query Type: Boolean - fix is applied!"
else
    echo "✗ configuration.rst does not have log-query Type: Boolean - fix not applied"
    echo "Current Type line:"
    grep -A 5 "^log-query" docs/references/configuration.rst | grep "**Type**" || echo "(not found)"
    test_status=1
fi

echo ""
echo "Checking CHANGELOG.md mentions log-query boolean change..."
if grep -q "log-query.*boolean" CHANGELOG.md; then
    echo "✓ CHANGELOG.md mentions log-query boolean change - fix is applied!"
else
    echo "✗ CHANGELOG.md does not mention log-query boolean change - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
