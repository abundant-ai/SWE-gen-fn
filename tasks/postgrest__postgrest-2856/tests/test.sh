#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.yaml" "test/io/fixtures.yaml"

test_status=0

echo "Verifying fix for --version CLI option (PR #2856)..."
echo ""
echo "NOTE: This PR adds --version/-v CLI option to print version information"
echo "BASE (buggy) does not have versionFlag parser"
echo "HEAD (fixed) has versionFlag parser that handles --version/-v"
echo ""

# Check that CLI.hs has the versionFlag function
echo "Checking src/PostgREST/CLI.hs has versionFlag function..."
if grep -q "versionFlag =" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs has versionFlag function"
else
    echo "✗ CLI.hs does not have versionFlag function - fix not applied"
    test_status=1
fi

# Check that the parser includes versionFlag
echo "Checking CLI.hs parser includes versionFlag..."
if grep -q "parser = O.helper <\*> versionFlag <\*> exampleParser <\*> cliParser" "src/PostgREST/CLI.hs"; then
    echo "✓ CLI.hs parser includes versionFlag"
else
    echo "✗ CLI.hs parser does not include versionFlag - fix not applied"
    test_status=1
fi

# Check that versionFlag has --version long option
echo "Checking versionFlag has --version long option..."
if grep -A 3 "versionFlag =" "src/PostgREST/CLI.hs" | grep -q 'O.long "version"'; then
    echo "✓ versionFlag has --version long option"
else
    echo "✗ versionFlag does not have --version long option - fix not applied"
    test_status=1
fi

# Check that versionFlag has -v short option
echo "Checking versionFlag has -v short option..."
if grep -A 3 "versionFlag =" "src/PostgREST/CLI.hs" | grep -q "O.short 'v'"; then
    echo "✓ versionFlag has -v short option"
else
    echo "✗ versionFlag does not have -v short option - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md mentions the fix
echo "Checking CHANGELOG.md mentions the --version CLI option..."
if grep -q "#2856, Add the \`--version\` CLI option that prints the version information" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions --version CLI option"
else
    echo "✗ CHANGELOG.md does not mention --version CLI option - fix not fully applied"
    test_status=1
fi

# Verify the test file has the version test cases
echo "Checking test/io/fixtures.yaml has version test cases..."
if grep -q "name: version long" "test/io/fixtures.yaml"; then
    echo "✓ fixtures.yaml has 'version long' test case"
else
    echo "✗ fixtures.yaml does not have 'version long' test case - fix not applied"
    test_status=1
fi

if grep -q "name: version short" "test/io/fixtures.yaml"; then
    echo "✓ fixtures.yaml has 'version short' test case"
else
    echo "✗ fixtures.yaml does not have 'version short' test case - fix not applied"
    test_status=1
fi

# Check that the version test cases have the correct args
echo "Checking test/io/fixtures.yaml has correct args for version tests..."
if grep -A 1 "name: version long" "test/io/fixtures.yaml" | grep -q "args: \['--version'\]"; then
    echo "✓ fixtures.yaml version long has correct args"
else
    echo "✗ fixtures.yaml version long has incorrect args - fix not applied"
    test_status=1
fi

if grep -A 1 "name: version short" "test/io/fixtures.yaml" | grep -q "args: \['-v'\]"; then
    echo "✓ fixtures.yaml version short has correct args"
else
    echo "✗ fixtures.yaml version short has incorrect args - fix not applied"
    test_status=1
fi

echo ""

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
