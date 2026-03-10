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
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Verify that the fix has been applied by checking source code changes
test_status=0

echo "Verifying fix has been applied..."
echo ""

# Check Config.hs for server-timing-enabled field in AppConfig
echo "Checking Config.hs for configServerTimingEnabled field..."
if grep -q 'configServerTimingEnabled' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has configServerTimingEnabled field"
else
    echo "✗ Config.hs missing configServerTimingEnabled field - fix not applied"
    test_status=1
fi

# Check Config.hs for server-timing-enabled in toText function
echo "Checking Config.hs for server-timing-enabled in config output..."
if grep -q 'server-timing-enabled' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has server-timing-enabled in toText"
else
    echo "✗ Config.hs missing server-timing-enabled in toText - fix not applied"
    test_status=1
fi

# Check Config.hs parser for server-timing-enabled option
echo "Checking Config.hs for server-timing-enabled parser..."
if grep -q 'optBool "server-timing-enabled"' "src/PostgREST/Config.hs"; then
    echo "✓ Config.hs has server-timing-enabled parser"
else
    echo "✗ Config.hs missing server-timing-enabled parser - fix not applied"
    test_status=1
fi

# Check Config/Database.hs for server_timing_enabled in dbSettingsNames
echo "Checking Config/Database.hs for server_timing_enabled..."
if grep -q '"server_timing_enabled"' "src/PostgREST/Config/Database.hs"; then
    echo "✓ Config/Database.hs has server_timing_enabled in dbSettingsNames"
else
    echo "✗ Config/Database.hs missing server_timing_enabled - fix not applied"
    test_status=1
fi

# Check App.hs uses configServerTimingEnabled for JWT timing
echo "Checking App.hs for configServerTimingEnabled in JWT timing..."
if grep -q 'if configServerTimingEnabled then Auth.getJwtDur req' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses configServerTimingEnabled for JWT timing"
else
    echo "✗ App.hs not using configServerTimingEnabled for JWT timing - fix not applied"
    test_status=1
fi

# Check App.hs uses configServerTimingEnabled for rendering server timing header
echo "Checking App.hs for configServerTimingEnabled in response header..."
if grep -q 'renderServerTimingHeader timings | configServerTimingEnabled conf' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses configServerTimingEnabled for response header"
else
    echo "✗ App.hs not using configServerTimingEnabled for response header - fix not applied"
    test_status=1
fi

# Check App.hs uses configServerTimingEnabled in withTiming
echo "Checking App.hs for configServerTimingEnabled in withTiming..."
if grep -q 'if configServerTimingEnabled conf' "src/PostgREST/App.hs"; then
    echo "✓ App.hs uses configServerTimingEnabled in withTiming"
else
    echo "✗ App.hs not using configServerTimingEnabled in withTiming - fix not applied"
    test_status=1
fi

# Check Auth.hs uses configServerTimingEnabled
echo "Checking Auth.hs for configServerTimingEnabled..."
if grep -q 'configServerTimingEnabled conf' "src/PostgREST/Auth.hs"; then
    echo "✓ Auth.hs uses configServerTimingEnabled"
else
    echo "✗ Auth.hs not using configServerTimingEnabled - fix not applied"
    test_status=1
fi

# Check config files have server-timing-enabled = false by default
echo "Checking default config files for server-timing-enabled = false..."
if grep -q 'server-timing-enabled = false' "test/io/configs/expected/defaults.config"; then
    echo "✓ defaults.config has server-timing-enabled = false"
else
    echo "✗ defaults.config missing server-timing-enabled = false - fix not applied"
    test_status=1
fi

# Check config file with server-timing-enabled = true
echo "Checking no-defaults-with-db-other-authenticator.config for server-timing-enabled = true..."
if grep -q 'server-timing-enabled = true' "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"; then
    echo "✓ no-defaults-with-db-other-authenticator.config has server-timing-enabled = true"
else
    echo "✗ no-defaults-with-db-other-authenticator.config missing server-timing-enabled = true - fix not applied"
    test_status=1
fi

# Check CHANGELOG mentions the feature
echo "Checking CHANGELOG for server-timing-enabled feature..."
if grep -q '#3062.*Server-Timing' "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions Server-Timing config feature"
else
    echo "✗ CHANGELOG missing Server-Timing config feature - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
