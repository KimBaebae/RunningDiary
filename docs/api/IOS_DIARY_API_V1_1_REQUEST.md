# iOS 러닝 다이어리 API v1.1 추가 요청 초안

작성일: 2026-08-05

대상: Run Diary iOS

상태: **검토 요청 초안 — 현재 v1 개발·배포를 차단하지 않음**

## 1. 현재 v1 수용 결과

서버는 전달받은 `Diary` 구조를 기준으로 아래 계약을 수용했다.

- `POST /api/v1/running-logs`
- `Authorization: Bearer <access-token>` 필수
- 사용자 ID는 JWT에서 결정하며 body로 받지 않는다.
- `workout.id`는 사용자별 HealthKit workout 고유키로 사용한다.
- 거리 `km`는 서버 저장 시 한 번만 `m`로 변환한다.
- 미측정 스칼라의 `0`은 서버에서 `null`로 정규화한다.
- GPS와 시계열은 목록·통계 문서와 분리해 저장한다.
- 동일 사용자의 동일 `workout.id`는 `409`로 거절한다.

## 2. 현재 앱에 우선 요청할 항목

### 2.1 `Idempotency-Key` 헤더

오프라인 큐나 네트워크 타임아웃 재시도 시 같은 요청에 같은 키를 보내 달라.

```http
Idempotency-Key: diary-{workout.id}
```

- 동일 키 + 동일 body: 기존 결과를 재사용한다.
- 동일 키 + 다른 body: `409 IDEMPOTENCY_KEY_REUSED`다.
- 새로운 운동에는 새로운 키를 사용한다.
- 키는 1~128자이며 로그에는 원문 대신 SHA-256 hash만 저장한다.

### 2.2 `schemaVersion` 명시

현재 서버는 필드가 없으면 `1`로 처리한다. 다음 앱 버전부터 최상위에 명시해 달라.

```json
{
  "schemaVersion": 1,
  "workout": {}
}
```

### 2.3 인코딩 후 body 크기 제한

서버의 요청 제한은 **UTF-8 JSON 전체 5MiB**다. `route` 50,000점과 지표별 `series` 2,000점을 동시에 보내면 점수 제한 이내여도 전체 JSON이 5MiB를 넘을 수 있다.

- `JSONEncoder` 결과의 `Data.count`를 전송 직전에 확인한다.
- 4.5MiB를 초과하면 route를 순서 보존 균등 샘플링으로 추가 축약한다.
- `routeOriginalPointCount`는 최초 원본 개수를 유지한다.
- `routeSamplingMethod`는 축약했다면 `uniform`을 유지한다.
- 서버 절대 상한은 route 50,000점, 각 series 2,000점이다.
- 초과 응답은 `413`이며 해당 payload를 그대로 무한 재시도하지 않는다.

## 3. v1.1 필드 협의 요청

아래 항목은 현재 엔티티 미러링 원칙을 존중해 v1에 강제하지 않는다. 필요한 필드와 enum을 합의한 뒤 `schemaVersion: 2`에서 추가하는 방식을 제안한다.

### 3.1 시간대 출처

`timeZone`만으로는 운동 당시 위치 기준인지 업로드 시점 기기 기준인지 알 수 없다.

```json
"timeZoneSource": "workoutLocation"
```

제안 enum:

- `workoutLocation`: 운동 위치로 계산
- `deviceAtWorkout`: 운동 당시 기기 시간대
- `deviceAtUpload`: 업로드 시점 기기 시간대
- `unknown`

이 값이 있어야 여행·서머타임 상황에서도 현지 날짜, 주간 통계, 연속 러닝을 정확히 계산할 수 있다.

### 3.2 러닝 타입 출처와 미확정 상태

현재 `runningType`은 `outdoor | treadmill`만 허용한다. 추론 실패를 outdoor로 강제하지 않도록 아래 확장을 요청한다.

```json
"runningType": "unknown",
"runningTypeSource": "healthKit"
```

제안 source enum: `healthKit | routeInference | user | unknown`.

### 3.3 총 에너지의 결측 의미

기초대사 값을 얻지 못했을 때 `totalEnergyBurned = activeEnergyBurned`로 복사하면 실제 총 에너지와 측정 실패를 구분할 수 없다. v1.1에서는 미측정이면 `null`을 요청한다.

```json
"activeEnergyBurned": 512.4,
"totalEnergyBurned": null
```

### 3.4 사용자 소유 신발 식별자

현재 `shoeId`는 카탈로그 모델 ID다. 같은 모델을 두 켤레 보유하면 개별 누적거리와 교체 주기를 계산할 수 없다.

```json
"shoeId": "catalog-object-id",
"userShoeId": "user-shoe-object-id"
```

- `shoeId`: 모델·브랜드 스냅샷용
- `userShoeId`: 사용자 소유 한 켤레의 수명·누적거리용
- `userShoeId`는 현재 로그인 사용자 소유인지 서버가 검증한다.

### 3.5 날씨 원시값 확장

현재 `temperature`, `humidity`, `windSpeed`는 저장한다. 체감온도·운량·강수와 퍼포먼스 상관 분석을 위해 WeatherKit 원시값을 선택적으로 요청한다.

```json
{
  "apparentTemperature": 28.1,
  "cloudCover": 0.72,
  "precipitationIntensity": 0.0
}
```

표시용 카테고리 문자열 대신 원시 수치를 보내고, 분류 기준은 서버나 앱 버전별로 다시 계산할 수 있게 한다.

## 4. 현재 서버 응답 계약

성공:

```json
{
  "id": "68f1a2b3c4d5e6f701234567",
  "source": "healthkit",
  "workoutId": "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
  "createdAt": "2026-08-05T06:00:00Z",
  "idempotencyReplayed": false
}
```

주요 오류:

| HTTP | `detail.code` | 앱 처리 |
|---|---|---|
| `401` | 없음 | 토큰 갱신 또는 재로그인 |
| `409` | `WORKOUT_ALREADY_EXISTS` | 성공 동기화로 간주하고 중복 업로드 중지 |
| `409` | `IDEMPOTENCY_KEY_REUSED` | 새 요청 키 생성이 아니라 로컬 요청 매핑 오류를 수정 |
| `413` | 없음 | route 추가 축약 후 새 body로 재시도 |
| `422` | `SHOE_NOT_FOUND` 또는 검증 상세 | 신발 동기화 또는 payload 수정 후 재시도 |

## 5. 이 저장 구조로 제공 가능한 기능

- 현지 날짜 기준 캘린더·주/월간 통계·연속 러닝
- 거리·페이스·심박·케이던스·파워 추세와 개인 기준선
- split·lap·zone 기반 구간 분석
- route 지도 재생, 고도 프로파일, 위치 기반 날씨 결합
- 통증 부위·러닝 스타일·강도와 훈련량의 상관관계
- 사용자 신발별 누적거리·교체 알림
- 원본 개수와 샘플링 방식을 이용한 데이터 품질 표시
- 멱등 재시도와 `pending → ready/failed` 상태를 이용한 안정적인 오프라인 동기화

## 6. 확인 요청

1. 다음 앱 버전에서 `Idempotency-Key`와 `schemaVersion`을 먼저 반영할 수 있는가?
2. 전송 직전 5MiB 제한을 기준으로 route를 추가 축약할 수 있는가?
3. `timeZoneSource`, `runningTypeSource`, `unknown` enum을 v1.1 엔티티에 추가할 수 있는가?
4. `totalEnergyBurned` 미측정을 `null`로 구분할 수 있는가?
5. 사용자별 신발 기능 도입 시 `userShoeId`를 함께 저장할 수 있는가?
6. WeatherKit 확장 원시값 세 항목의 수집 가능 OS 범위를 확인해 줄 수 있는가?
