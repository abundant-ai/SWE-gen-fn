#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/RollbackSpec.hs" "test/Feature/RollbackSpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/privileges.sql" "test/fixtures/privileges.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

test_status=0

echo "Verifying fix for deferred constraint triggers with tx=rollback (PR #2053)..."
echo ""
echo "This PR ensures that deferred constraint triggers are executed when using Prefer: tx=rollback."
echo "The bug was that deferred constraints were not being triggered, allowing invalid data to be inserted."
echo "The fix adds 'SET CONSTRAINTS ALL IMMEDIATE' before rolling back the transaction."
echo ""

echo "Checking Middleware.hs has the fix applied..."
if [ -f "src/PostgREST/Middleware.hs" ]; then
    echo "✓ src/PostgREST/Middleware.hs exists"

    # After fix: should have BlockArguments language extension
    if grep -q "{-# LANGUAGE BlockArguments  #-}" "src/PostgREST/Middleware.hs"; then
        echo "✓ Middleware.hs has BlockArguments extension (fix applied)"
    else
        echo "✗ Middleware.hs missing BlockArguments extension (fix not applied)"
        test_status=1
    fi

    # After fix: should execute SET CONSTRAINTS ALL IMMEDIATE before condemn
    if grep -q "SQL.sql \"SET CONSTRAINTS ALL IMMEDIATE\"" "src/PostgREST/Middleware.hs"; then
        echo "✓ Middleware.hs executes SET CONSTRAINTS ALL IMMEDIATE (fix applied)"
    else
        echo "✗ Middleware.hs not executing SET CONSTRAINTS ALL IMMEDIATE (fix not applied)"
        test_status=1
    fi

    # After fix: should use 'lift do' block syntax
    if grep -A 1 "when (shouldRollback || (configDbTxRollbackAll && not shouldCommit))" "src/PostgREST/Middleware.hs" | grep -q "lift do"; then
        echo "✓ Middleware.hs uses 'lift do' block syntax (fix applied)"
    else
        echo "✗ Middleware.hs not using 'lift do' block syntax (fix not applied)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Middleware.hs not found"
    test_status=1
fi

echo ""
echo "Checking CHANGELOG.md has the fix documented..."
if [ -f "CHANGELOG.md" ]; then
    echo "✓ CHANGELOG.md exists"
    if grep -q "#2020, Execute deferred constraint triggers when using \`Prefer: tx=rollback\`" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md documents the fix (fix applied)"
    else
        echo "✗ CHANGELOG.md missing fix documentation (fix not applied)"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files have shouldRaiseExceptions tests..."

# RollbackSpec.hs should have shouldRaiseExceptions function
if [ -f "test/Feature/RollbackSpec.hs" ]; then
    echo "✓ test/Feature/RollbackSpec.hs exists (HEAD version)"

    if grep -q "shouldRaiseExceptions reqHeaders respHeaders = do" "test/Feature/RollbackSpec.hs"; then
        echo "✓ RollbackSpec.hs has shouldRaiseExceptions function (matches fixed code)"

        # Check it tests immediate constraints
        if grep -q "raises immediate constraints" "test/Feature/RollbackSpec.hs"; then
            echo "✓ RollbackSpec.hs tests immediate constraints"
        else
            echo "✗ RollbackSpec.hs missing immediate constraints test"
            test_status=1
        fi

        # Check it tests deferred constraints
        if grep -q "raises deferred constraints" "test/Feature/RollbackSpec.hs"; then
            echo "✓ RollbackSpec.hs tests deferred constraints"
        else
            echo "✗ RollbackSpec.hs missing deferred constraints test"
            test_status=1
        fi

        # Check it calls raise_constraint RPC
        if grep -q "/rpc/raise_constraint" "test/Feature/RollbackSpec.hs"; then
            echo "✓ RollbackSpec.hs tests raise_constraint RPC"
        else
            echo "✗ RollbackSpec.hs not testing raise_constraint RPC"
            test_status=1
        fi
    else
        echo "✗ RollbackSpec.hs missing shouldRaiseExceptions function"
        test_status=1
    fi
else
    echo "✗ test/Feature/RollbackSpec.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD schema.sql has deferrable_unique_constraint table..."
if [ -f "test/fixtures/schema.sql" ]; then
    echo "✓ test/fixtures/schema.sql exists (HEAD version)"

    if grep -q "CREATE TABLE deferrable_unique_constraint" "test/fixtures/schema.sql"; then
        echo "✓ schema.sql has deferrable_unique_constraint table (matches fixed code)"
    else
        echo "✗ schema.sql missing deferrable_unique_constraint table"
        test_status=1
    fi

    if grep -q "CREATE FUNCTION raise_constraint" "test/fixtures/schema.sql"; then
        echo "✓ schema.sql has raise_constraint function (matches fixed code)"
    else
        echo "✗ schema.sql missing raise_constraint function"
        test_status=1
    fi
else
    echo "✗ test/fixtures/schema.sql not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD privileges.sql grants access to new table..."
if [ -f "test/fixtures/privileges.sql" ]; then
    echo "✓ test/fixtures/privileges.sql exists (HEAD version)"

    if grep -q "deferrable_unique_constraint" "test/fixtures/privileges.sql"; then
        echo "✓ privileges.sql grants access to deferrable_unique_constraint (matches fixed code)"
    else
        echo "✗ privileges.sql not granting access to deferrable_unique_constraint"
        test_status=1
    fi
else
    echo "✗ test/fixtures/privileges.sql not found"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
