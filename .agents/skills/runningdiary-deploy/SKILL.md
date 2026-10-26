---
name: runningdiary-deploy
description: RunningDiary iOS의 검증한 main 커밋을 TestFlight에 올리거나 기존 빌드를 App Store 심사에 제출하고, 승인된 공개 이후 태그와 GitHub 릴리스를 기록한다. 서버 배포는 제외한다.
---

# RunningDiary iOS 배포

루트 `AGENTS.md`, `CONTRIBUTING.md`, `docs/engineering/delivery.md`를 읽고 배포 순서를 따른다. 서버는 별도 담당자 소관이며, 필요한 API의 배포 증거만 확인한다.

1. 요청 대상과 이미 승인된 범위를 확인한다. TestFlight·심사 제출·공개를 구분하고 main에 포함된 전체 SHA와 버전을 고정한다. 준비/스킬 수정 요청만으로 배포하지 않는다.
2. 문서의 일회성 브랜치 전환이 끝났는지 확인한다. 전환 중인 기존 release 작업을 후보에 몰래 포함하거나 브랜치를 삭제하지 않는다. 새 버전·릴리스노트 변경은 짧은 main 대상 PR로 준비한다.
3. 후보 SHA의 성공 CI, API 호환성, 기존 SwiftData 스토어 보존, 기기 검증, 자격·서명 접근을 확인한다. 누락되면 실행 전에 해결하거나 구체적인 차단 사유를 보고한다. 서버 #5가 열려 있다는 이유만으로 배포됐다고 간주하지 않는다.
4. 승인된 TestFlight는 main의 `testflight.yml`을 candidate_sha로 dispatch한다. 실제 실행 ID/attempt와 빌드 식별 아티팩트를 확보하고 업로드·Apple 처리·기기 검증을 구분한다. 자동 과금 안내가 있으면 즉시 중단하고 알린다. 유료 AI API/체험/전환/추가 과금에 동의하지 않는다.
5. 심사 요청이 승인된 경우에만 동일한 TestFlight SHA·버전·빌드·실행 ID로 `release.yml`을 실행한다. 아티팩트 불일치·만료 시 중단한다. 다시 빌드하거나 최신 빌드를 추정해 제출하지 않는다. automatic_release는 false로 유지한다.
6. 실제 심사 상태를 확인한다. Apple 승인 후 공개가 승인된 경우에만 수동 공개한다. 외부 처리를 기다리는 상태는 완료로 보고하지 않는다.
7. 공개가 확인된 후보에 불변 `v<version>` 태그와 GitHub 릴리스를 기록한다. 변경점·제약·SHA·버전/빌드·실행 링크를 포함한다. 같은 태그의 다른 SHA는 차단 사유다. 베타에는 선택적 `testflight/<version>-<build>`만 쓰며 태그 push로 배포하지 않는다.

각 단계는 앞 단계의 증거를 요구한다. 실패·타임아웃 시 외부 상태를 먼저 확인하여 중복 업로드/제출을 피한다. 인증서 재발급, 서버 브랜치/배포 변경, 자동 머지는 이 스킬의 범위가 아니다. 이미 승인한 대상은 중복 확인하지 않고, 더 넓은 단계는 임의로 실행하지 않는다.

실제 PR/push/CI 재실행/승인된 배포 dispatch 뒤 설치된 `runningdiary-ci-watch`가 있으면 정확한 후보 SHA와 실행 ID로 감시를 연결한다. 미변경 상태의 로그를 반복해서 읽지 않는다. 새 리뷰 지적은 해결안을 제시하고 승인 후 반영한다.
