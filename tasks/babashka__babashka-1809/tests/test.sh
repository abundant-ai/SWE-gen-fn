#!/bin/bash

cd /app/src

# Set environment variables for Clojure tests
export LEIN_ROOT=true
unset BABASHKA_PRELOADS
unset BABASHKA_CLASSPATH
unset BABASHKA_PRELOADS_TEST

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test-resources/lib_tests/cheshire/test"
cp "/tests/test-resources/lib_tests/cheshire/test/core.clj" "test-resources/lib_tests/cheshire/test/core.clj"
mkdir -p "test-resources/lib_tests/cheshire/test"
cp "/tests/test-resources/lib_tests/cheshire/test/multi.json" "test-resources/lib_tests/cheshire/test/multi.json"
mkdir -p "test-resources/lib_tests/cheshire/test"
cp "/tests/test-resources/lib_tests/cheshire/test/pass1.json" "test-resources/lib_tests/cheshire/test/pass1.json"

# Set up babashka test environment
export BABASHKA_TEST_ENV=jvm
export BABASHKA_CLASSPATH=$(cd /app/src && clojure -Spath -A:lib-tests)

# Run the specific test namespace using babashka via leiningen
cd /app/src
lein bb -cp "$BABASHKA_CLASSPATH" -f "test-resources/lib_tests/babashka/run_all_libtests.clj" cheshire.test.core
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
