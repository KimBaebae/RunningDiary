# 앱 브랜치·배포 전략

## 일상 개발

- 영구 통합 브랜치는 `main` 하나다. 최신 main에서 짧은 `feature/`, `fix/`, `docs/`, `chore/` 브랜치를 만들고 관련 CI와 리뷰를 마친 뒤 승인된 PR을 squash merge한다.
- 작업은 한두 개발 세션 안에 합칠 크기로 나눈다. 미완성 기능은 노출하지 않거나 독립적으로 안전한 부분만 통합한다. 새 작업에서 상시 develop/release 브랜치와 불필요한 PR 의존 관계를 만들지 않는다.
- PR·main의 관련 CI와 배포는 별개다. 머지, 태그 push, release 브랜치 push만으로 TestFlight/App Store 배포를 실행하지 않는다.
- 버전·릴리스노트 준비도 작은 PR로 처리한다. 배포되지 않은 작업을 릴리스에 임의로 끼워 넣지 않는다.
- 서버는 `KimBaebae/run_diary_api` 담당자의 정책을 따른다. 앱에서 서버 배포를 실행하거나 서버 브랜치 전략을 변경하지 않는다.

## 배포 스킬의 순서

1. **후보 확정:** 대상(TestFlight / App Store 심사 / 승인된 앱 공개), 버전, main에 포함된 전체 SHA를 정한다. 변경 목록과 서버 API 호환성, 실제 기존 사용자 스토어·기기 검증 증거를 확인한다. 부족한 검증은 차단 사유로 남긴다.
2. **CI 확인:** 해당 SHA의 main push `Build & Test` 성공을 확인한다. 이전 커밋이나 PR의 synthetic merge 결과로 대체하지 않는다. 문서만 바뀌어 CI가 생략됐다면 수동 `Build & Test`를 main에서 실행해 후보 SHA의 성공 증거를 확보한다. CI 실행은 배포가 아니다.
3. **사전 준비:** 후보의 Release 스킴, Secrets.xcconfig 주입, 실제 API 환경, 인증서 저장소 접근, App Store Connect 자격을 확인한다. 비밀값은 출력하지 않는다. 인증서 재발급·권한 변경은 배포 과정에 포함하지 않는다.
4. **TestFlight 업로드:** 승인된 요청이면 main에서 `testflight.yml`을 `candidate_sha`로 수동 실행한다. 워크플로는 main 포함 여부, 동일 SHA의 성공 CI, 배포 스크립트 버전을 확인한 뒤에만 secrets를 읽는다. 실행 ID를 기록하고 `ios-build-identity` 아티팩트(SHA·버전·빌드·실행 ID/attempt)를 보존한다. 업로드 성공과 Apple 처리 완료를 구분하고 실제 TestFlight 사용 가능 상태 및 기기 smoke test를 확인한다.
5. **심사 제출:** 검증한 TestFlight의 `candidate_sha`, `app_version`, `build_number`, `testflight_run_id`로 main의 `release.yml`을 수동 실행한다. 성공한 업로드 실행과 아티팩트가 정확히 일치해야 한다. 기존 바이너리만 선택하며 재빌드·새 업로드·자동 공개는 하지 않는다. 아티팩트 만료·누락 시 추정으로 진행하지 않는다.
6. **공개:** Apple 승인과 사용자의 공개 요청을 확인한 뒤 App Store Connect에서 해당 버전을 공개한다. 심사 제출만 요청했다면 여기까지 진행하지 않는다.
7. **태그·GitHub 릴리스:** 실제 공개가 확인된 후보 SHA에 `v<version>` 태그를 만들고 GitHub 릴리스를 작성한다. 변경점, 알려진 제한, 버전/빌드, 소스 SHA, TestFlight/심사 실행 링크를 포함한다. 같은 태그가 다른 SHA를 가리키면 중단하며 태그를 이동하지 않는다. TestFlight를 기록할 때는 선택적으로 `testflight/<version>-<build>`를 사용하고 정식 릴리스와 구분한다. 태그는 배포 기록이며 자동 배포 트리거가 아니다.

전체 배포 요청은 승인 범위 안의 단계를 순차 진행한다. 단순 문서/스킬 수정 요청은 배포 승인이 아니다. 이미 특정 대상의 실행을 승인했다면 같은 승인을 반복해서 묻지 않는다.

## 실행과 실패 처리

- Actions의 Run workflow에서 **main**을 선택한다. PR 브랜치에서 dispatch한 배포는 차단된다. 워크플로가 기본 브랜치에 반영돼야 수동 실행 버튼을 사용할 수 있다.
- 배포 가드/워크플로/Fastfile이 달라진 오래된 후보는 거부한다. 현재 main 정책을 포함한 새 후보를 CI·TestFlight에서 검증한다.
- 업로드/제출이 타임아웃 나면 실행·App Store Connect의 같은 버전/빌드를 조회한다. 무조건 재실행하여 중복 업로드하지 않는다.
- 배포 실패 시 해당 단계에서 멈추고 원인·완료된 외부 작업·복구 선택지를 보고한다. 새 코드 수정은 PR로 처리한다. 기존 사용자 데이터 삭제나 인증서 재발급으로 우회하지 않는다.
- 별도 유료 AI API, 유료 체험, 추가 과금에 동의하지 않는다. 승인 없는 과금 예정 안내는 즉시 보고한다. 무료 리뷰 한도는 기다린다.
- CI 감시가 설정되어 있으면 실제 실행 ID와 후보 SHA를 등록하고 성공·차단·기한 종료 시 끈다. 감시를 켠다는 이유로 배포를 실행하지 않는다.

## 기존 브랜치의 일회성 전환

2026-10-26 확인: main `373f8e0`에는 release/v1.2.0 `61e0e76`의 과거 변경 275개 파일이 아직 없다. #32만 main으로 바꾸면 이 변경까지 섞인다.

1. 이 정책 PR을 먼저 main에 반영한다. 기존 자동 App Store 제출 및 release push TestFlight 트리거를 제거한다. 적용 전에는 옛 release/hotfix→main PR을 머지하지 않는다.
2. 기존 release 작업은 별도의 일회성 통합 PR로 main에 가져온다. 정책 PR의 수동 배포 설정·Fastfile·공통 규칙을 보존하고, 기존 release의 앱 코드·스키마 이력·테스트는 누락 없이 검토한다. 이 통합은 이력 보존용 merge commit을 사용한다(squash 예외). 기존 release를 리셋하거나 선제 삭제하지 않는다.
3. release 기준 이력이 main에 들어온 뒤 #32의 base를 main으로 변경한다. 정책 문서·배포 설정을 유지하고 최신 main과 통합한 CI를 다시 확인한다. 명세 이동 리뷰는 반영됐지만 서버 #5 배포·테스트 계정 왕복·실제 과거 스토어 검증은 별도 조건이다. 현재 사용자에게 노출되는 전송 기능은 서버 준비 또는 별도 승인된 비노출 처리 없이 준비 완료로 간주하지 않는다.
4. #33은 #32를 기반으로 한 기존 예외다. #32가 main에 반영된 뒤 #33을 main 기준으로 옮겨 중복 변경을 제거하고 CI·무료 리뷰를 다시 확인한다. 기존 녹화·UI 테스트를 유지한다. #32를 squash merge했다면 #33의 고유 커밋만 main 위로 재배치해야 하므로 단순 base 변경만으로 완료했다고 판단하지 않는다.
5. 고유 변경이 모두 반영되고 열린 PR이 더 이상 참조하지 않을 때 기존 release/작업 브랜치를 삭제한다. 이 문서 작성만으로 머지·삭제·배포를 실행하지 않는다.

현재 두 PR의 설명에는 이 순서와 배포 제한을 반영한다. 전환 후 새 작업은 main에서 시작하며 임시 전환 예외를 새 상시 전략으로 확대하지 않는다.

## 근거

- [GitHub 수동 워크플로 실행](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
- [Fastlane 기존 빌드 선택 및 수동 공개](https://docs.fastlane.tools/actions/deliver/)
