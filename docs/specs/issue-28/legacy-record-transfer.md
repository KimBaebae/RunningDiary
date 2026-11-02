# 기존 기록 서버 전송 (1차)

## 범위

SwiftData의 기존 기록을 로그인한 계정에 사용자가 요청할 때 가져온다. 양방향 수정·삭제 동기화, HealthKit 원본 재조회, 기존 로컬 기록 삭제는 포함하지 않는다. SwiftData 모델·스키마·MigrationPlan은 바꾸지 않는다.

- 앱 기준: `feat/diary-request-payload`의 `a198ac1`.
- 서버 기준: `develop`의 `81cbdc2`. 2026-10-22 조회 시 마지막 성공한 개발 배포도 이 SHA였다. 운영 main은 `b4ac53b`로 JSON 다이어리 생성 구현보다 이전이다.
- 서버 로컬 디렉토리는 커넥터로 읽은 develop 소스 스냅샷이다. 로컬 초기 커밋은 원격 이력이 아니다. 변경 패치를 실제 서버 develop 기반 작업 브랜치에 적용한다.
- 이전 스킬/배포 규칙 변경은 별도 작업이다. 서버 main 자동 운영 배포 설정은 그대로이므로 이 기능 개발을 위해 main을 바로 머지하지 않는다.

## 계약

`PUT /api/v1/running-logs/legacy-imports/{recordUUID}`

인증: 현재 계정의 Bearer access token. 요청:

```json
{
  "schemaVersion": 1,
  "snapshotJSON": "<SwiftData 영속 필드 30개를 담은 JSON 원문>"
}
```

snapshotJSON은 `LegacyRecordSnapshot`의 Codable 출력이다.
- id: SwiftData에 이미 저장된 UUID. HealthKitWorkout을 재구성하면서 생성되는 UUID를 사용하지 않는다.
- date/startTime/endTime: UTC Unix epoch 초 Double. 원래 저장된 소수 정밀도를 보존한다.
- distance: km, duration: 초. 모든 원본 스칼라를 보존한다.
- routeData: Data의 base64. 경로를 재인코딩·다운샘플하지 않는다.
- nil: JSON의 생략/nullable을 허용한다. 시간대·누락된 날씨·운동 UUID를 추정하지 않는다.
- 메모를 자르거나 trim하지 않는다. 수동 날씨, 알 수 없는 enum raw 값, 원래 신발 문자열도 보존한다.

응답: `id`(서버 ID), `recordId`, `status: ready`, `snapshotJSON`, `sha256`.
`GET /api/v1/running-logs/legacy-imports/{recordUUID}`로 같은 원문을 다시 받는다. 현재 사용자 범위에서만 조회한다.

동일 계정 + source=swiftdata + 로컬 UUID의 기존 고유 인덱스를 사용한다. 한 RunningLog 문서에 요약과 원본을 함께 저장하므로 부분 저장 단계가 없다. 동시 요청도 하나의 문서로 합쳐진다. 같은 ID와 다른 원문이면 409이고 덮어쓰지 않는다. 409를 성공으로 취급하지 않는다.

일반 목록 API에도 나타나며 일반 상세의 `legacy_snapshot_json`에서도 원본을 받는다. 목록용 거리·시간·심박·케이던스·메모·신발명은 매핑한다. 목록의 정수 duration은 초 단위로 절삭되지만 원본 Double은 snapshotJSON에 유지된다. 기존 trackpoints API에 경로를 새로 생성하지 않는다. 다른 앱에서 전체 복원을 구현할 때 원본 snapshot 계약을 읽어야 한다.

원문 UTF-8 최대 2 MiB, 전체 JSON 요청은 기존 미들웨어의 5 MiB 제한을 적용한다. 초과 기록은 원본을 자르지 않고 미완료로 남긴다. 기존 healthkit 출처로 이미 업로드된 같은 운동과의 교차 출처 중복 제거는 지원하지 않는다. 레거시 저장소에는 원래 HealthKit UUID가 없기 때문이다.

## 앱 흐름

설정 → 기존 기록 서버로 보내기 → 인증된 계정과 기록 수 확인 → 순차 전송 → 각 PUT 결과와 GET 원문·ID·SHA-256 대조 → 완료 표시.

`Application Support/LegacyMigration/`에 서버 주소+계정으로 분리한 원자적 JSON 체크포인트를 저장한다. 전송 중 원문은 고정하며 완료 후에는 식별자와 해시만 남겨 전체 기록을 반복 저장하지 않는다. 앱 종료·네트워크 실패 후 다시 실행하면 완료한 항목은 건너뛰고 미완료 항목을 재전송한다. 파일 손상은 자동 초기화하지 않는다.

토큰 변경/401/403은 중단하고 재로그인을 안내한다. 사용자 취소/화면 이탈은 효과를 취소한다. 서버가 PUT을 이미 처리했더라도 다음 재시도는 같은 ID로 검증하므로 중복 생성하지 않는다. 전송 이후 로컬 내용이 달라지면 충돌로 알려주고 수정 동기화를 가장하지 않는다.

## 검증과 적용 순서

1. 서버 단위·실제 로컬 MongoDB 통합 테스트: `uv run pytest tests/running_logs -q`. 테스트 DB 전용 연결을 `TEST_MONGODB_URL`, `LEGACY_TEST_MONGODB_URL`에 지정한다.
2. 앱 전송 모듈: `swift test --package-path Dependencies/LegacyMigration`.
3. iOS: `LegacyMigrationFeatureTests`, `SettingsFeatureTests` 실행 및 앱 빌드.
4. 개발 서버에 먼저 배포하고 테스트 계정으로 소량 PUT→GET 검증. 실제 운영 토큰/사용자 기록을 테스트 픽스처에 넣지 않는다.
5. 실기기에서 실제 과거 스토어를 열어 기록 수/원문 필드를 확인한다. 로컬 합성 스토어 테스트가 실제 사용자의 과거 스토어 검증을 대신하지 않는다.
6. 서버 운영 배포 후 TestFlight에서 검증한다. 앱 출시 및 전체 기록 전송은 이 검증 뒤에 진행한다.

신규 HealthKit JSON 생성 API의 별도 계약 차이(날씨 추가 필드/nullable timezone)는 이번 레거시 경로와 분리된다. 이 가져오기 기능의 성공을 신규 기록 상시 동기화 완료로 표현하지 않는다.

## 2026-10-22 로컬 검증 결과

- 서버 러닝 로그 회귀 테스트: 62개 통과 (새 레거시 API 테스트 6개 포함). 실제 임시 MongoDB 사용.
- 전송 패키지: 9개 통과. Swift HTTP → FastAPI → MongoDB 실통신, 저장 직후 로그아웃, 재시작, 충돌, 계정/환경 분리 포함.
- iOS 27 전용 시뮬레이터: LegacyMigrationFeatureTests + SettingsFeatureTests 총 6개 통과. 앱 및 테스트 번들 빌드 성공.
- ruff 및 pyrefly 통과. 기존 의존성 deprecation 경고는 남아 있다. CI 워크플로 YAML 파싱 통과, GitHub Actions 원격 실행은 미실시.
- iOS 18.2 시뮬레이터 실행은 지연되어 중단하고 iOS 27에서 확인했다. 실제 과거 사용자 스토어와 실기기 검증은 남아 있다.
- 원격 PR, 개발/운영 배포 및 실제 사용자 기록 전송은 미실시. 먼저 서버 변경을 개발 환경에 반영하고 테스트 계정으로 재검증해야 한다.
