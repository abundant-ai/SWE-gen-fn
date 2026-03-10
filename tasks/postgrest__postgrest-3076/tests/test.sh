#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/CustomMediaSpec.hs" "test/spec/Feature/Query/CustomMediaSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify that the fix has been applied by checking test file and source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check Plan.hs for MediaHandlerMap import
echo "Checking Plan.hs for MediaHandlerMap import..."
if grep -q "MediaHandlerMap," "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has MediaHandlerMap import"
else
    echo "✗ Plan.hs missing MediaHandlerMap import - fix not applied"
    test_status=1
fi

# Check Plan.hs for MediaHandlerMap in negotiateContent signature
echo "Checking Plan.hs for MediaHandlerMap in negotiateContent signature..."
if grep -q "MediaHandlerMap -> Either ApiRequestError" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has MediaHandlerMap in negotiateContent signature"
else
    echo "✗ Plan.hs missing MediaHandlerMap in negotiateContent signature - fix not applied"
    test_status=1
fi

# Check Plan.hs for defaultMTAnyToMTJSON
echo "Checking Plan.hs for defaultMTAnyToMTJSON..."
if grep -q "defaultMTAnyToMTJSON" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has defaultMTAnyToMTJSON"
else
    echo "✗ Plan.hs missing defaultMTAnyToMTJSON - fix not applied"
    test_status=1
fi

# Check Plan.hs for matchMT function
echo "Checking Plan.hs for matchMT function..."
if grep -q "matchMT mt = case mt of" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has matchMT function"
else
    echo "✗ Plan.hs missing matchMT function - fix not applied"
    test_status=1
fi

# Check Plan.hs for lookupHandler function with MTAny support
echo "Checking Plan.hs for lookupHandler function..."
if grep -q "lookupHandler mt =" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has lookupHandler function"
else
    echo "✗ Plan.hs missing lookupHandler function - fix not applied"
    test_status=1
fi

# Check Plan.hs for MTAny lookup in lookupHandler
echo "Checking Plan.hs for MTAny lookup in lookupHandler..."
if grep -q "HM.lookup (RelId identifier, MTAny) produces" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has MTAny lookup in lookupHandler"
else
    echo "✗ Plan.hs missing MTAny lookup in lookupHandler - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs for */* media type support
echo "Checking SchemaCache.hs for */* media type support..."
if grep -q "or t.typname = '\*\/\*'" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs has */* media type support"
else
    echo "✗ SchemaCache.hs missing */* media type support - fix not applied"
    test_status=1
fi

# Check CustomMediaSpec.hs for "any media type" context
echo "Checking CustomMediaSpec.hs for 'any media type' context..."
if grep -q 'context "any media type"' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has 'any media type' context"
else
    echo "✗ CustomMediaSpec.hs missing 'any media type' context - fix not applied"
    test_status=1
fi

# Check CustomMediaSpec.hs for ret_any_mt test
echo "Checking CustomMediaSpec.hs for ret_any_mt test..."
if grep -q 'ret_any_mt' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has ret_any_mt test"
else
    echo "✗ CustomMediaSpec.hs missing ret_any_mt test - fix not applied"
    test_status=1
fi

# Check CustomMediaSpec.hs for ret_some_mt test
echo "Checking CustomMediaSpec.hs for ret_some_mt test..."
if grep -q 'ret_some_mt' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has ret_some_mt test"
else
    echo "✗ CustomMediaSpec.hs missing ret_some_mt test - fix not applied"
    test_status=1
fi

# Check CustomMediaSpec.hs for some_numbers test
echo "Checking CustomMediaSpec.hs for some_numbers table test..."
if grep -q 'some_numbers' "test/spec/Feature/Query/CustomMediaSpec.hs"; then
    echo "✓ CustomMediaSpec.hs has some_numbers table test"
else
    echo "✗ CustomMediaSpec.hs missing some_numbers table test - fix not applied"
    test_status=1
fi

# Check schema.sql for */* domain
echo "Checking schema.sql for */* domain..."
if grep -q 'create domain "\*\/\*" as bytea' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has */* domain"
else
    echo "✗ schema.sql missing */* domain - fix not applied"
    test_status=1
fi

# Check schema.sql for ret_any_mt function
echo "Checking schema.sql for ret_any_mt function..."
if grep -q 'create or replace function ret_any_mt' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has ret_any_mt function"
else
    echo "✗ schema.sql missing ret_any_mt function - fix not applied"
    test_status=1
fi

# Check schema.sql for ret_some_mt function
echo "Checking schema.sql for ret_some_mt function..."
if grep -q 'create or replace function ret_some_mt' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has ret_some_mt function"
else
    echo "✗ schema.sql missing ret_some_mt function - fix not applied"
    test_status=1
fi

# Check schema.sql for some_numbers table
echo "Checking schema.sql for some_numbers table..."
if grep -q 'create table some_numbers' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has some_numbers table"
else
    echo "✗ schema.sql missing some_numbers table - fix not applied"
    test_status=1
fi

# Check schema.sql for some_agg aggregate
echo "Checking schema.sql for some_agg aggregate..."
if grep -q 'create aggregate test.some_agg' "test/spec/fixtures/schema.sql"; then
    echo "✓ schema.sql has some_agg aggregate"
else
    echo "✗ schema.sql missing some_agg aggregate - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
