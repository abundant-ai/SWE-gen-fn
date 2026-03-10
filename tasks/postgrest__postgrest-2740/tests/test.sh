#!/bin/bash

cd /app/src

export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/doc"
cp "/tests/doc/Main.hs" "test/doc/Main.hs"
mkdir -p "test/io"
cp "/tests/io/fixtures.sql" "test/io/fixtures.sql"
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"

test_status=0

echo "Verifying fix for fallback_application_name feature (#2647)..."
echo ""

# Check CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md has fallback_application_name fix entry..."
if grep -q "#2647" "CHANGELOG.md" && grep -q "Allow to verify the PostgREST version in SQL" "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has fallback_application_name fix entry"
else
    echo "✗ CHANGELOG.md missing fallback_application_name fix entry - fix not applied"
    test_status=1
fi

# Check Config.hs exports addFallbackAppName
echo "Checking src/PostgREST/Config.hs exports addFallbackAppName..."
if grep -q "addFallbackAppName" "src/PostgREST/Config.hs" && grep -q "module PostgREST.Config" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs exports addFallbackAppName"
else
    echo "✗ src/PostgREST/Config.hs missing addFallbackAppName export - fix not applied"
    test_status=1
fi

# Check Config.hs has Network.URI imports
echo "Checking src/PostgREST/Config.hs has Network.URI imports..."
if grep -q "import Network.URI" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has Network.URI imports"
else
    echo "✗ src/PostgREST/Config.hs missing Network.URI imports - fix not applied"
    test_status=1
fi

# Check Config.hs has addFallbackAppName function implementation
echo "Checking src/PostgREST/Config.hs has addFallbackAppName function..."
if grep -q "addFallbackAppName :: ByteString -> Text -> Text" "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has addFallbackAppName function"
else
    echo "✗ src/PostgREST/Config.hs missing addFallbackAppName function - fix not applied"
    test_status=1
fi

# Check Config.hs has the full implementation with fallback_application_name
echo "Checking src/PostgREST/Config.hs has fallback_application_name parameter..."
if grep -q 'fallback_application_name=' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs has fallback_application_name parameter"
else
    echo "✗ src/PostgREST/Config.hs missing fallback_application_name parameter - fix not applied"
    test_status=1
fi

# Check Config.hs has PostgREST version string formatting
echo "Checking src/PostgREST/Config.hs formats PostgREST version string..."
if grep -q 'pgrstVer = "PostgREST " <>' "src/PostgREST/Config.hs"; then
    echo "✓ src/PostgREST/Config.hs formats PostgREST version string"
else
    echo "✗ src/PostgREST/Config.hs missing PostgREST version string formatting - fix not applied"
    test_status=1
fi

# Check AppState.hs imports prettyVersion
echo "Checking src/PostgREST/AppState.hs imports prettyVersion..."
if grep -q "PostgREST.Version.*prettyVersion" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs imports prettyVersion"
else
    echo "✗ src/PostgREST/AppState.hs missing prettyVersion import - fix not applied"
    test_status=1
fi

# Check AppState.hs imports addFallbackAppName
echo "Checking src/PostgREST/AppState.hs imports addFallbackAppName..."
if grep -q "addFallbackAppName" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs imports addFallbackAppName"
else
    echo "✗ src/PostgREST/AppState.hs missing addFallbackAppName import - fix not applied"
    test_status=1
fi

# Check AppState.hs uses addFallbackAppName in initPool
echo "Checking src/PostgREST/AppState.hs uses addFallbackAppName in initPool..."
if grep -q "toUtf8 \$ addFallbackAppName prettyVersion configDbUri" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs uses addFallbackAppName in initPool"
else
    echo "✗ src/PostgREST/AppState.hs not using addFallbackAppName in initPool - fix not applied"
    test_status=1
fi

# Check AppState.hs uses addFallbackAppName in listener
echo "Checking src/PostgREST/AppState.hs uses addFallbackAppName in listener..."
if grep -q "acquire \$ toUtf8 (addFallbackAppName prettyVersion configDbUri)" "src/PostgREST/AppState.hs"; then
    echo "✓ src/PostgREST/AppState.hs uses addFallbackAppName in listener"
else
    echo "✗ src/PostgREST/AppState.hs not using addFallbackAppName in listener - fix not applied"
    test_status=1
fi

# Check test/doc/Main.hs includes Config.hs in doctest
echo "Checking test/doc/Main.hs includes Config.hs in doctest..."
if grep -q '"src/PostgREST/Config.hs"' "test/doc/Main.hs"; then
    echo "✓ test/doc/Main.hs includes Config.hs in doctest"
else
    echo "✗ test/doc/Main.hs missing Config.hs in doctest - fix not applied"
    test_status=1
fi

# Check test/io/fixtures.sql has get_pgrst_version function
echo "Checking test/io/fixtures.sql has get_pgrst_version function..."
if grep -q "create or replace function get_pgrst_version()" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql has get_pgrst_version function"
else
    echo "✗ test/io/fixtures.sql missing get_pgrst_version function - fix not applied"
    test_status=1
fi

# Check test/io/fixtures.sql queries pg_stat_activity
echo "Checking test/io/fixtures.sql queries pg_stat_activity for application_name..."
if grep -q "from pg_stat_activity" "test/io/fixtures.sql" && grep -q "application_name" "test/io/fixtures.sql"; then
    echo "✓ test/io/fixtures.sql queries pg_stat_activity for application_name"
else
    echo "✗ test/io/fixtures.sql not querying pg_stat_activity - fix not applied"
    test_status=1
fi

# Check test/io/test_io.py has test_get_pgrst_version_with_uri_connection_string test
echo "Checking test/io/test_io.py has test_get_pgrst_version_with_uri_connection_string test..."
if grep -q "def test_get_pgrst_version_with_uri_connection_string" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has test_get_pgrst_version_with_uri_connection_string test"
else
    echo "✗ test/io/test_io.py missing test_get_pgrst_version_with_uri_connection_string test - fix not applied"
    test_status=1
fi

# Check test/io/test_io.py has test_get_pgrst_version_with_keyval_connection_string test
echo "Checking test/io/test_io.py has test_get_pgrst_version_with_keyval_connection_string test..."
if grep -q "def test_get_pgrst_version_with_keyval_connection_string" "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py has test_get_pgrst_version_with_keyval_connection_string test"
else
    echo "✗ test/io/test_io.py missing test_get_pgrst_version_with_keyval_connection_string test - fix not applied"
    test_status=1
fi

# Check test/io/test_io.py tests fallback_application_name
echo "Checking test/io/test_io.py tests fallback_application_name..."
if grep -q 'fallback_application_name should be added to the db-uri' "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py tests fallback_application_name"
else
    echo "✗ test/io/test_io.py missing fallback_application_name tests - fix not applied"
    test_status=1
fi

# Check test/io/test_io.py calls get_pgrst_version
echo "Checking test/io/test_io.py calls get_pgrst_version..."
if grep -q '/rpc/get_pgrst_version' "test/io/test_io.py"; then
    echo "✓ test/io/test_io.py calls get_pgrst_version"
else
    echo "✗ test/io/test_io.py not calling get_pgrst_version - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
