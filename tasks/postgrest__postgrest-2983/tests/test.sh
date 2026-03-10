#!/bin/bash

cd /app/src

export CI=true

test_status=0

echo "Verifying fix has been applied..."
echo ""

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/io"
cp "/tests/io/test_io.py" "test/io/test_io.py"
mkdir -p "test/io"
cp "/tests/io/util.py" "test/io/util.py"
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/ServerTimingSpec.hs" "test/spec/Feature/Query/ServerTimingSpec.hs"
mkdir -p "test/spec"
cp "/tests/spec/SpecHelper.hs" "test/spec/SpecHelper.hs"

# Check that postgrest.cabal includes PostgREST.Response.Performance module
echo "Checking postgrest.cabal for Performance module..."
if grep -q 'PostgREST.Response.Performance' "postgrest.cabal"; then
    echo "✓ postgrest.cabal includes Performance module"
else
    echo "✗ postgrest.cabal missing Performance module - fix not applied"
    test_status=1
fi

# Check that PostgREST/Response/Performance.hs exists and has the ServerTimingData type
echo "Checking PostgREST/Response/Performance.hs exists..."
if [ -f "src/PostgREST/Response/Performance.hs" ]; then
    echo "✓ PostgREST/Response/Performance.hs exists"

    echo "Checking Performance.hs for ServerTimingData type..."
    if grep -q 'type ServerTimingData' "src/PostgREST/Response/Performance.hs"; then
        echo "✓ Performance.hs has ServerTimingData type"
    else
        echo "✗ Performance.hs missing ServerTimingData type - fix not applied"
        test_status=1
    fi

    echo "Checking Performance.hs for renderServerTimingHeader function..."
    if grep -q 'renderServerTimingHeader' "src/PostgREST/Response/Performance.hs"; then
        echo "✓ Performance.hs has renderServerTimingHeader function"
    else
        echo "✗ Performance.hs missing renderServerTimingHeader function - fix not applied"
        test_status=1
    fi

    echo "Checking Performance.hs for ServerMetric type..."
    if grep -q 'data ServerMetric' "src/PostgREST/Response/Performance.hs"; then
        echo "✓ Performance.hs has ServerMetric type"
    else
        echo "✗ Performance.hs missing ServerMetric type - fix not applied"
        test_status=1
    fi
else
    echo "✗ PostgREST/Response/Performance.hs does not exist - fix not applied"
    test_status=1
fi

# Check that App.hs imports the Performance module
echo "Checking App.hs for Performance module import..."
if grep -q 'PostgREST.Response.Performance' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports Performance module"
else
    echo "✗ App.hs missing Performance module import - fix not applied"
    test_status=1
fi

# Check that App.hs imports ServerTimingData and renderServerTimingHeader
echo "Checking App.hs for ServerTimingData import..."
if grep -q 'ServerTimingData' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports ServerTimingData"
else
    echo "✗ App.hs missing ServerTimingData import - fix not applied"
    test_status=1
fi

echo "Checking App.hs for renderServerTimingHeader import..."
if grep -q 'renderServerTimingHeader' "src/PostgREST/App.hs"; then
    echo "✓ App.hs imports renderServerTimingHeader"
else
    echo "✗ App.hs missing renderServerTimingHeader import - fix not applied"
    test_status=1
fi

# Check that Response.hs has been refactored (ServerTimingParams removed)
echo "Checking Response.hs refactoring..."
if ! grep -q 'ServerTimingParams' "src/PostgREST/Response.hs"; then
    echo "✓ Response.hs has been refactored (ServerTimingParams removed)"
else
    echo "✗ Response.hs still has ServerTimingParams - fix not applied"
    test_status=1
fi

# Check that util.py has the parse_server_timings_header function
echo "Checking test/io/util.py for parse_server_timings_header function..."
if grep -q 'def parse_server_timings_header' "test/io/util.py"; then
    echo "✓ util.py has parse_server_timings_header function"
else
    echo "✗ util.py missing parse_server_timings_header function - fix not applied"
    test_status=1
fi

# Check that test_io.py has server timing tests
echo "Checking test/io/test_io.py for server timing tests..."
if grep -q 'server_timing\|Server-Timing' "test/io/test_io.py"; then
    echo "✓ test_io.py has server timing tests"
else
    echo "✗ test_io.py missing server timing tests - fix not applied"
    test_status=1
fi

# Check that ServerTimingSpec.hs exists and has specs
echo "Checking test/spec/Feature/Query/ServerTimingSpec.hs for specs..."
if grep -q 'Server-Timing' "test/spec/Feature/Query/ServerTimingSpec.hs"; then
    echo "✓ ServerTimingSpec.hs has Server-Timing specs"
else
    echo "✗ ServerTimingSpec.hs missing Server-Timing specs - fix not applied"
    test_status=1
fi

# Check that SpecHelper.hs has matchServerTimingHasTiming helper
echo "Checking test/spec/SpecHelper.hs for matchServerTimingHasTiming..."
if grep -q 'matchServerTimingHasTiming' "test/spec/SpecHelper.hs"; then
    echo "✓ SpecHelper.hs has matchServerTimingHasTiming helper"
else
    echo "✗ SpecHelper.hs missing matchServerTimingHasTiming helper - fix not applied"
    test_status=1
fi

# Check that CHANGELOG.md has the fix entry
echo "Checking CHANGELOG.md for fix entry..."
if grep -q '#2983.*Server-Timing' "CHANGELOG.md"; then
    echo "✓ CHANGELOG.md has the fix entry"
else
    echo "✗ CHANGELOG.md missing fix entry - fix not applied"
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
