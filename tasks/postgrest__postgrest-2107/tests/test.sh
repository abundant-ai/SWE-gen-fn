#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test"
cp "/tests/Main.hs" "test/Main.hs"
mkdir -p "test/io-tests"
cp "/tests/io-tests/db_config.sql" "test/io-tests/db_config.sql"
cp "/tests/io-tests/test_io.py" "test/io-tests/test_io.py"

test_status=0

echo "Verifying fix for health check schema cache state (PR #2107)..."
echo ""
echo "This PR adds schema cache state checking to the /ready health endpoint."
echo "The bug was that /ready would return 200 even when schema cache failed to load."
echo "The fix adds checks so /ready returns 503 when schema cache is not loaded."
echo ""

echo "Checking CHANGELOG mentions PR #2107..."
if [ -f "CHANGELOG.md" ]; then
    if grep -q "#2107" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md mentions PR #2107 (fix documented)"
    else
        echo "✗ CHANGELOG.md does not mention PR #2107 (missing documentation)"
        test_status=1
    fi

    if grep -q "Clarify error for failed schema cache load" "CHANGELOG.md"; then
        echo "✓ CHANGELOG.md describes the schema cache error clarification"
    else
        echo "✗ CHANGELOG.md missing schema cache error description"
        test_status=1
    fi
else
    echo "✗ CHANGELOG.md not found"
    test_status=1
fi

echo ""
echo "Checking Admin.hs checks schema cache state..."
if [ -f "src/PostgREST/Admin.hs" ]; then
    echo "✓ src/PostgREST/Admin.hs exists"

    if grep -q "isSchemaCacheLoaded" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin.hs checks isSchemaCacheLoaded (fix applied)"
    else
        echo "✗ Admin.hs does not check isSchemaCacheLoaded (fix missing)"
        test_status=1
    fi

    if grep -q "getDbStructure appState" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin.hs calls getDbStructure (fix applied)"
    else
        echo "✗ Admin.hs does not call getDbStructure (fix missing)"
        test_status=1
    fi

    if grep -q "isConnectionUp" "src/PostgREST/Admin.hs"; then
        echo "✓ Admin.hs checks isConnectionUp (fix applied)"
    else
        echo "✗ Admin.hs does not check isConnectionUp (fix missing)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Admin.hs not found"
    test_status=1
fi

echo ""
echo "Checking Error.hs uses NoSchemaCacheError..."
if [ -f "src/PostgREST/Error.hs" ]; then
    if grep -q "NoSchemaCacheError" "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs has NoSchemaCacheError (fix applied)"
    else
        echo "✗ Error.hs missing NoSchemaCacheError (fix not applied)"
        test_status=1
    fi

    if grep -q "Could not query the database for the schema cache. Retrying." "src/PostgREST/Error.hs"; then
        echo "✓ Error.hs has correct schema cache error message"
    else
        echo "✗ Error.hs missing correct error message"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Error.hs not found"
    test_status=1
fi

echo ""
echo "Checking AppState.hs putDbStructure signature..."
if [ -f "src/PostgREST/AppState.hs" ]; then
    if grep -q "putDbStructure :: AppState -> Maybe DbStructure -> IO ()" "src/PostgREST/AppState.hs"; then
        echo "✓ putDbStructure has correct signature (Maybe DbStructure)"
    else
        echo "✗ putDbStructure has wrong signature (should take Maybe DbStructure)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/AppState.hs not found"
    test_status=1
fi

echo ""
echo "Checking App.hs uses NoSchemaCacheError..."
if [ -f "src/PostgREST/App.hs" ]; then
    if grep -q "throwError Error.NoSchemaCacheError" "src/PostgREST/App.hs"; then
        echo "✓ App.hs throws NoSchemaCacheError (fix applied)"
    else
        echo "✗ App.hs does not throw NoSchemaCacheError (fix missing)"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/App.hs not found"
    test_status=1
fi

echo ""
echo "Checking Workers.hs sets putDbStructure Nothing on error..."
if [ -f "src/PostgREST/Workers.hs" ]; then
    if grep -q "putDbStructure appState Nothing" "src/PostgREST/Workers.hs"; then
        echo "✓ Workers.hs calls putDbStructure with Nothing on error (fix applied)"
    else
        echo "✗ Workers.hs does not call putDbStructure with Nothing (fix missing)"
        test_status=1
    fi

    if grep -q "putDbStructure appState (Just dbStructure)" "src/PostgREST/Workers.hs"; then
        echo "✓ Workers.hs calls putDbStructure with Just on success (fix applied)"
    else
        echo "✗ Workers.hs does not call putDbStructure correctly"
        test_status=1
    fi
else
    echo "✗ src/PostgREST/Workers.hs not found"
    test_status=1
fi

echo ""
echo "Verifying HEAD test files were copied correctly..."
if [ -f "test/Main.hs" ]; then
    echo "✓ test/Main.hs exists (HEAD version)"

    if grep -q "putDbStructure appState (Just baseDbStructure)" "test/Main.hs"; then
        echo "✓ Test file has correct putDbStructure call (with Just/Maybe)"
    else
        echo "✗ Test file has wrong putDbStructure call"
        test_status=1
    fi
else
    echo "✗ test/Main.hs not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/io-tests/db_config.sql" ]; then
    echo "✓ test/io-tests/db_config.sql exists (HEAD version)"

    if grep -q "limited_authenticator" "test/io-tests/db_config.sql"; then
        echo "✓ db_config.sql has limited_authenticator (fix applied)"
    else
        echo "✗ db_config.sql missing limited_authenticator (fix not applied)"
        test_status=1
    fi

    if grep -q "no_schema_cache_for_limited_authenticator" "test/io-tests/db_config.sql"; then
        echo "✓ db_config.sql has schema cache test setup function"
    else
        echo "✗ db_config.sql missing schema cache test setup"
        test_status=1
    fi
else
    echo "✗ test/io-tests/db_config.sql not found - HEAD file not copied!"
    test_status=1
fi

if [ -f "test/io-tests/test_io.py" ]; then
    echo "✓ test/io-tests/test_io.py exists (HEAD version)"

    if grep -q "test_admin_ready_includes_schema_cache_state" "test/io-tests/test_io.py"; then
        echo "✓ Test file has test_admin_ready_includes_schema_cache_state (fix applied)"
    else
        echo "✗ Test file missing test_admin_ready_includes_schema_cache_state (fix not applied)"
        test_status=1
    fi
else
    echo "✗ test/io-tests/test_io.py not found - HEAD file not copied!"
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
