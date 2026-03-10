#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"

test_status=0

echo "Verifying fix for RPC calls with domain-wrapped composite types on PostgreSQL 11/12..."
echo ""

# Check App.hs passes pgVer to invokeQuery
echo "Checking src/PostgREST/App.hs passes pgVer to invokeQuery..."
if grep -q "Query.invokeQuery (Plan.crProc cPlan) cPlan apiReq conf pgVer" "src/PostgREST/App.hs"; then
    echo "✓ src/PostgREST/App.hs passes pgVer to invokeQuery"
else
    echo "✗ src/PostgREST/App.hs not passing pgVer - fix not applied"
    test_status=1
fi

# Check Plan.hs imports procReturnsCompositeAlias
echo "Checking src/PostgREST/Plan.hs imports procReturnsCompositeAlias..."
if grep -q "procReturnsCompositeAlias" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs imports procReturnsCompositeAlias"
else
    echo "✗ src/PostgREST/Plan.hs missing procReturnsCompositeAlias import - fix not applied"
    test_status=1
fi

# Check Plan.hs sets funCRetCompositeAlias
echo "Checking src/PostgREST/Plan.hs sets funCRetCompositeAlias..."
if grep -q "funCRetCompositeAlias = procReturnsCompositeAlias proc" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs sets funCRetCompositeAlias"
else
    echo "✗ src/PostgREST/Plan.hs not setting funCRetCompositeAlias - fix not applied"
    test_status=1
fi

# Check CallPlan.hs has funCRetCompositeAlias field
echo "Checking src/PostgREST/Plan/CallPlan.hs has funCRetCompositeAlias field..."
if grep -q "funCRetCompositeAlias" "src/PostgREST/Plan/CallPlan.hs"; then
    echo "✓ src/PostgREST/Plan/CallPlan.hs has funCRetCompositeAlias field"
else
    echo "✗ src/PostgREST/Plan/CallPlan.hs missing funCRetCompositeAlias - fix not applied"
    test_status=1
fi

# Check Query.hs accepts pgVer parameter and passes it to callPlanToQuery
echo "Checking src/PostgREST/Query.hs accepts pgVer and passes to callPlanToQuery..."
if grep -q "invokeQuery :: ProcDescription -> CallReadPlan -> ApiRequest -> AppConfig -> PgVersion" "src/PostgREST/Query.hs" && \
   grep -q "QueryBuilder.callPlanToQuery crCallPlan pgVer" "src/PostgREST/Query.hs"; then
    echo "✓ src/PostgREST/Query.hs accepts pgVer and passes to callPlanToQuery"
else
    echo "✗ src/PostgREST/Query.hs not properly handling pgVer - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs imports PgVersion and version constants
echo "Checking src/PostgREST/Query/QueryBuilder.hs imports PgVersion..."
if grep -q "PgVersion" "src/PostgREST/Query/QueryBuilder.hs" && \
   grep -q "pgVersion110" "src/PostgREST/Query/QueryBuilder.hs" && \
   grep -q "pgVersion130" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs imports PgVersion and version constants"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs missing PgVersion imports - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs callPlanToQuery accepts PgVersion parameter
echo "Checking src/PostgREST/Query/QueryBuilder.hs callPlanToQuery accepts PgVersion..."
if grep -q "callPlanToQuery :: CallPlan -> PgVersion -> SQL.Snippet" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs callPlanToQuery accepts PgVersion"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs callPlanToQuery signature wrong - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs callPlanToQuery uses returnsCompositeAlias
echo "Checking src/PostgREST/Query/QueryBuilder.hs callPlanToQuery uses returnsCompositeAlias..."
if grep -q "returnsCompositeAlias" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs callPlanToQuery uses returnsCompositeAlias"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs not using returnsCompositeAlias - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs has version-aware SQL generation for pg11/12
echo "Checking src/PostgREST/Query/QueryBuilder.hs has version-aware SQL generation..."
if grep -q "pgVer < pgVersion130 && pgVer >= pgVersion110 && returnsCompositeAlias" "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs has version-aware SQL generation for pg11/12"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs missing version check - fix not applied"
    test_status=1
fi

# Check QueryBuilder.hs uses SELECT (...).*) workaround for pg11/12
echo "Checking src/PostgREST/Query/QueryBuilder.hs uses SELECT (...).*) workaround..."
if grep -q '(SELECT (' "src/PostgREST/Query/QueryBuilder.hs" && grep -q ')).\*)' "src/PostgREST/Query/QueryBuilder.hs"; then
    echo "✓ src/PostgREST/Query/QueryBuilder.hs uses SELECT (...).*) workaround"
else
    echo "✗ src/PostgREST/Query/QueryBuilder.hs missing SELECT workaround - fix not applied"
    test_status=1
fi

# Check SchemaCache/Proc.hs exports procReturnsCompositeAlias
echo "Checking src/PostgREST/SchemaCache/Proc.hs exports procReturnsCompositeAlias..."
if grep -q "procReturnsCompositeAlias" "src/PostgREST/SchemaCache/Proc.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Proc.hs exports procReturnsCompositeAlias"
else
    echo "✗ src/PostgREST/SchemaCache/Proc.hs not exporting procReturnsCompositeAlias - fix not applied"
    test_status=1
fi

# Check SchemaCache/Proc.hs Composite type has Bool parameter
echo "Checking src/PostgREST/SchemaCache/Proc.hs Composite type has Bool parameter..."
if grep -q "Composite QualifiedIdentifier Bool" "src/PostgREST/SchemaCache/Proc.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Proc.hs Composite type has Bool parameter"
else
    echo "✗ src/PostgREST/SchemaCache/Proc.hs Composite type wrong - fix not applied"
    test_status=1
fi

# Check SchemaCache/Proc.hs has procReturnsCompositeAlias function implementation
echo "Checking src/PostgREST/SchemaCache/Proc.hs has procReturnsCompositeAlias implementation..."
if grep -q "procReturnsCompositeAlias :: ProcDescription -> Bool" "src/PostgREST/SchemaCache/Proc.hs" && \
   grep -q "Composite _ True" "src/PostgREST/SchemaCache/Proc.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Proc.hs has procReturnsCompositeAlias implementation"
else
    echo "✗ src/PostgREST/SchemaCache/Proc.hs procReturnsCompositeAlias implementation missing - fix not applied"
    test_status=1
fi

# Check SchemaCache/Proc.hs procReturnsSingleComposite updated for new Composite signature
echo "Checking src/PostgREST/SchemaCache/Proc.hs procReturnsSingleComposite updated..."
if grep -q "Single (Composite _ _)" "src/PostgREST/SchemaCache/Proc.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Proc.hs procReturnsSingleComposite updated"
else
    echo "✗ src/PostgREST/SchemaCache/Proc.hs procReturnsSingleComposite not updated - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs updated for new Composite constructor
echo "Checking src/PostgREST/SchemaCache.hs handles composite alias detection..."
if grep -q "Composite" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has Composite handling"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing Composite handling - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
