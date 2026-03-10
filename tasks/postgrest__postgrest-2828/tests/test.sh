#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

test_status=0

echo "Verifying fix for MediaType refactoring to eliminate recursion (#2828)..."
echo ""

# The fix introduces NormalMedia type and refactors MediaType to be non-recursive

# Check src/PostgREST/MediaType.hs has NormalMedia type definition
echo "Checking src/PostgREST/MediaType.hs for NormalMedia type..."
if grep -q "data NormalMedia" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs defines NormalMedia type"
else
    echo "✗ src/PostgREST/MediaType.hs missing NormalMedia type - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs has MTNormal constructor in MediaType
echo "Checking src/PostgREST/MediaType.hs for MTNormal constructor..."
if grep -q "= MTNormal NormalMedia" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has MTNormal constructor"
else
    echo "✗ src/PostgREST/MediaType.hs missing MTNormal constructor - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs MTPlanAttrs has Maybe NormalMedia (not Maybe MediaType)
echo "Checking src/PostgREST/MediaType.hs for MTPlanAttrs with Maybe NormalMedia..."
if grep -q "data MTPlanAttrs = MTPlanAttrs (Maybe NormalMedia)" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has MTPlanAttrs with Maybe NormalMedia"
else
    echo "✗ src/PostgREST/MediaType.hs missing correct MTPlanAttrs definition - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs exports NormalMedia
echo "Checking src/PostgREST/MediaType.hs exports NormalMedia..."
if grep -q ", NormalMedia(..)" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs exports NormalMedia"
else
    echo "✗ src/PostgREST/MediaType.hs does not export NormalMedia - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs has toMimeNormal function (part of refactoring)
echo "Checking src/PostgREST/MediaType.hs for toMimeNormal function..."
if grep -q "toMimeNormal :: NormalMedia -> ByteString" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has toMimeNormal function"
else
    echo "✗ src/PostgREST/MediaType.hs missing toMimeNormal function - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs has decodeNormalMediaType function
echo "Checking src/PostgREST/MediaType.hs for decodeNormalMediaType function..."
if grep -q "decodeNormalMediaType :: \[BS.ByteString\] -> NormalMedia" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has decodeNormalMediaType function"
else
    echo "✗ src/PostgREST/MediaType.hs missing decodeNormalMediaType function - fix not applied"
    test_status=1
fi

# Check src/PostgREST/MediaType.hs has doctests (shows they can now be added)
echo "Checking src/PostgREST/MediaType.hs for doctest examples..."
if grep -q ">>> decodeMediaType" "src/PostgREST/MediaType.hs"; then
    echo "✓ src/PostgREST/MediaType.hs has doctest examples"
else
    echo "✗ src/PostgREST/MediaType.hs missing doctest examples - fix not applied"
    test_status=1
fi

# Check test/doc/Main.hs includes MediaType.hs for doctests
echo "Checking test/doc/Main.hs includes MediaType.hs..."
if grep -q '"src/PostgREST/MediaType.hs"' "test/doc/Main.hs"; then
    echo "✓ test/doc/Main.hs includes MediaType.hs"
else
    echo "✗ test/doc/Main.hs does not include MediaType.hs - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs imports NormalMedia
echo "Checking test/spec/SpecHelper.hs imports NormalMedia..."
if grep -q "NormalMedia (..)" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs imports NormalMedia"
else
    echo "✗ test/spec/SpecHelper.hs does not import NormalMedia - fix not applied"
    test_status=1
fi

# Check test/spec/SpecHelper.hs uses MTNormal constructor
echo "Checking test/spec/SpecHelper.hs uses MTNormal constructor..."
if grep -q "MTNormal \$ MTOther" "test/spec/SpecHelper.hs"; then
    echo "✓ test/spec/SpecHelper.hs uses MTNormal constructor"
else
    echo "✗ test/spec/SpecHelper.hs missing MTNormal usage - fix not applied"
    test_status=1
fi

# Check src/PostgREST/ApiRequest.hs imports NormalMedia
echo "Checking src/PostgREST/ApiRequest.hs imports NormalMedia..."
if grep -q "NormalMedia (..)" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs imports NormalMedia"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing NormalMedia import - fix not applied"
    test_status=1
fi

# Check src/PostgREST/ApiRequest.hs uses MTNormal constructors
echo "Checking src/PostgREST/ApiRequest.hs uses MTNormal constructors..."
if grep -q "MTNormal MTAny" "src/PostgREST/ApiRequest.hs"; then
    echo "✓ src/PostgREST/ApiRequest.hs uses MTNormal constructors"
else
    echo "✗ src/PostgREST/ApiRequest.hs missing MTNormal usage - fix not applied"
    test_status=1
fi

# Check getMediaType returns NormalMedia (not MediaType)
echo "Checking getMediaType returns NormalMedia..."
if grep -q "getMediaType :: MediaType -> NormalMedia" "src/PostgREST/MediaType.hs"; then
    echo "✓ getMediaType has correct return type (NormalMedia)"
else
    echo "✗ getMediaType has wrong return type - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
