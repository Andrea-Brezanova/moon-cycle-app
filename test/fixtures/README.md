# Test fixtures

## `cycle_ts_phase_ranges.json`
The phase ranges produced by the approved reference algorithm, `design/code/cycle.ts` (`phaseRanges`), for **every valid combination** of cycle length 21–45, period length 2–10 and luteal length 10–16: 1,575 cases.

`test/features/cycle/domain/phase_ranges_test.dart` checks that the Dart port returns exactly the same ranges for all of them.

**What this proves:** the Dart implementation matches the approved reference algorithm, day for day.
**What it does not prove:** that the algorithm's assumptions are medically right (a 14-day luteal default, a 4-day ovulatory window around an estimated ovulation day, the minimum phase lengths). The phases are calculated estimates, not observations of the user's body, and the app must never present them as confirmed biological events.

**How it was made (11 October 2026):** `phaseRanges` from `design/code/cycle.ts` was run once with Node 20 (tsx), outside this repository, for the 1,575 combinations. `sourceSha256` and `sourceGitBlob` record the hashes of the `cycle.ts` that produced it. The test compares `sourceGitBlob` with `git hash-object design/code/cycle.ts` and fails if the reference file changes, so the fixture can't silently go stale. The reference is immutable (see `design/`), so this fixture shouldn't need regenerating.
