#!/bin/bash

cd /app/src

# Set environment variables for Clojure tests
export LEIN_ROOT=true
unset BABASHKA_PRELOADS
unset BABASHKA_CLASSPATH
unset BABASHKA_PRELOADS_TEST

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/babashka"
cp "/tests/babashka/error_test.clj" "test/babashka/error_test.clj"

# Run the specific test namespace using Leiningen
lein test babashka.error-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
