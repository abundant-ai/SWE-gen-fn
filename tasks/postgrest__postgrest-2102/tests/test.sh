#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"
mkdir -p "test/io-tests"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

test_status=0

echo "Verifying fix for XMLTABLE view parsing (PR #2102)..."
echo ""
echo "This PR fixes schema cache loading when views with XMLTABLE and DEFAULT are present."
echo "The bug was that pfkSourceColumns parsing failed when coldefexprs started with <>."
echo "The fix moves <> replacement to before comma removal in the node-tree-to-JSON conversion."
echo ""

echo "Checking CHANGELOG mentions PR #2024..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#2024" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions PR #2024 (fix documented)"
    else
        echo "✗ CHANGELOG.md does not mention PR #2024 (missing documentation)"
        test_status=1
    fi

    if grep -q "Fix schema cache loading when views with XMLTABLE and DEFAULT are present" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md describes the XMLTABLE fix"
    else
        echo "✗ CHANGELOG.md missing XMLTABLE fix description"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking DbStructure.hs has correct <> replacement order..."
if [ -f "src/PostgREST/DbStructure.hs" ]; then
    echo "✓ src/PostgREST/DbStructure.hs exists"

    # Check for the comment explaining the <> replacement is placed first
    if grep -q "We'll need to put it first, to make the node protection below work" "src/PostgREST/DbStructure.hs"; then
        echo "✓ DbStructure.hs has comment explaining why <> is first (fix applied)"
    else
        echo "✗ DbStructure.hs missing comment about <> being first (fix not applied)"
        test_status=1
    fi

    # Check that '<>' -> '()' replacement exists
    if grep -q "'<>'.*'()'" "src/PostgREST/DbStructure.hs"; then
        echo "✓ DbStructure.hs replaces <> with () (fix applied)"
    else
        echo "✗ DbStructure.hs missing <> -> () replacement (fix not applied)"
        test_status=1
    fi

    # Verify the <> replacement comes before comma replacement (correct order)
    # Extract line numbers and compare them
    line_bracket=$(grep -n "   '<>'" "src/PostgREST/DbStructure.hs" | head -1 | cut -d: -f1)
    line_comma=$(grep -n "), ','  " "src/PostgREST/DbStructure.hs" | head -1 | cut -d: -f1)

    if [ -n "$line_bracket" ] && [ -n "$line_comma" ] && [ "$line_bracket" -lt "$line_comma" ]; then
        echo "✓ DbStructure.hs has <> replacement before comma replacement (correct order)"
    else
        echo "✗ DbStructure.hs has wrong replacement order (fix not applied correctly)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/DbStructure.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files were copied correctly..."
if [ -f "test/fixtures/schema.sql" ]; then
    echo "✓ test/fixtures/schema.sql exists (HEAD version)"

    # Check for the XMLTABLE view that triggers the bug
    if grep -q "XMLTABLE" "test/fixtures/schema.sql"; then
        echo "✓ schema.sql has XMLTABLE view (test case for fix)"
    else
        echo "✗ schema.sql missing XMLTABLE view (test case missing)"
        test_status=1
    fi

    if grep -q "DEFAULT 'not specified'" "test/fixtures/schema.sql"; then
        echo "✓ schema.sql has DEFAULT in XMLTABLE column (triggers the bug)"
    else
        echo "✗ schema.sql missing DEFAULT in XMLTABLE (test incomplete)"
        test_status=1
    fi
else
    echo "✗ test/fixtures/schema.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/io-tests/test_io.py" ]; then
    echo "✓ test/io-tests/test_io.py exists (HEAD version)"

    # Check for the formatting changes (concatenated f-strings instead of split)
    if grep -q 'f"http://localhost:{env' "test/io-tests/test_io.py"; then
        echo "✓ test_io.py has formatted request lines (fix applied)"
    else
        echo "✗ test_io.py still has split request lines (formatting not applied)"
        test_status=1
    fi
else
    echo "✗ test/io-tests/test_io.py not found - HEAD file not copied!"
    test_status=1
fi

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
