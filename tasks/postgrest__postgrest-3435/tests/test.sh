#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

# Check that LogDebug is added to LogLevel enum in Config.hs
echo "Checking that LogDebug is added to LogLevel enum..."
if grep -q "data LogLevel = LogCrit | LogError | LogWarn | LogInfo | LogDebug" "src/PostgREST/Config.hs"; then
    echo "✓ LogDebug added to LogLevel enum - fix applied!"
else
    echo "✗ LogDebug not found in LogLevel enum - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that 'debug' logging level is added to parser..."
if grep -q 'Just "debug" -> pure LogDebug' "src/PostgREST/Config.hs"; then
    echo "✓ 'debug' logging level added to parser - fix applied!"
else
    echo "✗ 'debug' not accepted in config parser - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that dumpLogLevel has LogDebug case..."
if grep -q 'LogDebug -> "debug"' "src/PostgREST/Config.hs"; then
    echo "✓ LogDebug case added to dumpLogLevel - fix applied!"
else
    echo "✗ LogDebug case not in dumpLogLevel - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs references LogDebug in middleware..."
if grep -q "LogDebug -> requestLogger (const True)" "src/PostgREST/Logger.hs"; then
    echo "✓ LogDebug added to Logger middleware - fix applied!"
else
    echo "✗ LogDebug not referenced in Logger.hs middleware - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Logger.hs has SchemaCacheLoadedObs with LogDebug..."
if grep -q "SchemaCacheLoadedObs" "src/PostgREST/Logger.hs"; then
    echo "✓ SchemaCacheLoadedObs handler added - fix applied!"
else
    echo "✗ SchemaCacheLoadedObs handler not found - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CLI help text mentions 'debug'..."
if grep -q 'crit, error, warn, info and debug' "src/PostgREST/CLI.hs"; then
    echo "✓ CLI help text updated to include 'debug' - fix applied!"
else
    echo "✗ CLI help doesn't mention 'debug' - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that test_io.py has 'debug' in parametrize..."
if grep -q '@pytest.mark.parametrize("level", \["crit", "error", "warn", "info", "debug"\])' "test/io/test_io.py"; then
    echo "✓ test_io.py updated to include 'debug' in parameters - fix applied!"
else
    echo "✗ test_io.py doesn't have 'debug' in test parameters - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that documentation mentions 'debug' log level..."
if grep -q 'log-level = "debug"' "docs/references/configuration.rst"; then
    echo "✓ Documentation updated to include debug log level - fix applied!"
else
    echo "✗ Documentation doesn't mention debug log level - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG mentions PR #3435..."
if grep -q "#3435" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions PR #3435 - fix applied!"
else
    echo "✗ CHANGELOG doesn't mention PR #3435 - fix may not be fully applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
