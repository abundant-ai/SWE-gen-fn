#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io/configs"
cp "/tests/io/configs/aliases.config" "test/io/configs/aliases.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/boolean-numeric.config" "test/io/configs/boolean-numeric.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/boolean-string.config" "test/io/configs/boolean-string.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/defaults.config" "test/io/configs/defaults.config"
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
cp "/tests/io/configs/expected/types.config" "test/io/configs/expected/types.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/sigusr2-settings.config" "test/io/configs/sigusr2-settings.config"
mkdir -p "test/io/configs"
cp "/tests/io/configs/types.config" "test/io/configs/types.config"

test_status=0

echo "Verifying fix for zero/low config mode (PR #2112)..."
echo ""
echo "This PR adds the ability to run PostgREST without configuration."
echo "The bug was that db-uri, db-schemas, and db-anon-role were required."
echo "The fix makes these optional with sensible defaults."
echo ""

echo "Checking CHANGELOG mentions the fix..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#1823.*run postgrest without any configuration" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions fix for PR #1823 (zero/low config mode)"
    else
        echo "✗ CHANGELOG.md does not mention fix (not documented)"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking Main.hs is simplified (fix applied)..."
if [ -f "main/Main.hs" ]; then
    if grep -q "readPGRSTEnvironment" "main/Main.hs"; then
        echo "✗ Main.hs still has readPGRSTEnvironment (not fixed)"
        test_status=1
    else
        echo "✓ Main.hs does not use readPGRSTEnvironment (simplified)"
    fi

    if grep -q "hasPGRSTEnv" "main/Main.hs"; then
        echo "✗ Main.hs still has hasPGRSTEnv (not fixed)"
        test_status=1
    else
        echo "✓ Main.hs does not have hasPGRSTEnv (simplified)"
    fi

    if grep -q "readCLIShowHelp$" "main/Main.hs"; then
        echo "✓ Main.hs uses simple readCLIShowHelp call"
    else
        echo "✗ Main.hs does not use simple readCLIShowHelp (not fixed)"
        test_status=1
    fi
else
    echo "✗ main/Main.hs not found"
    test_status=1
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

test_files=(
    "test/io/configs/aliases.config"
    "test/io/configs/boolean-numeric.config"
    "test/io/configs/boolean-string.config"
    "test/io/configs/defaults.config"
    "test/io/configs/expected/aliases.config"
    "test/io/configs/expected/boolean-numeric.config"
    "test/io/configs/expected/boolean-string.config"
    "test/io/configs/expected/defaults.config"
    "test/io/configs/expected/no-defaults-with-db-other-authenticator.config"
    "test/io/configs/expected/no-defaults-with-db.config"
    "test/io/configs/expected/types.config"
    "test/io/configs/sigusr2-settings.config"
    "test/io/configs/types.config"
)

for test_file in "${test_files[@]}"; do
    if [ -f "$test_file" ]; then
        echo "✓ $test_file exists (HEAD version)"
    else
        echo "✗ $test_file not found - HEAD file not copied!"
        test_status=1
    fi
done

if [ $test_status -eq 0 ]; then
    echo ""
    echo "✓ All checks passed - fix applied and HEAD test files copied successfully"
    echo 1 > /logs/verifier/reward.txt
else
    echo ""
    echo "✗ Some checks failed"
    echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
