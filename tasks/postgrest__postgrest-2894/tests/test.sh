#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/NullsStrip.hs" "test/spec/Feature/Query/NullsStrip.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for nulls=stripped parameter in media types..."
echo ""

# Check CHANGELOG has the fix documented
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#1601, Add optional `nulls=stripped` parameter for mediatypes' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

# Check postgrest.cabal includes the NullsStrip test module
echo "Checking postgrest.cabal for Feature.Query.NullsStrip module..."
if grep -q "Feature.Query.NullsStrip" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes Feature.Query.NullsStrip module"
else
    echo "✗ postgrest.cabal missing Feature.Query.NullsStrip module - fix not applied"
    test_status=1
fi

# Check MediaType.hs has MTArrayJSONStrip type
echo "Checking src/PostgREST/MediaType.hs for MTArrayJSONStrip..."
if grep -q "MTArrayJSONStrip" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has MTArrayJSONStrip type"
else
    echo "✗ MediaType.hs missing MTArrayJSONStrip type - fix not applied"
    test_status=1
fi

# Check MediaType.hs has MTSingularJSON with Bool parameter
echo "Checking src/PostgREST/MediaType.hs for MTSingularJSON Bool..."
if grep -q "MTSingularJSON Bool" "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs has MTSingularJSON Bool type"
else
    echo "✗ MediaType.hs missing MTSingularJSON Bool type - fix not applied"
    test_status=1
fi

# Check MediaType.hs decodes nulls=stripped parameter
echo "Checking src/PostgREST/MediaType.hs for checkArrayNullStrip function..."
if grep -q 'checkArrayNullStrip \["nulls=stripped"\] = MTArrayJSONStrip' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs decodes array nulls=stripped parameter"
else
    echo "✗ MediaType.hs missing checkArrayNullStrip - fix not applied"
    test_status=1
fi

# Check MediaType.hs decodes singular nulls=stripped parameter
echo "Checking src/PostgREST/MediaType.hs for checkSingularNullStrip function..."
if grep -q 'checkSingularNullStrip \["nulls=stripped"\] = MTSingularJSON True' "src/PostgREST/MediaType.hs"; then
    echo "✓ MediaType.hs decodes singular nulls=stripped parameter"
else
    echo "✗ MediaType.hs missing checkSingularNullStrip - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs has addNullsToSnip function
echo "Checking src/PostgREST/Query/SqlFragment.hs for addNullsToSnip function..."
if grep -q "addNullsToSnip :: Bool -> SQL.Snippet -> SQL.Snippet" "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs has addNullsToSnip function"
else
    echo "✗ SqlFragment.hs missing addNullsToSnip function - fix not applied"
    test_status=1
fi

# Check SqlFragment.hs uses json_strip_nulls
echo "Checking src/PostgREST/Query/SqlFragment.hs for json_strip_nulls..."
if grep -q 'if strip then "json_strip_nulls(" <> snip <> ")"' "src/PostgREST/Query/SqlFragment.hs"; then
    echo "✓ SqlFragment.hs uses json_strip_nulls"
else
    echo "✗ SqlFragment.hs missing json_strip_nulls usage - fix not applied"
    test_status=1
fi

# Check Routine.hs has BuiltinAggArrayJsonStrip
echo "Checking src/PostgREST/SchemaCache/Routine.hs for BuiltinAggArrayJsonStrip..."
if grep -q "BuiltinAggArrayJsonStrip" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs has BuiltinAggArrayJsonStrip"
else
    echo "✗ Routine.hs missing BuiltinAggArrayJsonStrip - fix not applied"
    test_status=1
fi

# Check Routine.hs has BuiltinAggSingleJson with Bool parameter
echo "Checking src/PostgREST/SchemaCache/Routine.hs for BuiltinAggSingleJson Bool..."
if grep -q "BuiltinAggSingleJson Bool" "src/PostgREST/SchemaCache/Routine.hs"; then
    echo "✓ Routine.hs has BuiltinAggSingleJson Bool"
else
    echo "✗ Routine.hs missing BuiltinAggSingleJson Bool - fix not applied"
    test_status=1
fi

# Check test file exists
echo "Checking test/spec/Feature/Query/NullsStrip.hs exists..."
if [ -f "test/spec/Feature/Query/NullsStrip.hs" ]; then
    echo "✓ NullsStrip.hs test file exists"
else
    echo "✗ NullsStrip.hs test file missing - fix not applied"
    test_status=1
fi

# Check test file has strip nulls test
echo "Checking test/spec/Feature/Query/NullsStrip.hs for strip nulls tests..."
if grep -q 'application/vnd.pgrst.array+json;nulls=stripped' "test/spec/Feature/Query/NullsStrip.hs"; then
    echo "✓ NullsStrip.hs has array strip tests"
else
    echo "✗ NullsStrip.hs missing array strip tests - fix not applied"
    test_status=1
fi

# Check test file has singular strip test
echo "Checking test/spec/Feature/Query/NullsStrip.hs for singular strip tests..."
if grep -q 'application/vnd.pgrst.object+json;nulls=stripped' "test/spec/Feature/Query/NullsStrip.hs"; then
    echo "✓ NullsStrip.hs has singular strip tests"
else
    echo "✗ NullsStrip.hs missing singular strip tests - fix not applied"
    test_status=1
fi

# Check Main.hs imports NullsStrip
echo "Checking test/spec/Main.hs imports Feature.Query.NullsStrip..."
if grep -q "import qualified Feature.Query.NullsStrip" "test/spec/Main.hs"; then
    echo "✓ Main.hs imports Feature.Query.NullsStrip"
else
    echo "✗ Main.hs missing Feature.Query.NullsStrip import - fix not applied"
    test_status=1
fi

# Check Main.hs registers NullsStrip spec
echo "Checking test/spec/Main.hs registers NullsStrip spec..."
if grep -q 'Feature.Query.NullsStrip.*spec' "test/spec/Main.hs"; then
    echo "✓ Main.hs registers NullsStrip spec"
else
    echo "✗ Main.hs missing NullsStrip spec registration - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs has matchCTArrayStrip helper
echo "Checking test/spec/SpecHelper.hs for matchCTArrayStrip..."
if grep -q "matchCTArrayStrip" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs has matchCTArrayStrip helper"
else
    echo "✗ SpecHelper.hs missing matchCTArrayStrip helper - fix not applied"
    test_status=1
fi

# Check SpecHelper.hs has matchCTSingularStrip helper
echo "Checking test/spec/SpecHelper.hs for matchCTSingularStrip..."
if grep -q "matchCTSingularStrip" "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs has matchCTSingularStrip helper"
else
    echo "✗ SpecHelper.hs missing matchCTSingularStrip helper - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
