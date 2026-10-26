# Contributing

## Branches and integration
- `main` is the only permanent integration branch and stays buildable.
- Start a small `feature/`, `fix/`, `refactor/`, `docs/` or `chore/` branch from current main. Aim to merge within one or two development sessions; split long work into independently safe changes.
- Use a concise PR, inspect the diff, run relevant checks, then squash merge and delete the merged branch. A solo maintainer does not need another reviewer. Agent permission to develop does not itself authorize merging.
- No standing develop/release branches. Record released versions with immutable tags; create a temporary maintenance branch from a released tag only when needed, then bring the fix back to main.
- Existing long-lived branches must first be reviewed and integrated deliberately. Never reset main to a feature branch or bulk-delete unmerged work.

## Issues, commits and PRs
- Use English types and Korean descriptions: `feat: 기록 동기화 추가`.
- Append `(#number)` / `Closes #number` when an issue exists; do not create an issue solely to satisfy formatting.
- Keep commits atomic, no emojis or generated-agent attribution / Co-Authored-By trailers.
- Prefer PRs under 500 changed lines; explain behavior, reason and verification using the repository template where applicable.

## Delivery
Merging integrates code; production delivery is explicitly initiated. Follow `docs/engineering/delivery.md` and the `runningdiary-deploy` skill. Main runs relevant CI automatically. TestFlight upload, App Store submission, public release and GitHub release publication are explicit separate milestones. Server policy belongs to its own repository and maintainer.


## PR visual evidence

UI or simulator-observable behavior changes require a short recording in the PR body showing the changed interaction and result. Screenshots are supplemental, not a substitute.

- Upload via the PR editor attachment control and verify playback; do not provide only a local path or commit large video files.
- Label each clip with its scenario, device/OS and real versus fixture data/server. Do not expose secrets or real user records.
- For nonvisual changes, mark not applicable and explain why.
- If recording/upload is blocked, state the reason and remaining action, and keep the affected PR Draft until attachment is complete.
- This applies equally to Codex, Claude Code and manual PR creation.

## Review handling and transition
- Review comments require a proposed solution and user approval before edits/push; existing approval covers the agreed solution.
- During the one-time transition, keep #32 and #33 stacked until the existing release history has entered main. Follow the adoption sequence in `docs/engineering/delivery.md`; do not retarget a PR if doing so folds unrelated historical changes into its diff.
- A PR merge does not authorize delivery. Do not start paid trials or additional paid AI features.
