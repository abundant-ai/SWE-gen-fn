#!/bin/bash

cd /app/src

export CI=true

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
cp "/tests/io/db_config.sql" "test/io/db_config.sql"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/ObservabilitySpec.hs" "test/spec/Feature/ObservabilitySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for server-trace-header feature..."
echo ""
echo "NOTE: This PR ADDS server-trace-header configuration option and middleware."
echo "HEAD should have CHANGELOG entry, Config fields, and traceHeaderMiddleware."
echo ""

# Check CHANGELOG.md - HEAD should have the PR #2506 entry (bug.patch removes it)
echo "Checking CHANGELOG.md has PR #2506 entry..."
if grep -q "#2506, Add \`server-trace-header\` for tracing HTTP requests" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has PR #2506 entry"
else
    echo "✗ CHANGELOG.md missing PR #2506 entry - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should have configServerTraceHeader field (bug.patch removes it)
echo "Checking src/PostgREST/Config.hs should have configServerTraceHeader..."
if grep -q "configServerTraceHeader" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has configServerTraceHeader field"
else
    echo "✗ src/PostgREST/Config.hs missing configServerTraceHeader - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should parse server-trace-header option (bug.patch removes it)
echo "Checking src/PostgREST/Config.hs should parse server-trace-header..."
if grep -q 'optString "server-trace-header"' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs parses server-trace-header option"
else
    echo "✗ src/PostgREST/Config.hs missing server-trace-header parsing - fix not applied"
    test_status=1
fi

# Check Config.hs - HEAD should output server-trace-header in toText (bug.patch removes it)
echo "Checking src/PostgREST/Config.hs should output server-trace-header..."
if grep -q 'server-trace-header' "src/PostgREST/Config.hs" && grep -q 'configServerTraceHeader' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs outputs server-trace-header in config"
else
    echo "✗ src/PostgREST/Config.hs missing server-trace-header output - fix not applied"
    test_status=1
fi

# Check Response.hs - HEAD should have traceHeaderMiddleware (bug.patch removes it)
echo "Checking src/PostgREST/Response.hs should have traceHeaderMiddleware..."
if grep -q "traceHeaderMiddleware" "src/PostgREST/Response.hs"; then
    echo "✓ src/PostgREST/Response.hs has traceHeaderMiddleware function"
else
    echo "✗ src/PostgREST/Response.hs missing traceHeaderMiddleware - fix not applied"
    test_status=1
fi

# Check Response.hs - traceHeaderMiddleware should use configServerTraceHeader
echo "Checking traceHeaderMiddleware implementation..."
if grep -q "configServerTraceHeader" "src/PostgREST/Response.hs"; then
    echo "✓ traceHeaderMiddleware uses configServerTraceHeader"
else
    echo "✗ traceHeaderMiddleware missing configServerTraceHeader usage - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs - HEAD should have testObservabilityCfg (bug.patch removes it)
echo "Checking test/spec/SpecHelper.hs should have testObservabilityCfg..."
if grep -q "testObservabilityCfg" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs has testObservabilityCfg"
else
    echo "✗ test/spec/SpecHelper.hs missing testObservabilityCfg - fix not applied"
    test_status=1
fi

# Check postgrest.cabal - HEAD should include Feature.ObservabilitySpec (bug.patch removes it)
echo "Checking postgrest.cabal should include Feature.ObservabilitySpec..."
if grep -q "Feature.ObservabilitySpec" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes Feature.ObservabilitySpec"
else
    echo "✗ postgrest.cabal missing Feature.ObservabilitySpec - fix not applied"
    test_status=1
fi

# Check config files have server-trace-header = "" default
echo "Checking config test files have server-trace-header..."
if grep -q 'server-trace-header = ""' "test/io/configs/expected/defaults.config"; then
    echo "✓ Config test files include server-trace-header"
else
    echo "✗ Config test files missing server-trace-header - fix not applied"
    test_status=1
fi

# Check ObservabilitySpec.hs test file exists and has server trace tests
echo "Checking test/spec/Feature/ObservabilitySpec.hs has trace header tests..."
if [ -f "test/spec/Feature/ObservabilitySpec.hs" ]; then
    if grep -q "X-Request-Id" "test/spec/Feature/ObservabilitySpec.hs"; then
        echo "✓ test/spec/Feature/ObservabilitySpec.hs has trace header tests"
    else
        echo "✗ test/spec/Feature/ObservabilitySpec.hs missing trace header tests - fix not applied"
        test_status=1
    fi
else
    echo "✗ test/spec/Feature/ObservabilitySpec.hs file missing - fix not applied"
    test_status=1
fi

echo ""
if [ $test_status -eq 0 ]; then
    echo "✓ All checks passed - server-trace-header feature properly implemented"
    echo 1 > /logs/verifier/reward.txt
else
    echo "✗ Some checks failed - fix not fully applied"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
