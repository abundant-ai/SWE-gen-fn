hledger’s timeclock handling currently assumes at most one active (clocked-in) session at a time, and this causes valid timeclock logs (compatible with ledger/emacs timeclock usage) to fail. In particular, consecutive clock-ins to different accounts should be allowed, and later clock-outs must be matched to the correct open session.

Problem scenarios:

1) Multiple concurrent sessions should be supported.
A timeclock log may contain multiple `i` entries in a row for different accounts, meaning multiple sessions are simultaneously active. Example:

```
i 2025-03-10 08:00:00 multi:1  description 1
i 2025-03-10 09:00:00 multi:2  description 2
o 2025-03-10 12:00:00 multi:1
o 2025-03-10 15:00:00 multi:2
```

Expected: This is accepted, producing two time entries: `multi:1` from 08:00–12:00 (4.00h) and `multi:2` from 09:00–15:00 (6.00h).
Actual (current behavior in affected versions): the second `i` can be rejected with an error like:

```
Encountered clockin entry for session "..." that is already active.
```

2) Clock-out matching rules must handle ambiguity.
A clock-out entry (`o`) can appear with or without an account name. Matching should follow these rules:
- If the `o` entry includes an account name, it must close the currently-open session for that account.
- If the `o` entry omits the account name, it must close the most recently opened (most recent unmatched `i`) session.

Example demonstrating implicit clock-outs:

```
i 2025-03-10 08:00:00 multi:1  description 1
i 2025-03-10 09:00:00 multi:2  description 2
i 2025-03-10 10:00:00 multi:3  description 3
o 2025-03-10 11:00:00
o 2025-03-10 12:00:00 multi:1
o 2025-03-10 15:00:00
```

Expected: the first `o` closes `multi:3` (10:00–11:00), the explicit `multi:1` closes 08:00–12:00, and the final implicit `o` closes `multi:2` (09:00–15:00).

3) Clock-out must error when no matching clock-in exists.
If a clock-out cannot be matched to any prior open clock-in session (either because there are no open sessions, or because an explicit account name is provided but that session is not active), hledger should fail with an error message of the form:

```
Could not find previous clockin to match this clockout.
```

4) Repeated clock-in for the same session name must still be rejected while that session is active.
While multiple different sessions may be open at once, a second `i` for the same session/account name without an intervening matching `o` should still be an error. Example:

```
i 2020/1/1 08:00
i 2020/1/1 09:00
```

Expected: error indicating that the session is already active (not silently accepted).

Implement the updated timeclock semantics so that `hledger -f timeclock:... print`, `balance`, and `check` accept valid multi-session logs, correctly pair clock-outs to the right open sessions using the rules above, and continue to produce the specified errors for unmatched clock-outs and duplicate clock-ins for the same active session.