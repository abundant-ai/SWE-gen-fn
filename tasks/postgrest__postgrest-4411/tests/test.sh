#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/conftest.py" "test/io/conftest.py"
mkdir -p "test/io"
cp "/tests/io/test_big_schema.py" "test/io/test_big_schema.py"
mkdir -p "test/io"
cp "/tests/io/test_cli.py" "test/io/test_cli.py"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify the code changes for the fix to internal schema cache sleep configs
# In BASE state: uses single configInternalSCSleep
# After fix: uses three separate configs (configInternalSCQuerySleep, configInternalSCLoadSleep, configInternalSCRelLoadSleep)

test_status=0

echo "Checking src/PostgREST/Config.hs for three separate internal schema cache sleep configs..."
if grep -q "configInternalSCQuerySleep" src/PostgREST/Config.hs && \
   grep -q "configInternalSCLoadSleep" src/PostgREST/Config.hs && \
   grep -q "configInternalSCRelLoadSleep" src/PostgREST/Config.hs; then
    echo "✓ Config.hs has three separate internal schema cache sleep configs - fix is applied!"
else
    echo "✗ Config.hs does not have three separate configs - fix not applied"
    echo "Current config fields:"
    grep "configInternalSC" src/PostgREST/Config.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/Config.hs parser for three separate config options..."
if grep -q '"internal-schema-cache-query-sleep"' src/PostgREST/Config.hs && \
   grep -q '"internal-schema-cache-load-sleep"' src/PostgREST/Config.hs && \
   grep -q '"internal-schema-cache-relationship-load-sleep"' src/PostgREST/Config.hs; then
    echo "✓ Config.hs parses three separate config options - fix is applied!"
else
    echo "✗ Config.hs does not parse three separate config options - fix not applied"
    echo "Current config parser:"
    grep "internal-schema-cache" src/PostgREST/Config.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs uses for_ instead of whenJust..."
if grep -q "for_ configInternalSCQuerySleep" src/PostgREST/SchemaCache.hs; then
    echo "✓ SchemaCache.hs uses for_ with configInternalSCQuerySleep - fix is applied!"
else
    echo "✗ SchemaCache.hs does not use for_ with configInternalSCQuerySleep - fix not applied"
    echo "Current sleep call usage:"
    grep -A2 "sleepCall" src/PostgREST/SchemaCache.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs has delayEval for loading and relationship delays..."
if grep -q "delayEval configInternalSCLoadSleep" src/PostgREST/SchemaCache.hs && \
   grep -q "delayEval configInternalSCRelLoadSleep" src/PostgREST/SchemaCache.hs; then
    echo "✓ SchemaCache.hs has delayEval for both load and relationship delays - fix is applied!"
else
    echo "✗ SchemaCache.hs does not have delayEval for both delays - fix not applied"
    echo "Current delayEval usage:"
    grep "delayEval" src/PostgREST/SchemaCache.hs || echo "(not found)"
    test_status=1
fi

echo "Checking src/PostgREST/SchemaCache.hs imports System.IO.Unsafe..."
if head -100 src/PostgREST/SchemaCache.hs | grep -q "import System.IO.Unsafe"; then
    echo "✓ SchemaCache.hs imports System.IO.Unsafe - fix is applied!"
else
    echo "✗ SchemaCache.hs does not import System.IO.Unsafe - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
    echo "All code change checks passed - fix is applied!"
    echo 1 > /logs/verifier/reward.txt
else
    echo "Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
