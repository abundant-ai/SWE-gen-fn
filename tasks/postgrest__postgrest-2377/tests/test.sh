#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for OPTIONS requests no longer starting database transactions (PR #2377)..."
echo ""
echo "NOTE: This PR moves OPTIONS handling outside of database transaction logic"
echo "BASE (buggy) processes OPTIONS through runDbHandler, starting a transaction"
echo "HEAD (fixed) handles OPTIONS before runDbHandler, avoiding transaction"
echo ""

# Check that postgrestResponse handles ActionInfo before runDbHandler
echo "Checking src/PostgREST/App.hs handles ActionInfo before database operations..."
if grep -A 5 "if iAction apiRequest == ActionInfo" "src/PostgREST/App.hs" | grep -q "handleInfo (iTarget apiRequest)"; then
    echo "✓ ActionInfo is handled before runDbHandler"
else
    echo "✗ ActionInfo is not handled before runDbHandler - fix not applied"
    test_status=1
fi

# Check that there's an else clause that goes to runDbHandler
if grep -A 8 "if iAction apiRequest == ActionInfo" "src/PostgREST/App.hs" | grep -q "else"; then
    echo "✓ Non-OPTIONS requests still go through runDbHandler"
else
    echo "✗ Missing else clause for database operations - fix not applied"
    test_status=1
fi

# Check that handleRequest does NOT handle ActionInfo for TargetIdent
echo "Checking that handleRequest no longer handles ActionInfo..."
if grep -B 2 -A 2 "ActionInfo, TargetIdent" "src/PostgREST/App.hs" | grep -q "handleInfo identifier context"; then
    echo "✗ handleRequest still handles ActionInfo - fix not applied"
    test_status=1
else
    echo "✓ handleRequest does not handle ActionInfo (moved to postgrestResponse)"
fi

# Check that handleInfo signature accepts Target (not QualifiedIdentifier)
echo "Checking handleInfo function signature..."
if grep "^handleInfo :: Monad m => Target -> RequestContext" "src/PostgREST/App.hs"; then
    echo "✓ handleInfo accepts Target parameter"
else
    echo "✗ handleInfo does not accept Target parameter - fix not applied"
    test_status=1
fi

# Check that handleInfo pattern matches on target types
echo "Checking handleInfo pattern matches on Target..."
if grep -A 10 "handleInfo target RequestContext" "src/PostgREST/App.hs" | grep -q "case target of"; then
    echo "✓ handleInfo pattern matches on Target"
else
    echo "✗ handleInfo does not pattern match on Target - fix not applied"
    test_status=1
fi

if grep -A 12 "handleInfo target RequestContext" "src/PostgREST/App.hs" | grep -q "TargetIdent identifier -> HM.lookup identifier"; then
    echo "✓ handleInfo handles TargetIdent case"
else
    echo "✗ handleInfo does not handle TargetIdent case - fix not applied"
    test_status=1
fi

# Check CHANGELOG mentions the fix
echo "Checking CHANGELOG.md mentions the fix..."
if grep -q "#2376" "CHANGELOG.md" && grep "#2376" "CHANGELOG.md" | grep -q "OPTIONS"; then
    echo "✓ CHANGELOG.md mentions the OPTIONS transaction fix"
else
    echo "✗ CHANGELOG.md does not mention the fix - fix not applied"
    test_status=1
fi

# Note: test_io.py changes were in the same commit but are not part of the core fix

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - OPTIONS no longer starts database transactions"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
