#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/UpdateSpec.hs" "test/spec/Feature/Query/UpdateSpec.hs"

test_status=0

echo "Verifying fix for renaming PreferUndefinedKeys to PreferMissing..."
echo ""

# Check CHANGELOG.md has the correct entry
echo "Checking CHANGELOG.md has 'missing=default' entry..."
if grep -q "#1567, On bulk inserts, missing values can get the column DEFAULT by using the \`Prefer: missing=default\` header" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has correct entry"
else
    echo "✗ CHANGELOG.md missing correct entry - fix not applied"
    test_status=1
fi

# Check Preferences.hs exports PreferMissing (not PreferUndefinedKeys)
echo "Checking src/PostgREST/ApiRequest/Preferences.hs exports PreferMissing..."
if grep -q "PreferMissing" "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q "PreferUndefinedKeys" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs exports PreferMissing"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has PreferUndefinedKeys - fix not applied"
    test_status=1
fi

# Check Preferences.hs has preferMissing field (not preferUndefinedKeys)
echo "Checking src/PostgREST/ApiRequest/Preferences.hs has preferMissing field..."
if grep -q "preferMissing" "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q "preferUndefinedKeys" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs has preferMissing field"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs still has preferUndefinedKeys field - fix not applied"
    test_status=1
fi

# Check Preferences.hs has correct data type
echo "Checking src/PostgREST/ApiRequest/Preferences.hs has data PreferMissing..."
if grep -q "data PreferMissing" "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q "ApplyNulls" "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q "IgnoreDefaults" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs has correct data PreferMissing"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs data type incorrect - fix not applied"
    test_status=1
fi

# Check Preferences.hs has correct header values
echo "Checking src/PostgREST/ApiRequest/Preferences.hs has 'missing=default' header..."
if grep -q 'toHeaderValue ApplyDefaults = "missing=default"' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'toHeaderValue ApplyNulls    = "missing=null"' "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q "undefined-keys" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs has correct header values"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs header values incorrect - fix not applied"
    test_status=1
fi

# Check Preferences.hs has correct instance declaration
echo "Checking src/PostgREST/ApiRequest/Preferences.hs has ToAppliedHeader PreferMissing..."
if grep -q "instance ToAppliedHeader PreferMissing" "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ src/PostgREST/ApiRequest/Preferences.hs has correct instance"
else
    echo "✗ src/PostgREST/ApiRequest/Preferences.hs instance declaration incorrect - fix not applied"
    test_status=1
fi

# Check Plan.hs uses preferMissing
echo "Checking src/PostgREST/Plan.hs uses preferMissing..."
if grep -q "applyDefaults = preferences.preferMissing == Just ApplyDefaults" "src/PostgREST/Plan.hs" && \
   ! grep -q "preferUndefinedKeys" "src/PostgREST/Plan.hs"; then
    echo "✓ src/PostgREST/Plan.hs uses preferMissing"
else
    echo "✗ src/PostgREST/Plan.hs not updated - fix not applied"
    test_status=1
fi

# Check Response.hs uses preferMissing
echo "Checking src/PostgREST/Response.hs uses preferMissing..."
if grep -q "preferMissing" "src/PostgREST/Response.hs" && \
   ! grep -q "preferUndefinedKeys" "src/PostgREST/Response.hs"; then
    echo "✓ src/PostgREST/Response.hs uses preferMissing"
else
    echo "✗ src/PostgREST/Response.hs not updated - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
