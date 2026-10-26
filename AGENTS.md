# RunningDiary 공통 작업 규칙

Codex와 Claude Code 모두 이 문서와 `CONTRIBUTING.md`를 따른다.

- 앱: SwiftUI, TCA, SwiftData, HealthKit. 기능은 `RunDiary/Sources/Features/`, 공유 코드는 `Dependencies/`에 있다.
- TCA는 State/Action 경계를 유지하고 Client 의존성을 mock으로 주입한다. Reducer 테스트는 TestStore, 테스트 설명은 한국어, `make*` 헬퍼와 명시적인 기대값을 사용한다.
- 기존 SwiftData 스키마와 사용자 기록을 보존한다. 서버 DTO 매핑과 이관 체크포인트는 영속 모델과 분리한다.
- 기능 개발: `.agents/skills/runningdiary-feature/SKILL.md`.
- 배포: `.agents/skills/runningdiary-deploy/SKILL.md`와 `docs/engineering/delivery.md`.
- 다른 세션의 미커밋 변경을 보존한다. `.handoff/CURRENT.md`가 있으면 읽고 작업 종료 시 갱신한다.
- 코드 변경은 관련 테스트, 문서·배포 설정 변경은 링크·구문·배포 가드 검증을 수행한다. 화면이나 관찰 가능한 동작 변경은 CONTRIBUTING의 PR 녹화 규칙을 적용한다.
- 리뷰 코멘트는 현재 코드와 대조한 뒤 해결안·영향을 제시하고 사용자 승인 후 수정·push한다. 이미 승인된 해결안은 재확인하지 않는다.
- 별도 유료 AI API, 유료 체험·유료 전환·추가 과금에 동의하지 않는다. 별도 승인 없이 과금될 예정이라는 안내가 나타나면 작업을 멈추고 사용자에게 알린다.
- GitHub 쓰기는 개인 계정 `khyeji98`을 검증한 뒤 수행한다. Chrome은 Hyeji 프로필을 사용한다.
- 실제 PR/push/CI 재실행 뒤 설치된 `runningdiary-ci-watch` 스킬이 있으면 적용한다. 배포는 별도 승인된 수동 실행만 감시하며 자동 dispatch하지 않는다. 로컬 준비만으로 감시를 켜지 않는다.
- 서버는 별도 저장소·담당자 소관이다. 필요한 API 변경 PR과 리뷰 요청까지만 수행하며 앱 규칙으로 서버 브랜치·배포 정책을 바꾸지 않는다.
