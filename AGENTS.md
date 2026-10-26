# Running Log Diary

## Overview
- **Goal**: Manage daily running logs and condition tracking
- **Core Design**: Built with predictable state management and modularized features based on TCA.
- **Key Concept**: Focused on clear state–action boundaries and data-driven UI updates.

## Tech Stack
- **Architecture**: TCA (@Reducer, State, Action, Dependency)
- **Storage**: SwiftData (Repository pattern)
- **Integration**: HealthKit (distance/heart rate/cadence/route), Shoes API, Weather API

## Main Screens
1. **Daily Logs** (Main): Date carousel, HealthKit data, pain/stride/condition, shoes, weather, route
2. **Calendar View**: Satisfaction visualization
3. **Add/Edit Log**: Import from HealthKit or manual entry

## Priorities
1. ✅ Setup
2. 🔄 Basic UI structure (date carousel, mock data)
3. ⏳ HealthKit integration
4. ⏳ Log entry screen
5. ⏳ Calendar view
6. ⏳ SwiftData + Repository
7. ⏳ External API integration

## Coding Guidelines
- **Naming**: SwiftLint + Swift API Guidelines
  - Types: UpperCamelCase (`~View`, `~Feature`)
  - Variables/functions: lowerCamelCase
- **TCA**: `@Reducer` macro, separate State/Action, `@Dependency` injection
- **Access Control**: default internal, private when unnecessary

## Testing Strategy (Swift Testing + TCA)
- **Testing**: Reducers must use TestStore, Dependencies require mock implementations
- **Framework**: Swift Testing (`@Test`, `#expect`)
- **Naming**: `test_trigger_result`

### AI Rules (Strict)
1. **Korean Descriptions**: `@Test` macro MUST have a descriptive **Korean** name. (e.g., `@Test("버튼 클릭 시 카운트 증가")`).
2. **Helper `make*`**: MUST encapsulate `TestStore` or SUT creation in `make*` private helpers (e.g., `makeTestStore`).
3. **Expected Constants**: Define expected values as constants (`let expected...`) *before* assertions/actions for clarity.
4. **TCA Pattern**: Use `await store.send(...)` and `await store.receive(...)` with `withDependencies` for mocking.

### Compact Template
```swift
@Test("테스트 시나리오 설명(한글)")
func action_result() async {
    // Given
    let expectedVal = ...
    let store = makeTestStore(initialState: ...)
    
    // When
    await store.send(.action) {
        // Then
        $0.state = expectedVal
    }
}

// Helper (in private extension)
func makeTestStore(...) -> TestStore<State, Action> { ... }
```

See existing feature files for detailed examples

## Collaboration
Git workflow, commit/PR conventions: [CONTRIBUTING.md](./CONTRIBUTING.md)

## Handoff Protocol
세션 시작 시 `.handoff/CURRENT.md` 가 있으면 미완료 인수인계다. 먼저 읽고 목표·진행 상태·제약을 복원한 뒤 "다음 액션"부터 이어서 진행하라. 작업을 마치거나 중단할 때는 이 파일을 최신화하라(없으면 `.handoff/README.md` 참고). 노트는 코드·git으로 복원 가능한 내용은 경로/커맨드로만 참조하는 경량 문서다.

## Imported Claude Cowork project instructions

## PR visual evidence
Follow `CONTRIBUTING.md` → `PR visual evidence`: attach a playable simulator recording for UI or observable behavior changes before marking the PR ready. This applies to Codex and Claude Code.
