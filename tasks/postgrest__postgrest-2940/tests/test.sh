#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/DeleteSpec.hs" "test/spec/Feature/Query/DeleteSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/InsertSpec.hs" "test/spec/Feature/Query/InsertSpec.hs"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/SingularSpec.hs" "test/spec/Feature/Query/SingularSpec.hs"
mkdir -p "test/spec/Feature"
cp "/tests/spec/Feature/RollbackSpec.hs" "test/spec/Feature/RollbackSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Check that CHANGELOG.md has the fix entry for #2939
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2939.*Preference-Applied.*tx=commit.*transaction.*rollbacked' "CHANGELOG.md" && \
   grep -q '#2939.*count=exact.*Preference-Applied' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entries for #2939"
else
    echo "✗ CHANGELOG.md missing fix entries - fix not applied"
    test_status=1
fi

# Check that fromHeaders function signature includes Bool parameter
echo "Checking Preferences.hs has updated fromHeaders signature..."
if grep -q 'fromHeaders :: Bool -> \[HTTP.Header\] -> Preferences' "src/PostgREST/ApiRequest/Preferences.hs" || \
   grep -q 'fromHeaders allowTxEndOverride headers' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs fromHeaders has Bool parameter for tx override control"
else
    echo "✗ Preferences.hs fromHeaders missing Bool parameter - fix not applied"
    test_status=1
fi

# Check that ApiRequest.hs passes configDbTxAllowOverride to fromHeaders
echo "Checking ApiRequest.hs passes config to fromHeaders..."
if grep -q 'fromHeaders (configDbTxAllowOverride conf)' "src/PostgREST/ApiRequest.hs" || \
   grep -q 'fromHeaders.*configDbTxAllowOverride.*hdrs' "src/PostgREST/ApiRequest.hs"; then
    echo "✓ ApiRequest.hs passes configDbTxAllowOverride to fromHeaders"
else
    echo "✗ ApiRequest.hs not passing config to fromHeaders - fix not applied"
    test_status=1
fi

# Check that NamedFieldPuns language extension is added
echo "Checking Preferences.hs has NamedFieldPuns extension..."
if grep -q '{-# LANGUAGE NamedFieldPuns #-}' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs has NamedFieldPuns extension"
else
    echo "✗ Preferences.hs missing NamedFieldPuns extension - fix not applied"
    test_status=1
fi

# Check that module exports prefAppliedHeader instead of ToAppliedHeader
echo "Checking Preferences.hs exports prefAppliedHeader..."
if grep -q 'prefAppliedHeader' "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q 'ToAppliedHeader(..)' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs exports prefAppliedHeader correctly"
else
    echo "✗ Preferences.hs export list not updated - fix not applied"
    test_status=1
fi

# Check that doctest examples are updated with txAllowOverride parameter
echo "Checking Preferences.hs doctests are updated..."
if grep -q 'fromHeaders True' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ Preferences.hs doctests updated with txAllowOverride parameter"
else
    echo "✗ Preferences.hs doctests not updated - fix not applied"
    test_status=1
fi

# Check that prefAppliedHeader function is defined
echo "Checking prefAppliedHeader function exists..."
if grep -q 'prefAppliedHeader :: Preferences -> Maybe HTTP.Header' "src/PostgREST/ApiRequest/Preferences.hs" && \
   grep -q 'prefAppliedHeader Preferences' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ prefAppliedHeader function is defined"
else
    echo "✗ prefAppliedHeader function missing - fix not applied"
    test_status=1
fi

# Check that preferTransaction uses conditional logic with allowTxEndOverride
echo "Checking conditional logic for preferTransaction..."
if grep -q 'if allowTxEndOverride then parsePrefs \[Commit, Rollback\] else Nothing' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ preferTransaction uses conditional logic based on allowTxEndOverride"
else
    echo "✗ preferTransaction conditional logic missing - fix not applied"
    test_status=1
fi

# Check that ToAppliedHeader class and instances are removed
echo "Checking ToAppliedHeader class is removed..."
if ! grep -q 'class ToHeaderValue a => ToAppliedHeader a where' "src/PostgREST/ApiRequest/Preferences.hs" && \
   ! grep -q 'instance ToAppliedHeader' "src/PostgREST/ApiRequest/Preferences.hs"; then
    echo "✓ ToAppliedHeader class and instances removed"
else
    echo "✗ ToAppliedHeader class still present - fix not applied"
    test_status=1
fi

# Check that Response.hs imports prefAppliedHeader instead of toAppliedHeader
echo "Checking Response.hs imports prefAppliedHeader..."
if grep -q 'prefAppliedHeader' "src/PostgREST/Response.hs" && \
   ! grep -q 'toAppliedHeader' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs imports prefAppliedHeader"
else
    echo "✗ Response.hs still uses toAppliedHeader - fix not applied"
    test_status=1
fi

# Check that Response.hs uses prefAppliedHeader with Preferences constructor
echo "Checking Response.hs uses prefAppliedHeader..."
if grep -q 'prefAppliedHeader.*Preferences' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs uses prefAppliedHeader with Preferences constructor"
else
    echo "✗ Response.hs not using prefAppliedHeader correctly - fix not applied"
    test_status=1
fi

# Check that Query.hs has simplified shouldCommit and shouldRollback logic
echo "Checking Query.hs has updated rollback logic..."
if grep -A 1 'shouldCommit =' "src/PostgREST/Query.hs" | grep -q 'preferTransaction == Just Commit' && \
   ! grep -q 'configDbTxAllowOverride && preferTransaction' "src/PostgREST/Query.hs"; then
    echo "✓ Query.hs has simplified commit/rollback logic"
else
    echo "✗ Query.hs rollback logic not updated - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
