## Ship Pipeline
- Run `scripts/doctor.sh` at session start to check the local environment (Xcode CLI, simulators, gh auth). It is read-only and safe to re-run.
- Never claim a build, test, or visual check passed without pasting the actual command output.
- Always run `scripts/ship.sh` before opening a PR. It halts on the first failing gate and prints a PASS/FAIL table.
- A local git pre-push hook already runs ship.sh automatically and blocks the push if any gate fails.
- Only gate right now is the Xcode build (no test target, no SwiftLint config in this repo). This repo already has .github/workflows/ci.yml for PR-level CI — ship.sh is the local pre-push equivalent.

## Git & PR Conventions
- Commit messages follow this repo's current style: `type: 설명` (Korean, imperative, no issue number, no emoji) — e.g. `feat: 그룹 초대 코드 공유 기능 추가`. Older commits used `💄-fix :: [#issue] 설명`, but that convention was dropped; match the recent commits, not the old ones.
- No AI attribution, no emoji, no "Generated with" footers in commits or PR bodies.
- PR merges require the user's manual approval. Open the PR and stop there — never run `gh pr merge`.
