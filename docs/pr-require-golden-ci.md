## Summary
Makes the golden screenshot job a real gate. It was `continue-on-error: true`, so a failing golden job still showed the whole CI run as passing (this is how the Eat merge reached `main` with out-of-date goldens).

- Removed `continue-on-error: true` from `golden-tests`; updated the outdated comment (references are recorded on macOS 15 and match the runner).
- Kept the pinned `macos-15` runner and the golden test configuration unchanged.
- Documented the three checks to require on `main` in `docs/v2-ui-roadmap.md`.

No application code, UI or golden images changed.

## After merging (GitHub settings)
Settings → Branches → rule for `main`: require a pull request; require status checks to pass; require branches to be up to date; add `Format, analyze, layers, tests`, `Golden screenshots (macOS)`, `Android build (dev, debug)`.

## Testing
Workflow file parses; the run on this branch shows all three jobs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
