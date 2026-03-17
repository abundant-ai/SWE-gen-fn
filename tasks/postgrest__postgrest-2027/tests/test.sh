#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/Feature"
cp "/tests/Feature/QuerySpec.hs" "test/Feature/QuerySpec.hs"
mkdir -p "test/fixtures"
cp "/tests/fixtures/data.sql" "test/fixtures/data.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/privileges.sql" "test/fixtures/privileges.sql"
mkdir -p "test/fixtures"
cp "/tests/fixtures/schema.sql" "test/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #2027 which fixes the `is` operator to support `unknown` and removes SQL injection risk
# HEAD state (5cc95992dd11279e9dce701087070c370fc2fc4d) = fix applied
# BASE state (with bug.patch) = old code with pgFmtLit, no TrileanVal
# ORACLE state (BASE + fix.patch) = new code with TrileanVal, no pgFmtLit

test_status=0

echo "Verifying source code matches HEAD state (fixed `is` operator with TrileanVal support)..."
echo ""

echo "Checking that CHANGELOG mentions the unknown operator support..."
if grep -q "#1988, Allow specifying \`unknown\` for the \`is\` operator" "CHANGELOG.md"; then
    echo "✓ CHANGELOG mentions unknown operator support - fix applied!"
else
    echo "✗ CHANGELOG does not mention unknown operator support - fix not applied"
    test_status=1
fi

echo "Checking that SqlFragment.hs imports TrileanVal..."
if grep -q "TrileanVal (..)" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs imports TrileanVal - fix applied!"
else
    echo "✗ SqlFragment.hs does not import TrileanVal - fix not applied"
    test_status=1
fi

echo "Checking that pgFmtLit function was removed from SqlFragment.hs..."
if ! grep -q "^pgFmtLit ::" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ pgFmtLit function removed - fix applied!"
else
    echo "✗ pgFmtLit function still exists - fix not applied"
    test_status=1
fi

echo "Checking that pgBuildArrayLiteral exists (renamed from pgFmtArrayLit)..."
if grep -q "pgBuildArrayLiteral :: \[Text\] -> Text" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ pgBuildArrayLiteral exists - fix applied!"
else
    echo "✗ pgBuildArrayLiteral does not exist - fix not applied"
    test_status=1
fi

echo "Checking that SqlFragment.hs has the Is pattern match with TrileanVal..."
if grep -q "Is triVal ->" "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q "TriTrue    -> \"TRUE\"" "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q "TriFalse   -> \"FALSE\"" "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q "TriNull    -> \"NULL\"" "src/PostgREST/Query/SqlFragment.hs" && \
   grep -q "TriUnknown -> \"UNKNOWN\"" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has Is pattern with all TrileanVal cases - fix applied!"
else
    echo "✗ SqlFragment.hs missing Is pattern or TrileanVal cases - fix not applied"
    test_status=1
fi

echo "Checking that isAllowed function was removed from SqlFragment.hs..."
if ! grep -q "isAllowed ::" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ isAllowed function removed - fix applied!"
else
    echo "✗ isAllowed function still exists - fix not applied"
    test_status=1
fi

echo "Checking that Types.hs defines TrileanVal data type..."
if grep -q "data TrileanVal" "src/PostgREST/Request/Types.hs" && \
   grep -q "TriTrue" "src/PostgREST/Request/Types.hs" && \
   grep -q "TriFalse" "src/PostgREST/Request/Types.hs" && \
   grep -q "TriNull" "src/PostgREST/Request/Types.hs" && \
   grep -q "TriUnknown" "src/PostgREST/Request/Types.hs"; then
    echo "✓ Types.hs defines TrileanVal with all constructors - fix applied!"
else
    echo "✗ Types.hs missing TrileanVal or its constructors - fix not applied"
    test_status=1
fi

echo "Checking that Types.hs exports TrileanVal..."
if grep -q ", TrileanVal(..)" "src/PostgREST/Request/Types.hs"; then
    echo "✓ Types.hs exports TrileanVal - fix applied!"
else
    echo "✗ Types.hs does not export TrileanVal - fix not applied"
    test_status=1
fi

echo "Checking that Operation includes Is TrileanVal constructor..."
if grep -q "| Is TrileanVal" "src/PostgREST/Request/Types.hs"; then
    echo "✓ Operation has Is TrileanVal constructor - fix applied!"
else
    echo "✗ Operation missing Is TrileanVal constructor - fix not applied"
    test_status=1
fi

echo "Checking that Parsers.hs has pTriVal parser..."
if grep -q "pTriVal = try (string \"null\"    \$> TriNull)" "src/PostgREST/Request/Parsers.hs" && \
   grep -q "try (string \"unknown\" \$> TriUnknown)" "src/PostgREST/Request/Parsers.hs" && \
   grep -q "try (string \"true\"    \$> TriTrue)" "src/PostgREST/Request/Parsers.hs" && \
   grep -q "try (string \"false\"   \$> TriFalse)" "src/PostgREST/Request/Parsers.hs"; then
    echo "✓ Parsers.hs has pTriVal parser with all trilean values - fix applied!"
else
    echo "✗ Parsers.hs missing pTriVal parser or trilean values - fix not applied"
    test_status=1
fi

echo "Checking that Parsers.hs uses Is constructor in pOperation..."
if grep -q "Is <\$> (try (string \"is\" \*> pDelimiter) \*> pTriVal)" "src/PostgREST/Request/Parsers.hs"; then
    echo "✓ Parsers.hs uses Is with pTriVal - fix applied!"
else
    echo "✗ Parsers.hs does not use Is with pTriVal - fix not applied"
    test_status=1
fi

echo "Checking that Parsers.hs excludes 'is' from ops..."
if grep -q 'ops = M.filterWithKey (const . flip notElem ("in":"is":ftsOps))' "src/PostgREST/Request/Parsers.hs"; then
    echo "✓ Parsers.hs excludes 'is' from ops - fix applied!"
else
    echo "✗ Parsers.hs does not exclude 'is' from ops - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
