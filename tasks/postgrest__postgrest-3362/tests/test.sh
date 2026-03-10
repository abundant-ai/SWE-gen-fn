#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied to source code..."
echo ""

# Check that CHANGELOG.md has the entry for #3361
echo "Checking that CHANGELOG.md has entry for #3361..."
if grep -q "#3361, Clarify PGRST204(column not found) error message" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has entry for #3361"
else
    echo "✗ CHANGELOG.md missing entry for #3361 - fix not applied"
    test_status=1
fi

# Check that docs/references/errors.rst has the correct schema_cache reference
echo "Checking that docs/references/errors.rst has correct reference..."
if grep -q "Related to a :ref:\`schema_cache\`. Most of the time, these errors are solved by :ref:\`schema_reloading\`." "docs/references/errors.rst"; then
    echo "✓ docs/references/errors.rst has correct reference"
else
    echo "✗ docs/references/errors.rst has incorrect reference - fix not applied"
    test_status=1
fi

# Check that docs/references/schema_cache.rst does NOT have "stale_schema" anchor
echo "Checking that docs/references/schema_cache.rst does NOT have stale_schema anchor..."
if grep -q ".. _stale_schema:" "docs/references/schema_cache.rst"; then
    echo "✗ docs/references/schema_cache.rst still has stale_schema anchor - fix not applied"
    test_status=1
else
    echo "✓ docs/references/schema_cache.rst does not have stale_schema anchor (correctly removed)"
fi

# Check that docs/references/schema_cache.rst has original intro
echo "Checking that docs/references/schema_cache.rst has original intro..."
if grep -q "PostgREST requires metadata from the database schema to provide a REST API that abstracts SQL details" "docs/references/schema_cache.rst"; then
    echo "✓ docs/references/schema_cache.rst has original intro"
else
    echo "✗ docs/references/schema_cache.rst missing original intro - fix not applied"
    test_status=1
fi

# Check that docs/references/schema_cache.rst has schema_reloading_signals anchor
echo "Checking that docs/references/schema_cache.rst has schema_reloading_signals anchor..."
if grep -q ".. _schema_reloading_signals:" "docs/references/schema_cache.rst"; then
    echo "✓ docs/references/schema_cache.rst has schema_reloading_signals anchor"
else
    echo "✗ docs/references/schema_cache.rst missing schema_reloading_signals anchor - fix not applied"
    test_status=1
fi

# Check that src/PostgREST/Error.hs has the correct error message
echo "Checking that src/PostgREST/Error.hs has correct error message..."
if grep -q "Could not find the '" "src/PostgREST/Error.hs" && grep -q "' column of '" "src/PostgREST/Error.hs" && grep -q "' in the schema cache" "src/PostgREST/Error.hs"; then
    echo "✓ src/PostgREST/Error.hs has correct error message"
else
    echo "✗ src/PostgREST/Error.hs missing correct error message - fix not applied"
    test_status=1
fi

# Check that test/spec/Feature/Query/InsertSpec.hs has the correct error messages
echo "Checking that test/spec/Feature/Query/InsertSpec.hs has correct error messages..."
if grep -q "Could not find the 'helicopter' column of 'articles' in the schema cache" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/InsertSpec.hs has correct error message (line 472)"
else
    echo "✗ test/spec/Feature/Query/InsertSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

if grep -q "Could not find the 'helicopters' column of 'datarep_todos' in the schema cache" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/InsertSpec.hs has correct error message (line 854)"
else
    echo "✗ test/spec/Feature/Query/InsertSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

if grep -q "Could not find the 'helicopters' column of 'datarep_todos_computed' in the schema cache" "test/spec/Feature/Query/InsertSpec.hs"; then
    echo "✓ test/spec/Feature/Query/InsertSpec.hs has correct error message (line 909)"
else
    echo "✗ test/spec/Feature/Query/InsertSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

# Check that test/spec/Feature/Query/UpdateSpec.hs has the correct error messages
echo "Checking that test/spec/Feature/Query/UpdateSpec.hs has correct error messages..."
if grep -q "Could not find the 'helicopter' column of 'articles' in the schema cache" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpdateSpec.hs has correct error message (line 345)"
else
    echo "✗ test/spec/Feature/Query/UpdateSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

if grep -q "Could not find the 'helicopters' column of 'datarep_todos' in the schema cache" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpdateSpec.hs has correct error message (line 891)"
else
    echo "✗ test/spec/Feature/Query/UpdateSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

if grep -q "Could not find the 'helicopters' column of 'datarep_todos_computed' in the schema cache" "test/spec/Feature/Query/UpdateSpec.hs"; then
    echo "✓ test/spec/Feature/Query/UpdateSpec.hs has correct error message (line 981)"
else
    echo "✗ test/spec/Feature/Query/UpdateSpec.hs missing correct error message - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
