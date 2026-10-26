# iOS delivery

배포 절차와 후보 검증은 [앱 배포 전략](../docs/engineering/delivery.md)을 따른다.

- `beta`: 검증된 후보를 빌드하여 TestFlight에 업로드하고 빌드 식별 아티팩트를 남긴다.
- `release`: 지정된 기존 TestFlight 빌드만 심사 제출하며 자동 공개하지 않는다.
- `sync_certs`: 별도 승인된 인증서 관리 작업이다. 일반 배포에서 실행하지 않는다.

실행은 main의 수동 GitHub Actions를 사용한다. 워크플로 가드를 우회하는 로컬 lane 실행은 표준 배포 경로가 아니다.
