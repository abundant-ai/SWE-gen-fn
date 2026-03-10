#!/bin/bash

cd /app/src

# Set environment variables for tests
export PATH="/root/.local/bin:${PATH}"

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "hledger/test/cli"
cp "/tests/hledger/test/cli/a.timeclock" "hledger/test/cli/a.timeclock"
mkdir -p "hledger/test/cli"
cp "/tests/hledger/test/cli/b.timedot" "hledger/test/cli/b.timedot"
mkdir -p "hledger/test/cli"
cp "/tests/hledger/test/cli/multiple-files.test" "hledger/test/cli/multiple-files.test"
mkdir -p "hledger/test/errors"
cp "/tests/hledger/test/errors/csvnoinclude.test" "hledger/test/errors/csvnoinclude.test"
mkdir -p "hledger/test/journal/include/.cycle"
cp "/tests/hledger/test/journal/include/.cycle/cycle.j" "hledger/test/journal/include/.cycle/cycle.j"
mkdir -p "hledger/test/journal/include/.cycle/cycle2"
cp "/tests/hledger/test/journal/include/.cycle/cycle2/cycle2.j" "hledger/test/journal/include/.cycle/cycle2/cycle2.j"
mkdir -p "hledger/test/journal/include/.cycle"
cp "/tests/hledger/test/journal/include/.cycle/cycleglob.j" "hledger/test/journal/include/.cycle/cycleglob.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/.dota.j" "hledger/test/journal/include/.dota.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/a.j" "hledger/test/journal/include/a.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/a.timeclock" "hledger/test/journal/include/a.timeclock"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/a2.j" "hledger/test/journal/include/a2.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/b.timedot" "hledger/test/journal/include/b.timedot"
mkdir -p "hledger/test/journal/include/b/.dotdir"
cp "/tests/hledger/test/journal/include/b/.dotdir/dotdirb.j" "hledger/test/journal/include/b/.dotdir/dotdirb.j"
mkdir -p "hledger/test/journal/include/b"
cp "/tests/hledger/test/journal/include/b/b.j" "hledger/test/journal/include/b/b.j"
mkdir -p "hledger/test/journal/include/b/bb/.dotdir"
cp "/tests/hledger/test/journal/include/b/bb/.dotdir/dotdirbb.j" "hledger/test/journal/include/b/bb/.dotdir/dotdirbb.j"
mkdir -p "hledger/test/journal/include/b/bb"
cp "/tests/hledger/test/journal/include/b/bb/bb.j" "hledger/test/journal/include/b/bb/bb.j"
mkdir -p "hledger/test/journal/include/c"
cp "/tests/hledger/test/journal/include/c/c.j" "hledger/test/journal/include/c/c.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/include.test" "hledger/test/journal/include/include.test"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/self.j" "hledger/test/journal/include/self.j"
mkdir -p "hledger/test/journal/include"
cp "/tests/hledger/test/journal/include/selfglob.j" "hledger/test/journal/include/selfglob.j"
mkdir -p "hledger/test"
cp "/tests/hledger/test/timeclock.test" "hledger/test/timeclock.test"

# Run the specific test files with shelltestrunner
shelltest --execdir \
  hledger/test/cli/multiple-files.test \
  hledger/test/errors/csvnoinclude.test \
  hledger/test/journal/include/include.test \
  hledger/test/timeclock.test
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
