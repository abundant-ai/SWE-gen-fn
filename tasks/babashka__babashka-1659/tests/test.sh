#!/bin/bash

cd /app/src

# Set environment variables for Clojure tests
export LEIN_ROOT=true
unset BABASHKA_PRELOADS
unset BABASHKA_CLASSPATH
unset BABASHKA_PRELOADS_TEST

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/babashka"
cp "/tests/babashka/bb_edn_test.clj" "test/babashka/bb_edn_test.clj"
mkdir -p "test/babashka"
cp "/tests/babashka/main_test.clj" "test/babashka/main_test.clj"

# Run the specific test namespaces using Leiningen
lein test :only babashka.bb-edn-test babashka.main-test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
