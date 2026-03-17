#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/SpecHelper.hs" "test/SpecHelper.hs"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/aliases.config" "test/io-tests/configs/expected/aliases.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-numeric.config" "test/io-tests/configs/expected/boolean-numeric.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/boolean-string.config" "test/io-tests/configs/expected/boolean-string.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/defaults.config" "test/io-tests/configs/expected/defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config" "test/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults-with-db.config" "test/io-tests/configs/expected/no-defaults-with-db.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/no-defaults.config" "test/io-tests/configs/expected/no-defaults.config"
mkdir -p "test/io-tests/configs/expected"
cp "/tests/io-tests/configs/expected/types.config" "test/io-tests/configs/expected/types.config"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults-env.yaml" "test/io-tests/configs/no-defaults-env.yaml"
mkdir -p "test/io-tests/configs"
cp "/tests/io-tests/configs/no-defaults.config" "test/io-tests/configs/no-defaults.config"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

test_status=0

echo "Verifying fix for admin health check endpoint (PR #2092)..."
echo ""
echo "This PR adds a minimal health check endpoint on an admin port."
echo "The bug was the absence of this feature - the fix adds admin-server-port config and /health endpoint."
echo ""

echo "Checking CHANGELOG mentions PR #1933..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#1933" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions PR #1933 (feature documented)"
    else
        echo "✗ CHANGELOG.md does not mention PR #1933 (missing documentation)"
        test_status=1
    fi

    if grep -q "admin-server-port" "CHANGELOG.md" || grep -q "health check" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md describes the health check feature"
    else
        echo "✗ CHANGELOG.md missing health check description"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking App.hs has postgrestAdmin function..."
if [ -f "src/PostgREST/App.hs" ]; then
    echo "✓ src/PostgREST/App.hs exists"

    if grep -q "postgrestAdmin" "src/PostgREST/App.hs"; then
        echo "✓ App.hs has postgrestAdmin function (admin server implemented)"
    else
        echo "✗ App.hs missing postgrestAdmin function (fix not applied)"
        test_status=1
    fi

    if grep -q "/health" "src/PostgREST/App.hs" || grep -q "health" "src/PostgREST/App.hs"; then
        echo "✓ App.hs implements /health endpoint"
    else
        echo "✗ App.hs missing /health endpoint (fix not applied)"
        test_status=1
    fi

    if grep -q "configAdminServerPort" "src/PostgREST/App.hs"; then
        echo "✓ App.hs uses configAdminServerPort config option"
    else
        echo "✗ App.hs missing configAdminServerPort usage"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking AppState.hs has getIsListenerOn function..."
if [ -f "src/PostgREST/AppState.hs" ]; then
    echo "✓ src/PostgREST/AppState.hs exists"

    if grep -q "getIsListenerOn" "src/PostgREST/AppState.hs"; then
        echo "✓ AppState.hs has getIsListenerOn function (listener state tracking implemented)"
    else
        echo "✗ AppState.hs missing getIsListenerOn function (fix not applied)"
        test_status=1
    fi

    if grep -q "putIsListenerOn" "src/PostgREST/AppState.hs"; then
        echo "✓ AppState.hs has putIsListenerOn function"
    else
        echo "✗ AppState.hs missing putIsListenerOn function"
        test_status=1
    fi

    if grep -q "stateIsListenerOn" "src/PostgREST/AppState.hs"; then
        echo "✓ AppState.hs has stateIsListenerOn state field"
    else
        echo "✗ AppState.hs missing stateIsListenerOn field"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/AppState.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files were copied correctly..."
if [ -f "test/SpecHelper.hs" ]; then
    echo "✓ test/SpecHelper.hs exists (HEAD version)"
else
    echo "✗ test/SpecHelper.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/io-tests/test_io.py" ]; then
    echo "✓ test/io-tests/test_io.py exists (HEAD version)"
else
    echo "✗ test/io-tests/test_io.py not found - HEAD file not copied!"
    test_status=1
fi

# Check config files
config_files=(
    "test/io-tests/configs/expected/aliases.config"
    "test/io-tests/configs/expected/boolean-numeric.config"
    "test/io-tests/configs/expected/boolean-string.config"
    "test/io-tests/configs/expected/defaults.config"
    "test/io-tests/configs/expected/no-defaults-with-db-other-authenticator.config"
    "test/io-tests/configs/expected/no-defaults-with-db.config"
    "test/io-tests/configs/expected/no-defaults.config"
    "test/io-tests/configs/expected/types.config"
    "test/io-tests/configs/no-defaults-env.yaml"
    "test/io-tests/configs/no-defaults.config"
)

for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ]; then
        echo "✓ $config_file exists"
    else
        echo "✗ $config_file not found - HEAD file not copied!"
        test_status=1
    fi
done

# Check that at least one config file mentions admin-server-port
admin_config_found=false
for config_file in "${config_files[@]}"; do
    if [ -f "$config_file" ] && grep -q "admin-server-port" "$config_file"; then
        echo "✓ Found admin-server-port in $config_file (new config option present)"
        admin_config_found=true
        break
    fi
done

if [ "$admin_config_found" = false ]; then
    echo "✗ No config file contains admin-server-port (new config option missing)"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
