#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# Verify source code matches HEAD state (fix applied)
# This is PR #4524 which optimizes count=exact when there's no limits, offsets or db-max-rows

test_status=0

echo "Verifying source code matches HEAD state (fix applied)..."
echo ""

echo "Checking that CHANGELOG.md mentions the count=exact optimization..."
if grep -q "Optimize requests with \`Prefer: count=exact\` that do not use ranges or \`db-max-rows\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions count=exact optimization - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention count=exact optimization - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that CHANGELOG.md mentions removing unnecessary double count..."
if grep -q "Removed unnecessary double count when building the \`Content-Range\`" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md mentions removing double count - fix applied!"
else
    echo "✗ CHANGELOG.md does not mention removing double count - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Query.hs passes range parameter to mainRead..."
if grep -q "mainQuery (Db plan) conf@AppConfig{..} apiReq@ApiRequest{iTopLevelRange=range" "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs extracts range parameter - fix applied!"
else
    echo "✗ Query.hs does not extract range parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that mainRead function signature includes range parameter..."
if grep -q "mainRead wrReadPlan countQuery preferCount configDbMaxRows range pMedia wrHandler" "src/PostgREST/Query.hs"; then
    echo "✓ mainRead call includes range parameter - fix applied!"
else
    echo "✗ mainRead call does not include range parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that mainCall function signature includes range parameter..."
if grep -q "mainCall crProc crCallPlan crReadPlan preferCount configDbMaxRows range pMedia crHandler" "src/PostgREST/Query.hs"; then
    echo "✓ mainCall call includes range parameter - fix applied!"
else
    echo "✗ mainCall call does not include range parameter - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SqlFragment.hs exports pageCountSelectF..."
if grep -q "pageCountSelectF" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs exports pageCountSelectF - fix applied!"
else
    echo "✗ SqlFragment.hs does not export pageCountSelectF - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that SqlFragment.hs imports funcReturnsSingle..."
if grep -q "funcReturnsSingle" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs imports funcReturnsSingle - fix applied!"
else
    echo "✗ SqlFragment.hs does not import funcReturnsSingle - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that countF signature includes maxRows and range parameters..."
if grep -q "countF :: SQL.Snippet -> SQL.Snippet -> Bool -> Maybe Integer -> NonnegRange -> (SQL.Snippet, SQL.Snippet)" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ countF signature updated with new parameters - fix applied!"
else
    echo "✗ countF signature not updated - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that countF implementation uses pageCountSelect optimization..."
if grep -q "isJust maxRows || range /= allRange" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ countF includes optimization logic - fix applied!"
else
    echo "✗ countF does not include optimization logic - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that pageCountSelectF function exists..."
if grep -q "pageCountSelectF :: Maybe Routine -> SQL.Snippet" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ pageCountSelectF function defined - fix applied!"
else
    echo "✗ pageCountSelectF function not defined - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that Statements.hs mainRead signature includes range parameter..."
if grep -q "mainRead :: ReadPlanTree -> SQL.Snippet -> Maybe PreferCount -> Maybe Integer ->" "src/PostgREST/Query/Statements.hs" && \
   grep -q "NonnegRange -> MediaType -> MediaHandler -> SQL.Snippet" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs mainRead signature updated - fix applied!"
else
    echo "✗ Statements.hs mainRead signature not updated - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that mainRead implementation uses pageCountSelect..."
if grep -q "pageCountSelect <- " "src/PostgREST/Query/Statements.hs" || grep -q "pageCountSelect = pageCountSelectF Nothing" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ mainRead uses pageCountSelect - fix applied!"
else
    echo "✗ mainRead does not use pageCountSelect - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that mainCall signature includes range parameter..."
if grep -q "mainCall :: Routine -> CallPlan -> ReadPlanTree -> Maybe PreferCount -> Maybe Integer ->" "src/PostgREST/Query/Statements.hs" && \
   grep -q "NonnegRange-> MediaType -> MediaHandler -> SQL.Snippet" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ Statements.hs mainCall signature updated - fix applied!"
else
    echo "✗ Statements.hs mainCall signature not updated - fix not applied"
    test_status=1
fi

echo ""
echo "Checking that mainCall implementation uses pageCountSelect..."
if grep -q "pageCountSelect = pageCountSelectF (Just rout)" "src/PostgREST/Query/Statements.hs"; then
    echo "✓ mainCall uses pageCountSelect - fix applied!"
else
    echo "✗ mainCall does not use pageCountSelect - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
