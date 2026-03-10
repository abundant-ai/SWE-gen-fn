#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ComputedRelsSpec.hs" "test/spec/Feature/Query/ComputedRelsSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/QuerySpec.hs" "test/spec/Feature/Query/QuerySpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/Main.hs" "test/spec/Main.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/data.sql" "test/spec/fixtures/data.sql"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

test_status=0

echo "Verifying fix for Data Representations (#2523)..."
echo ""

# Check CHANGELOG.md for the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q "#2523, Data representations - @aljungberg" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the data representations feature entry"
else
    echo "✗ CHANGELOG.md missing data representations entry - fix not applied"
    test_status=1
fi

# Check postgrest.cabal for PostgREST.SchemaCache.Representations module
echo "Checking postgrest.cabal for Representations module..."
if grep -q "PostgREST.SchemaCache.Representations" "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes PostgREST.SchemaCache.Representations module"
else
    echo "✗ postgrest.cabal missing Representations module - fix not applied"
    test_status=1
fi

# Check that PostgREST.SchemaCache.Representations.hs file exists
echo "Checking for PostgREST.SchemaCache.Representations.hs file..."
if [ -f "src/PostgREST/SchemaCache/Representations.hs" ]; then
    echo "✓ src/PostgREST/SchemaCache/Representations.hs exists"
else
    echo "✗ src/PostgREST/SchemaCache/Representations.hs missing - fix not applied"
    test_status=1
fi

# Check PostgREST/Plan.hs imports Representations
echo "Checking src/PostgREST/Plan.hs for Representations import..."
if grep -q "PostgREST.SchemaCache.Representations" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs imports Representations module"
else
    echo "✗ src/PostgREST/Plan.hs missing Representations import - fix not applied"
    test_status=1
fi

# Check PostgREST/Plan.hs imports HMI (HashMap.Strict.InsOrd)
echo "Checking src/PostgREST/Plan.hs for HMI import..."
if grep -q "Data.HashMap.Strict.InsOrd.*as HMI" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs imports Data.HashMap.Strict.InsOrd as HMI"
else
    echo "✗ src/PostgREST/Plan.hs missing HMI import - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs for dbRepresentations field
echo "Checking src/PostgREST/SchemaCache.hs for dbRepresentations..."
if grep -q "dbRepresentations.*RepresentationsMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has dbRepresentations field"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing dbRepresentations - fix not applied"
    test_status=1
fi

# Check SchemaCache.hs for decodeRepresentations function
echo "Checking src/PostgREST/SchemaCache.hs for decodeRepresentations function..."
if grep -q "decodeRepresentations.*Result RepresentationsMap" "src/PostgREST/SchemaCache.hs"; then
    echo "✓ src/PostgREST/SchemaCache.hs has decodeRepresentations function"
else
    echo "✗ src/PostgREST/SchemaCache.hs missing decodeRepresentations - fix not applied"
    test_status=1
fi

# Check Plan.hs for ResolverContext with representations field
echo "Checking src/PostgREST/Plan.hs for ResolverContext with representations..."
if grep -q "data ResolverContext" "src/PostgREST/Plan.hs" && \
   grep -q "representations :: RepresentationsMap" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs has ResolverContext with representations field"
else
    echo "✗ src/PostgREST/Plan.hs missing ResolverContext or representations - fix not applied"
    test_status=1
fi

# Check Representations.hs module definition
echo "Checking src/PostgREST/SchemaCache/Representations.hs module structure..."
if grep -q "module PostgREST.SchemaCache.Representations" "src/PostgREST/SchemaCache/Representations.hs" && \
   grep -q "DataRepresentation" "src/PostgREST/SchemaCache/Representations.hs"; then
    echo "✓ src/PostgREST/SchemaCache/Representations.hs has proper module structure with DataRepresentation"
else
    echo "✗ src/PostgREST/SchemaCache/Representations.hs incomplete - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
