#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that CHANGELOG.md has the fix entries
echo "Checking that CHANGELOG.md has the fix entries..."
if grep -q "#3093, Nested empty embeds no longer show empty values and are correctly omitted" "CHANGELOG.md" && \
   grep -q "#3644, Make --dump-schema work with in-database pgrst.db_schemas setting" "CHANGELOG.md" && \
   grep -q "#3644, Show number of timezones in schema cache load report" "CHANGELOG.md" && \
   grep -q "#3644, List correct enum options in OpenApi output when multiple types with same name are present" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entries - fix applied!"
else
    echo "✗ CHANGELOG.md missing fix entries - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CLI.hs has the fix (reReadConfig before dumpSchema)..."
if grep -q "CmdDumpSchema -> do" "src/PostgREST/CLI.hs" && \
   grep -A 1 "CmdDumpSchema -> do" "src/PostgREST/CLI.hs" | grep -q "when configDbConfig.*reReadConfig"; then
    echo "✓ CLI.hs has reReadConfig before dumpSchema - fix applied!"
else
    echo "✗ CLI.hs missing reReadConfig - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Plan.hs has the fix (nested empty embeds logic)..."
if grep -q "hasOnlyNullEmbed" "src/PostgREST/Plan.hs"; then
    echo "✓ Plan.hs has hasOnlyNullEmbed logic - fix applied!"
else
    echo "✗ Plan.hs missing hasOnlyNullEmbed logic - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs has the fix (timezone count in summary)..."
if grep -q "show (S.size tzs)" "src/PostgREST/SchemaCache.hs" && \
   grep -q "Timezones" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs shows timezone count - fix applied!"
else
    echo "✗ SchemaCache.hs missing timezone count - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SchemaCache.hs has the fix (enum options with base_type)..."
if grep -q "COALESCE(bt.oid, t.oid) AS base_type" "src/PostgREST/SchemaCache.hs" && \
   grep -q "enum_info ON info.base_type = enum_info.enumtypid" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ SchemaCache.hs uses base_type for enum options - fix applied!"
else
    echo "✗ SchemaCache.hs doesn't use base_type - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that QuerySpec.hs has the nested empty embed tests..."
if grep -q "works on nested relationships" "test/spec/Feature/Query/QuerySpec.hs" && \
   grep -q "users_tasks(tasks(projects()))" "test/spec/Feature/Query/QuerySpec.hs"; then
    echo "✓ QuerySpec.hs has nested empty embed tests - fix applied!"
else
    echo "✗ QuerySpec.hs missing nested empty embed tests - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
