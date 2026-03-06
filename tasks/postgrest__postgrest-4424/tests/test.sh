#!/bin/bash

cd /app/src

# Verify the configurator-pg dependency upgrade (the actual fix)
# In BASE state: configurator-pg >= 0.2 (old version without UTF-8 support)
# After fix: configurator-pg >= 0.2.11 (new version with UTF-8 support)

test_status=0

echo "Checking postgrest.cabal for configurator-pg version..."
if grep -q "configurator-pg.*>= 0.2.11" postgrest.cabal; then
    echo "✓ postgrest.cabal has configurator-pg >= 0.2.11 - fix is applied!"
else
    echo "✗ postgrest.cabal does not have configurator-pg >= 0.2.11 - fix not applied"
    echo "Current configurator-pg line:"
    grep "configurator-pg" postgrest.cabal || echo "(not found)"
    test_status=1
fi

echo "Checking stack.yaml for configurator-pg-0.2.11..."
if grep -q "configurator-pg-0.2.11" stack.yaml; then
    echo "✓ stack.yaml has configurator-pg-0.2.11 - fix is applied!"
else
    echo "✗ stack.yaml does not have configurator-pg-0.2.11 - fix not applied"
    echo "Current extra-deps:"
    grep -A5 "extra-deps:" stack.yaml || echo "(not found)"
    test_status=1
fi

echo "Checking CHANGELOG.md for fix entry..."
if grep -q "Fix loading utf-8 config files" CHANGELOG.md; then
    echo "✓ CHANGELOG.md has fix entry - fix is applied!"
else
    echo "✗ CHANGELOG.md does not have fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "All dependency upgrade checks passed - fix is applied!"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
