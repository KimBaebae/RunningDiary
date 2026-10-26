---
name: runningdiary-feature
description: RunningDiary iOS 기능 추가와 버그 수정을 작은 브랜치에서 구현하고 검증해 PR로 준비한다. 프로젝트의 TCA, SwiftData 보존 및 API 계약 규칙을 적용한다.
---

# RunningDiary feature

Read root `AGENTS.md`, `CONTRIBUTING.md` and applicable repository rules. Paths below are repository-root relative.

1. Inspect git status, remote and branch. Preserve unrelated edits. Use a short task branch from main; when explicitly continuing an existing branch, keep that base and report the integration dependency.
2. Read the affected product spec, implementation and existing tests. State intended user behavior, failure behavior and completion criteria briefly. Small changes need no new issue or design document; use `docs/specs/issue-N/` for issue-linked specifications.
3. Break work into small changes that can safely enter main. Implement TCA state/actions/effects and struct Clients with dependency mocks. Keep existing regression tests running. Use the separate respec skill only when asked to rewrite existing test specifications.
4. For persistence/sync: preserve legacy SwiftData schemas and data, use stable diary identities, account-scoped sync state and retry-safe uploads. Compare app request/response DTOs with the actual server branch; unknown timezone, optional weather, shoes and memo must not be silently discarded. A 409 alone does not prove successful sync.
5. Build and run relevant tests using the actual scheme/destination. For UI work apply existing Preview rules when present and verify affected UI states. For network/storage changes test meaningful failures such as retry, partial success and auth expiry. Update only relevant docs; add an ADR for consequential decisions.
6. Follow `CONTRIBUTING.md` → `PR visual evidence`: for UI or simulator-observable behavior changes, record the changed interaction and outcome, upload the video to the PR body, verify playback, and label fixtures/device/OS. Screenshots are supplemental. Keep an affected PR Draft until the recording is attached; explain blockers honestly. For nonvisual changes state why recording is not applicable. Review the diff, remove temporary debug/record modes (retain documented isolated UI-test fixtures), and prepare a concise Korean PR with verification and remaining limitations. Commit/push/open a PR when part of the requested delivery; merge only when authorized and checks pass. Never deploy as an implicit side effect of feature completion.

Completion report: behavior changed, verification performed, branch/PR and unresolved limitations. If CI cannot run, report why; never label it passed.

After actual PR/push/merge/rerun events, apply the installed `runningdiary-ci-watch` skill when available; monitor only workflows expected for that event. No automatic delivery. For new review comments, propose a solution and obtain user approval before changing code; do not ask again for the approved solution. Follow the no-paid-AI constraint in AGENTS.md.
