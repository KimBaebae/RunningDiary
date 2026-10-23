# Running Log Diary

## Overview
- **Goal**: 러닝 일지와 컨디션을 기록·관리하는 iOS 앱
- **Core Design**: TCA 기반 예측 가능한 상태 관리와 모듈화된 Feature 구조
- **Key Concept**: 명확한 State–Action 경계, 데이터 주도 UI 업데이트

## Tech Stack
- **Architecture**: TCA (@Reducer, State, Action, Dependency)
- **Storage**: SwiftData (Repository pattern)
- **Integration**: HealthKit (distance/heart rate/cadence/route), WeatherKit
- **Min Target**: iOS 18.0

## Project Structure
- `RunDiary/Sources/Features/` — Feature 모듈 (Calendar, CreateDiary, DailyDetail, Settings)
- `RunDiary/Sources/Clients/` — TCA Dependency 클라이언트 (HealthKit, Persistences, RunningRecord, Weather)
- `RunDiary/Sources/Core/` — DesignSystem, Extensions, Storage, Utils
- `RunDiary/Sources/App/` — App Entry Point
- `Dependencies/` — 로컬 Swift 패키지 (CoreNetwork, HealthKitService, Models, PersistencesService 등)
- `RunDiaryTests/` — 테스트

## Build & Run
- **빌드**: `xcodebuild -scheme RunDiary -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"`
- **테스트**: `xcodebuild test -scheme RunDiaryTests -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"`

## Testing
- **Framework**: Swift Testing (`@Test`, `#expect`)
- **TCA**: Reducer 테스트는 반드시 TestStore 사용, Dependency는 mock 구현 필수
- **Naming**: `test_trigger_result`
- **Workflow**: 기능이 이미 구현된 상태이므로 forward TDD가 아니라 **명세-우선 테스트 재작성**(이슈로 명세 → TC 매트릭스 → 기존 테스트 전체 주석화 후 TC 단위 복원)을 따른다. `feature-respec-tc` 스킬과 `.claude/rules/phases/`(phase-a/b/c), `.claude/rules/testing-convention.md` 참고.

## Workflow
- 코드 수정 완료 후 `xcodebuild` 빌드 실행
- 빌드 성공 시 `/commit` skill 실행
- 빌드 실패 시 에러 수정 후 재빌드
- 새 기능 구현 시 `@tdd` 파이프라인 실행 (PRD → TC → Test → Impl → Review)

## Key Decisions
- Navigation은 TCA tree-based (`@Reducer enum`) 사용
- CoreNetwork는 싱글톤 패키지로 분리
- TCA Dependency는 struct 기반 Client 패턴 (protocol 아님)

## Conventions
- **Code**: `~/.claude/rules/code-convention.md` (auto-loaded)
- **Commit**: `.claude/rules/commit-convention.md` (auto-loaded, 이모지 미사용)
- **TCA**: `.claude/rules/tca-convention.md` (auto-loaded)
- **Preview**: `.claude/rules/preview-convention.md` (auto-loaded)
- **Git workflow**: [CONTRIBUTING.md](./CONTRIBUTING.md)
- **Decisions**: [docs/decisions/README.md](./docs/decisions/README.md)

## Decision Records
되돌리기 어려운 판단은 `docs/decisions/NNNN-슬러그.md`에 남긴다. **한 파일에 두 개의 반**이다.

- **Ⅰ. 착수 전** — 구현을 맡기기 전에 쓴다. 결정마다 *고르지 않은 쪽과 그 이유*를 함께 적는다. 에이전트가 구현할 근거이자 리뷰의 기준선이다.
- **Ⅱ. 완료 후** — 구현이 끝나면 쓴다. Ⅰ의 "예상 위험"과 하나씩 대조한다.

**Ⅰ은 완료 후에 고치지 않는다.** 틀린 예측은 지우지 말고 Ⅱ에 "여기서 틀렸다"로 남긴다. 사후에 정답으로 덮으면 기록이 항상 옳아 보이고 아무것도 배울 수 없다.

**코드·테스트·git으로 복원 가능한 것은 쓰지 않는다** — 진행 상태표, 파일 목록, 시그니처, TC 목록. 경로와 커맨드로만 참조한다. 리팩터링·버그 수정·컨벤션대로의 구현은 기록하지 않는다(커밋 메시지로 충분하다).

## Preview Rules
- 모든 View 파일은 `#Preview` 블록을 반드시 포함한다.
- `#Preview` 블록은 파일의 **가장 마지막**에 위치하고 `// MARK: - Preview` 로 구분한다.
- 공용 더미 데이터는 `Core/Extensions/*+Preview.swift` 패턴으로 작성한다 (예: `HealthKitWorkout.preview`).

## Handoff
인수인계 프로토콜은 @AGENTS.md 의 "Handoff Protocol" 을 따른다. 세션 시작 시 `.handoff/CURRENT.md` 가 있으면 먼저 읽고 이어받는다.
## PR visual evidence
Follow `CONTRIBUTING.md` → `PR visual evidence`: UI or simulator-observable behavior changes require an attached playable recording before marking the PR ready. Codex follows the same rule.
