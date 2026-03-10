#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/PlanSpec.hs" "test/spec/Feature/Query/PlanSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for MediaType refactoring revert (#2829)..."
echo ""

# The fix REVERTS the refactoring, so we check for ABSENCE of new types

# Check src/PostgREST/MediaType.hs does NOT have NormalMedia type
echo "Checking src/PostgREST/MediaType.hs for absence of NormalMedia type..."
if grep -q "data NormalMedia" "src/PostgREST/MediaType.hs"; then
    echo "✗ src/PostgREST/MediaType.hs still has NormalMedia type - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/MediaType.hs does not define NormalMedia type"
fi

# Check src/PostgREST/MediaType.hs does NOT have MTPlanAttrs type
echo "Checking src/PostgREST/MediaType.hs for absence of MTPlanAttrs type..."
if grep -q "data MTPlanAttrs" "src/PostgREST/MediaType.hs"; then
    echo "✗ src/PostgREST/MediaType.hs still has MTPlanAttrs type - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/MediaType.hs does not define MTPlanAttrs type"
fi

# Check src/PostgREST/MediaType.hs does NOT have MTNormal constructor
echo "Checking src/PostgREST/MediaType.hs for absence of MTNormal constructor..."
if grep -q "MTNormal" "src/PostgREST/MediaType.hs"; then
    echo "✗ src/PostgREST/MediaType.hs still has MTNormal constructor - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/MediaType.hs does not have MTNormal constructor"
fi

# Check src/PostgREST/MediaType.hs has MTPlan with Maybe MediaType (old structure)
echo "Checking src/PostgREST/MediaType.hs for MTPlan with Maybe MediaType..."
if grep -q "| MTPlan (Maybe MediaType) (Maybe MTPlanFormat) \[MTPlanOption\]" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has MTPlan with old structure"
else
    echo "✗ src/PostgREST/MediaType.hs missing correct MTPlan structure - fix not applied"
    test_status=1
fi

# Check src/PostgREST/ApiRequest.hs does NOT import NormalMedia
echo "Checking src/PostgREST/ApiRequest.hs for absence of NormalMedia import..."
if grep -q "NormalMedia" "src/PostgREST/ApiRequest.hs"; then
    echo "✗ src/PostgREST/ApiRequest.hs still imports NormalMedia - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/ApiRequest.hs does not import NormalMedia"
fi

# Check src/PostgREST/ApiRequest.hs does NOT import MTPlanAttrs
echo "Checking src/PostgREST/ApiRequest.hs for absence of MTPlanAttrs import..."
if grep -q "MTPlanAttrs" "src/PostgREST/ApiRequest.hs"; then
    echo "✗ src/PostgREST/ApiRequest.hs still imports MTPlanAttrs - fix not applied"
    test_status=1
else
    echo "✓ src/PostgREST/ApiRequest.hs does not import MTPlanAttrs"
fi

# Check src/PostgREST/ApiRequest.hs uses direct MediaType constructors (no MTNormal wrapper)
echo "Checking src/PostgREST/ApiRequest.hs for direct MTApplicationJSON usage..."
if grep -q "MTApplicationJSON" "src/PostgREST/ApiRequest.hs" && ! grep -q "MTNormal MTApplicationJSON" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs uses direct MediaType constructors"
else
    echo "✗ src/PostgREST/ApiRequest.hs not using correct MediaType pattern - fix not applied"
    test_status=1
fi

# Check src/PostgREST/ApiRequest.hs uses MTPlan with Maybe MediaType (old structure)
echo "Checking src/PostgREST/ApiRequest.hs for MTPlan with old structure..."
if grep -q "MTPlan Nothing Nothing mempty" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs uses MTPlan with old structure"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing correct MTPlan usage - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs does NOT import NormalMedia
echo "Checking test/spec/SpecHelper.hs for absence of NormalMedia import..."
if grep -q "NormalMedia" "test/spec/SpecHelper.hs"; then
    echo "✗ test/spec/SpecHelper.hs still imports NormalMedia - fix not applied"
    test_status=1
else
    echo "✓ test/spec/SpecHelper.hs does not import NormalMedia"
fi

# Check test/spec/SpecHelper.hs uses direct MTOther (no MTNormal wrapper)
echo "Checking test/spec/SpecHelper.hs for direct MTOther usage..."
if grep -q "MTOther" "test/spec/SpecHelper.hs" && ! grep -q "MTNormal" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs uses direct MTOther"
else
    echo "✗ test/spec/SpecHelper.hs not using correct pattern - fix not applied"
    test_status=1
fi

# Check test/spec/Feature/Query/PlanSpec.hs expects old Content-Type (without +text)
echo "Checking test/spec/Feature/Query/PlanSpec.hs for old Content-Type..."
if grep -q 'application/vnd.pgrst.plan; charset=utf-8' "test/spec/Feature/Query/PlanSpec.hs"; then
    echo "✓ test/spec/Feature/Query/PlanSpec.hs expects old Content-Type"
else
    echo "✗ test/spec/Feature/Query/PlanSpec.hs not expecting correct Content-Type - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
