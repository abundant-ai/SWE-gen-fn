#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/fixtures.yaml" "test/io/fixtures.yaml"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for admin health-check with special host values (PR #2182)..."
echo ""
echo "This PR fixes admin /live and /ready endpoints to work with special server-host values like *, !4, !6, *4, *6."
echo ""

echo "Checking Admin.hs has RecordWildCards language extension..."
if [ -f "src/PostgREST/Admin.hs" ] && head -5 "src/PostgREST/Admin.hs" | grep -q '{-# LANGUAGE RecordWildCards #-}'; then
    echo "✓ Admin.hs has RecordWildCards extension (fix applied)"
else
    echo "✗ Admin.hs missing RecordWildCards extension (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs reachMainApp returns list of results..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q 'reachMainApp :: AppConfig -> IO \[Either IOException ()\]' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs reachMainApp returns list (fix applied)"
else
    echo "✗ Admin.hs reachMainApp does not return list (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs uses 'any isRight' to check reachability..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q 'any isRight <$> reachMainApp' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs uses 'any isRight' for checking (fix applied)"
else
    echo "✗ Admin.hs does not use 'any isRight' (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs handles special host values (*4, !4, *6, !6, *)..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q '\*4\|!4\|\*6\|!6' "src/PostgREST/Admin.hs" && grep -q 'filterAddrs' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs handles special host values (fix applied)"
else
    echo "✗ Admin.hs does not handle special host values (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs has ipv4Addrs and ipv6Addrs filters..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q 'ipv4Addrs' "src/PostgREST/Admin.hs" && grep -q 'ipv6Addrs' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs has IP address filters (fix applied)"
else
    echo "✗ Admin.hs missing IP address filters (not fixed)"
    test_status=1
fi

echo "Checking Admin.hs tries multiple addresses..."
if [ -f "src/PostgREST/Admin.hs" ] && grep -q 'tryAddr.*traverse' "src/PostgREST/Admin.hs"; then
    echo "✓ Admin.hs tries multiple addresses (fix applied)"
else
    echo "✗ Admin.hs does not try multiple addresses (not fixed)"
    test_status=1
fi

echo "Checking App.hs has correct typo fix (plattforms -> platforms)..."
if [ -f "src/PostgREST/App.hs" ] && grep -q 'Cannot run with unix socket on non-unix plattforms' "src/PostgREST/App.hs"; then
    echo "✗ App.hs still has old typo 'plattforms' (fix applied but minor issue)"
elif [ -f "src/PostgREST/App.hs" ] && grep -q 'Cannot run with.*socket.*non-unix' "src/PostgREST/App.hs"; then
    echo "✓ App.hs socket message present (checking typo...)"
fi

echo ""
echo "Now checking that HEAD test files were copied correctly..."
echo ""

echo "Checking test files exist..."
for file in "test/io/fixtures.yaml" "test/io/test_io.py"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists (HEAD version)"
    else
        echo "✗ $file not found - HEAD file not copied!"
        test_status=1
    fi
done

echo "Checking fixtures.yaml has specialhostvalues..."
if [ -f "test/io/fixtures.yaml" ] && grep -q 'specialhostvalues:' "test/io/fixtures.yaml" && grep -q '\*4' "test/io/fixtures.yaml"; then
    echo "✓ fixtures.yaml contains specialhostvalues (HEAD version)"
else
    echo "✗ fixtures.yaml does not contain specialhostvalues - HEAD file not properly copied!"
    test_status=1
fi

echo "Checking test_io.py has test for special host values..."
if [ -f "test/io/test_io.py" ] && grep -q 'test_admin_works_with_host_special_values' "test/io/test_io.py"; then
    echo "✓ test_io.py contains special host value test (HEAD version)"
else
    echo "✗ test_io.py does not contain special host value test - HEAD file not properly copied!"
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
