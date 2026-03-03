#!/bin/bash

cd /app/src

# Set up PostgreSQL for tests
export PGDATA=/tmp/pgdata
export PGHOST=/tmp
export PGUSER=postgres
export PGDATABASE=postgres

# Initialize and start PostgreSQL
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA" /tmp
su - postgres -c "initdb -D $PGDATA"
su - postgres -c "pg_ctl -D $PGDATA -o '-k /tmp' start"

# Wait for PostgreSQL to be ready
sleep 2

# Load the schema fixture
su - postgres -c "psql -h /tmp -U postgres -f /app/src/test/spec/fixtures/schema.sql"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "test/spec/Feature/Query"
cp "/tests/spec/Feature/Query/RpcSpec.hs" "test/spec/Feature/Query/RpcSpec.hs"
mkdir -p "test/spec/fixtures"
cp "/tests/spec/fixtures/schema.sql" "test/spec/fixtures/schema.sql"

# CRITICAL: Run ONLY the specific test files from the PR, NOT the entire test suite!
# The test files to run are: "test/spec/Feature/Query/RpcSpec.hs" "test/spec/fixtures/schema.sql"
#
# TODO: Fill in the actual test command to run ONLY these specific files
#
# DO NOT run the entire test suite - it's too slow and may have unrelated failures!
#
# Examples for different languages/frameworks:
#
# Python (pytest with uv):
#   # If using uv venv at /opt/venv:
#   source /opt/venv/bin/activate
#   uv pip install -e . --no-deps 2>/dev/null || true  # Reinstall to pick up changes
#   pytest -xvs path/to/test_file.py
#   # Or without venv activation:
#   /opt/venv/bin/pytest -xvs path/to/test_file.py
#
# JavaScript/TypeScript (IMPORTANT: disable coverage thresholds when running subset!):
#   npx jest path/to/test.js path/to/test2.js --coverage=false
#   npx vitest run path/to/test.ts --coverage.enabled=false
#   npx mocha path/to/test.js path/to/test2.js
#   npx borp path/to/test.js --no-check-coverage   # Used by fastify, pino, etc.
#   npx tap path/to/test.js --no-check-coverage    # Node TAP framework
#   npx ava path/to/test.js                        # AVA framework
#
#   CRITICAL for JS/TS: DO NOT use "npm test" or "npm run test" without args!
#   These run the ENTIRE suite. Pass specific files via the test runner directly.
#   If you must use npm: npm run test -- path/to/test.js (note the -- separator)
#
# Go:
#   go test -v ./path/to/package/...
#   go test -v -run TestSpecificName ./...
#
# Rust:
#   cargo test --test test_name -- --nocapture
#   cargo test specific_test_name -- --nocapture
#
# Ruby (RSpec/Minitest):
#   bundle exec rspec path/to/spec.rb
#   bundle exec ruby -Itest path/to/test.rb
#
# Java (JUnit/Maven/Gradle):
#   mvn test -Dtest=TestClassName
#   gradle test --tests TestClassName

# Run the specific test using HSpec's --match flag to filter to RpcSpec
# The --match flag matches against the test description path
stack test --test-arguments "--match 'remote procedure call'"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
