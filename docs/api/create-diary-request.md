# 다이어리 생성 API 요청 스키마

> 대상: 백엔드 개발자
> 목적: 현재 `Diary` 엔티티를 단일 진실 소스로 삼아 다이어리 생성 요청 바디의 직렬화 계약을 정의한다.
> 기준: `Dependencies/Models/Sources/Models/Entities/` 의 엔티티 정의
> 상태: **v1.1 확정** (2026-08-14 백엔드 회신 반영). 서버와 클라이언트가 이 문서를 계약의 단일 기준으로 삼는다.

## v1.1에서 확정된 것

v1.1 추가 요청(2026-08-05) → 클라이언트 회신(2026-08-07) → 백엔드 최종 회신(2026-08-14)으로 아래가 확정됐다. 앞의 두 문서는 협의가 닫히면서 폐기했고, 결론은 이 문서와 아래 해소 표가 전부 담는다.

| 항목 | 결정 |
|---|---|
| `Idempotency-Key` | **도입하지 않는다.** `(userId, workout.id)` 기준 중복 방지 + `409 WORKOUT_ALREADY_EXISTS`로 처리 |
| `schemaVersion` | **전송하지 않는다.** 계약 버전은 `/api/v1/` URL 경로가 관리하고, breaking change는 `/api/v2/`로 가른다 |
| `timeZone` | **nullable로 변경.** 알 수 없으면 `null`. 서버는 원본 `null`을 보존하고 날짜 계산 시 UTC로 폴백한다 |
| `totalEnergyBurned` | **nullable로 변경.** 기초대사를 얻지 못하면 `null` |
| 날씨 원시값 | `apparentTemperature`(°C) · `cloudCover`(0~1) · `precipitationAmount`(mm) **추가** |
| `runningTypeSource` | 값은 `healthKit` / `distanceInference`로 합의했으나 **이번 계약에서는 전송하지 않는다.** 아래 "러닝 타입" 참고 |
| `userShoeId` | 이번 계약에서 제외. user-shoe API 설계와 함께 별도 과제 |
| 오류 응답 | `$.detail.code`(String)로 고정. 아래 "오류 처리" 참고 |
| 저장 순서 | 로컬 저장을 먼저 수행하고 `pending` 상태로 동기화 큐에 등록한다. 아래 "오류 처리" 참고 |

이 문서의 모든 필드는 앱 내부 `Diary` 엔티티와 그 하위 엔티티에서 도출한다.

`HealthKitWorkout` · `WeatherData` · `RoutePoint` · `WorkoutSplit` · `WorkoutLap` · `WorkoutZoneSummary`(+`WorkoutZoneDuration`) · `WorkoutSeries`(+`SeriesPoint` · `MetricSeriesPoint` · `ElevationPoint` · `SeriesSamplingMetadata`)

엔티티에 존재하지 않는 필드는 이 계약에 포함하지 않는다. **예외는 다운샘플 메타데이터(`routeOriginalPointCount` · `routeSamplingMethod`)뿐이며**, 이들은 엔티티에 저장되지 않고 전송 시점에 산출하는 파생 필드다.

HealthKit·WeatherKit 원본 객체 자체는 직렬화하지 않으며, 각 값은 엔티티 프로퍼티가 정의한 단위·타입을 유지한 채 JSON 기본 타입으로 변환한다.

이 계약이 왜 이 모양인지와 클라이언트 구현 판단은 [0001 다이어리 전송 계약과 payload 생성 코드](../decisions/0001-diary-request-contract.md)에 있다.

## 엔티티 → 요청 바디 매핑 개요

요청 바디는 `Diary` 엔티티 구조를 그대로 미러링한다. `Diary`가 최상위이며, `workout`·`weather`는 중첩 객체, 나머지 사용자 입력 필드는 최상위에 나열한다.

| `Diary` 프로퍼티 | 요청 필드 | 타입 |
|---|---|---|
| `workout` | `workout` | Object (`HealthKitWorkout`) |
| `weather` | `weather` | Object \| null (`WeatherData`의 원시 수치, WeatherKit 자동 조회) |
| `painAreas` | `painAreas` | Array\<String\> |
| `runningStyle` | `runningStyle` | String \| null |
| `memo` | `memo` | String \| null |
| `shoe` | `shoeId` | String \| null (카탈로그 `Shoe.id`) |
| `difficultyLevel` | `difficultyLevel` | Integer \| null |
| `id` | — | 전송 제외 (로컬 전용 UUID, 아래 "전송 제외 항목" 참고) |
| `legacyShoe` | — | 전송 제외 (구버전 로컬 데이터, 아래 "신발" 참고) |

## 요청 헤더

| 헤더 | 값 |
|---|---|
| `Authorization` | `Bearer {accessToken}` |
| `Content-Type` | `application/json` |

**멱등성 헤더는 보내지 않는다.** 중복 방지는 `(userId, workout.id)` 기준 서버 판정과 `409 WORKOUT_ALREADY_EXISTS`가 담당한다.

키 이름은 **camelCase 그대로** 전송한다(`averagePaceSecondsPerKm`). snake_case로 변환하지 않는다.

## 요청 바디 예시

```json
{
  "workout": {
    "id": "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
    "startTime": "2026-07-12T06:30:00Z",
    "endTime": "2026-07-12T07:12:30Z",
    "timeZone": "Asia/Seoul",
    "runningType": "outdoor",
    "distance": 7.42,
    "duration": 2550,
    "elapsedTime": 2570,
    "averagePaceSecondsPerKm": 344,
    "averageHeartRate": 152,
    "averageCadence": 174,
    "averagePower": 310.0,
    "averageVerticalOscillation": 8.4,
    "averageGroundContactTime": 236.0,
    "averageStepLength": 1.12,
    "averageStrideLength": 1.35,
    "activeEnergyBurned": 512.3,
    "totalEnergyBurned": 598.1,
    "elevationAscended": 42.0,
    "restingHeartRate": 58.0,
    "heartRateRecoveryOneMinute": 32.0,
    "route": [
      { "latitude": 37.5665, "longitude": 126.9780, "altitude": 12.4, "elapsedSec": 0 },
      { "latitude": 37.5668, "longitude": 126.9783, "altitude": 13.1, "elapsedSec": 5 }
    ],
    "routeOriginalPointCount": 2,
    "routeSamplingMethod": "none",
    "splits": [
      {
        "index": 1,
        "distanceKm": 1.0,
        "durationSec": 330,
        "paceSecondsPerKm": 330,
        "averageHeartRate": 148,
        "averageCadence": 172,
        "averagePower": 308.5,
        "elevationGainM": 4.2
      }
    ],
    "laps": [
      {
        "id": "2f0f5a61-9c1d-4a9e-9f1b-7c0f4d2ab111",
        "index": 1,
        "startOffsetSec": 0,
        "durationSec": 600,
        "distanceKm": 1.72,
        "paceSecondsPerKm": 349,
        "averageHeartRate": 145,
        "averagePower": 242.0,
        "averageCadence": 171
      }
    ],
    "zoneSummaries": [
      {
        "metric": "heartRate",
        "source": "system",
        "durations": [
          { "index": 1, "minimum": null, "maximum": 120, "durationSec": 180 },
          { "index": 2, "minimum": 120, "maximum": 140, "durationSec": 420 },
          { "index": 3, "minimum": 140, "maximum": null, "durationSec": 1950 }
        ]
      }
    ],
    "series": {
      "sampleIntervalSec": 5,
      "heartRate": [
        { "t": 0, "v": 132 },
        { "t": 5, "v": 138 }
      ],
      "paceSecondsPerKm": [
        { "t": 0, "v": 360 },
        { "t": 5, "v": 352 }
      ],
      "cadence": [
        { "t": 0, "v": 168 },
        { "t": 5, "v": 170 }
      ],
      "power": [
        { "t": 0, "v": 305 },
        { "t": 5, "v": 312 }
      ],
      "verticalOscillation": [
        { "t": 0, "v": 8.4 },
        { "t": 5, "v": 8.2 }
      ],
      "groundContactTime": [
        { "t": 0, "v": 236 },
        { "t": 5, "v": 238 }
      ],
      "strideLength": [
        { "t": 0, "v": 1.35 },
        { "t": 5, "v": 1.37 }
      ],
      "elevation": [
        { "distanceM": 0, "altitude": 12.4 },
        { "distanceM": 50, "altitude": 13.1 }
      ],
      "metadata": {
        "heartRate": { "originalSampleCount": 3120, "samplingMethod": "fixedIntervalAverage" },
        "paceSecondsPerKm": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "cadence": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "power": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "verticalOscillation": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "groundContactTime": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "strideLength": { "originalSampleCount": 2540, "samplingMethod": "fixedIntervalAverage" },
        "elevation": { "originalSampleCount": 2, "samplingMethod": "none" }
      }
    }
  },
  "weather": {
    "temperature": 24.6,
    "humidity": 68,
    "windSpeed": 2.3,
    "apparentTemperature": 26.1,
    "cloudCover": 0.35,
    "precipitationAmount": 0.0
  },
  "painAreas": ["knee", "achilles"],
  "runningStyle": "midfoot",
  "memo": "컨디션 좋았음",
  "shoeId": "68f0a1b2c3d4e5f601234567",
  "difficultyLevel": 3
}
```

## `workout` 필드 (`HealthKitWorkout`)

| 필드 | 엔티티 프로퍼티 | 타입 | 단위/형식 | 규칙 |
|---|---|---|---|---|
| `id` | `id` | String | UUID | `HKWorkout.uuid`. 동일 운동에서 불변 |
| `startTime` | `startTime` | String | ISO 8601 UTC | `Z` 표기 (예: `2026-07-12T06:30:00Z`). 현지 시각은 `timeZone`으로 해석한다 |
| `endTime` | `endTime` | String | ISO 8601 UTC | `Z` 표기 |
| `timeZone` | `timeZone` | String \| null | IANA identifier | 기록 당시 타임존 (예: `Asia/Seoul`). 알 수 없으면 `null`. 아래 "타임존" 참고 |
| `runningType` | `runningType` | String | `outdoor`, `treadmill` | 아래 "러닝 타입" 참고 |
| `distance` | `distance` | Number | km | 트레드밀 등 거리 미측정 시 `0` |
| `duration` | `duration` | Integer | sec | 운동시간. `HKWorkout.duration`(일시정지 제외)을 반올림한 정수 초 |
| `elapsedTime` | `elapsedTime` | Integer | sec | 경과시간. `endTime - startTime`(일시정지 포함)을 반올림한 정수 초 |
| `averagePaceSecondsPerKm` | `averagePaceSecondsPerKm` | Integer \| null | sec/km | 거리가 `0`이면 `null`. `splits`/`laps`/`series`와 단위가 동일하다 |
| `averageHeartRate` | `averageHeartRate` | Integer | bpm | 미측정 시 `0` |
| `averageCadence` | `averageCadence` | Integer | spm | 미측정 시 `0` |
| `averagePower` | `averagePower` | Number | watts | 미측정 시 `0` |
| `averageVerticalOscillation` | `averageVerticalOscillation` | Number | cm | 미측정 시 `0` |
| `averageGroundContactTime` | `averageGroundContactTime` | Number | ms | 미측정 시 `0` |
| `averageStepLength` | `averageStepLength` | Number | m | 미측정 시 `0` |
| `averageStrideLength` | `averageStrideLength` | Number | m | 미측정 시 `0` |
| `activeEnergyBurned` | `activeEnergyBurned` | Number | kcal | 활동 칼로리. 미측정 시 `0` |
| `totalEnergyBurned` | `totalEnergyBurned` | Number \| null | kcal | 총 칼로리(활동 + 기초대사). **기초대사를 얻지 못하면 `null`.** 아래 "총 칼로리" 참고 |
| `elevationAscended` | `elevationAscended` | Number \| null | m | 등반 고도. 미측정이고 경로도 없으면 `null` |
| `restingHeartRate` | `restingHeartRate` | Number | bpm | 미측정 시 `0` |
| `heartRateRecoveryOneMinute` | `heartRateRecoveryOneMinute` | Number | bpm | 운동 후 1분 심박 회복. 미측정 시 `0` |
| `route` | `route` | Array\<RoutePoint\> \| null | - | 경로가 없으면 `null`. 최대 50,000점 |
| `routeOriginalPointCount` | (파생) | Integer | - | 다운샘플 전 경로 지점 수. `route`가 `null`이면 `0` |
| `routeSamplingMethod` | (파생) | String | `none`, `uniform` | 경로에 적용한 축약 방식 |
| `splits` | `splits` | Array | - | 1km 단위. 데이터가 없으면 `[]` |
| `laps` | `laps` | Array | - | 랩 버튼 구간. 데이터가 없으면 `[]` |
| `zoneSummaries` | `zoneSummaries` | Array | - | 심박·파워 영역. 데이터가 없으면 `[]` |
| `series` | `series` | Object \| null | - | 다운샘플 시계열. 수집 시계열이 없으면 `null` |

> **페이스는 숫자다.** `averagePaceSecondsPerKm`(sec/km, Integer)이며 표시용 문자열(`5'44"`)은 클라이언트가 포맷한다. `splits.paceSecondsPerKm`, `laps.paceSecondsPerKm`, `series.paceSecondsPerKm`과 단위가 같다.
>
> **미측정 스칼라 관례**: `HealthKitWorkout`의 숫자 스칼라 지표는 미측정 시 엔티티에서 `0`으로 채워진다(앱 표시 로직도 `0`을 "값 없음"으로 처리). 따라서 서버는 이들 필드의 `0`을 미측정으로 해석한다. 다만 `averagePaceSecondsPerKm`과 `elevationAscended`는 `0`이 유효값이 될 수 있어 미측정을 `null`로 구분한다.

### 타임존 (`timeZone`)

시각은 UTC(`Z`)로 보내고 기록 당시의 지역은 `timeZone`(IANA identifier)이 따로 담는다. 오프셋만으로는 같은 `+09:00`인 `Asia/Seoul`과 `Asia/Tokyo`를 구분할 수 없고, 서머타임이 있는 지역은 오프셋이 계절에 따라 달라져 지역을 역산할 수 없기 때문이다.

출처는 HealthKit `HKMetadataKeyTimeZone` **하나뿐**이다. 이 메타데이터는 기록 기기가 워크아웃 저장 시 남기는 IANA identifier이므로, 값이 있으면 **기록 당시의 타임존으로 신뢰할 수 있다.**

**메타데이터가 없으면 `null`을 보낸다.** 기기의 현재 타임존으로 대체하지 않는다.

```json
"timeZone": "Asia/Seoul"   // 기록 당시 기기가 남긴 값 (신뢰 가능)
"timeZone": null           // 기록 당시 타임존을 알 수 없음
```

폴백을 두지 않는 이유는 **모르는 값을 아는 값처럼 저장하지 않기 위해서**다. 기기 현재값으로 채우면 해외에서 기록한 러닝을 귀국 후 전송할 때 틀린 타임존이 참값으로 저장되고, 서버는 그것이 폴백이었다는 사실을 영원히 알 수 없다. `null`로 보내면 폴백 정책의 소유권이 서버로 넘어가고, **서버는 그것이 자기 폴백임을 안다.**

메타데이터 부재는 예외가 아니라 상시 경로다.

| 기록 출처 | `HKMetadataKeyTimeZone` |
|---|---|
| Apple Watch 워크아웃 앱 | 있음 |
| 서드파티 앱(Strava·Nike Run Club·Garmin 등)이 HealthKit에 기록 | **없음** |
| 건강 앱 수동 입력 | **없음** |

`startTime`/`endTime`(UTC)은 항상 정확하므로 절대 시각 기준 집계는 영향을 받지 않는다. 현지 시각 기준 집계(예: "새벽 러닝 비율")는 `timeZone`이 있으면 신뢰하고, `null`이면 서버 폴백값으로 계산하되 신뢰도를 낮춰 다루면 된다.

앱 내부 표시는 기존대로 기기 타임존으로 대체하므로 UI 영향이 없다.

### 총 칼로리 (`totalEnergyBurned`)

`활동 칼로리 + 기초대사 칼로리`다. **기초대사를 얻지 못하면 `null`을 보낸다.**

```json
"activeEnergyBurned": 512.4,
"totalEnergyBurned": null
```

이전에는 `활동 칼로리 + (기초대사 ?? 0)`이라 기초대사가 없으면 **활동 칼로리와 똑같은 값**이 총 칼로리 자리에 실렸다. 두 필드가 같은 값이면 "기초대사가 0이었다"인지 "얻지 못했다"인지 서버가 구분할 수 없어 `null`로 바꾼다.

`activeEnergyBurned`는 기존 **`0` = 미측정** 관례를 유지한다. 따라서 `activeEnergyBurned: 0` + `totalEnergyBurned: null`은 "둘 다 미측정"을 뜻한다.

### 러닝 타입 (`runningType`)

| 값 | 의미 |
|---|---|
| `outdoor` | 실외 달리기 |
| `treadmill` | 트레드밀(실내) |

HealthKit `HKMetadataKeyIndoorWorkout`을 1순위 근거로 판별하고, 메타데이터가 없으면 거리 측정 여부로 추정한다(거리가 `0`이면 `treadmill`).

> **`runningTypeSource`는 이번 계약에서 전송하지 않는다.**
>
> 판별 근거를 `healthKit`(메타데이터 있음) / `distanceInference`(거리로 추정)로 구분하는 데는 서버와 합의했고, 앱도 엔티티에 이 값을 보유한다. 다만 **요청 바디에는 아직 싣지 않는다** — 추정으로 판별된 기록의 비율이 실사용 데이터로 확인되기 전에는 서버가 이 값으로 무엇을 분기할지 정할 근거가 없기 때문이다.
>
> 필드 추가는 nullable 한 줄이라 언제든 가능하다. 서버가 지금 필요하다면 알려달라.

트레드밀 기록은 `distance`가 `0`, `averagePaceSecondsPerKm`이 `null`, **`route`가 항상 `null`**이며, 심박·칼로리·케이던스는 정상 기록된다. `route`는 트레드밀일 때 좌표가 기록돼 있더라도 `null`로 정규화하므로, **`runningType: "treadmill"`인데 `route`가 존재하는 조합은 나오지 않는다.**

역으로 `route: null`이라고 해서 반드시 트레드밀인 것은 아니다. 실외 달리기라도 위치 권한이 없거나 GPS를 잡지 못하면 `null`이 된다. 다만 실무상 `route: null`의 대다수는 트레드밀 기록이다.

## `workout.route` (`RoutePoint`)

경로는 좌표에 고도와 워크아웃 시작 후 경과초를 함께 담는다. 이 배열 하나가 지도 렌더링과 시간축 고도 시계열을 모두 커버한다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `latitude` | `latitude` | Number | 도 | |
| `longitude` | `longitude` | Number | 도 | |
| `altitude` | `altitude` | Number \| null | m | 고도 미측정 시 `null` |
| `elapsedSec` | `elapsedSec` | Number \| null | sec | 워크아웃 시작 후 경과 초. 미측정 시 `null` |

```json
{ "latitude": 37.5665, "longitude": 126.9780, "altitude": 12.4, "elapsedSec": 0 }
```

- **경로가 없으면 `route: null`이다. 빈 배열(`[]`)은 보내지 않는다.** 이때 `routeOriginalPointCount`는 `0`, `routeSamplingMethod`는 `none`이다.
- `route: null`은 트레드밀 기록이거나, 실외 달리기인데 위치 권한·GPS 문제로 경로를 얻지 못한 경우다. 트레드밀은 **항상** `null`이다(위 "러닝 타입" 참고).
- `altitude`/`elapsedSec`는 구버전 앱이 저장한 기록에서 `null`일 수 있다. 당시 포맷이 위경도만 담았기 때문이다.

**다운샘플 규칙**: 원본이 50,000점 이하면 그대로 보내고 `routeSamplingMethod: "none"`이다. 초과하면 균등 인덱스로 정확히 50,000점까지 줄이고 `routeSamplingMethod: "uniform"`이 되며, 첫 지점과 마지막 지점은 항상 보존한다. 같은 입력에는 항상 같은 출력이 나오고 좌표·시간 순서를 유지한다. `routeOriginalPointCount`는 축약 전 개수라 서버가 해상도 손실 여부를 판단할 수 있다.

## `workout.splits` (`WorkoutSplit`)

거리 기준 1km 단위 구간이다. 경로 데이터에서 산출하므로 경로가 없으면 비어 있다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `index` | `index` | Integer | - | 1부터 순차 증가 |
| `distanceKm` | `distanceKm` | Number | km | 마지막 구간은 1km 미만 가능 |
| `durationSec` | `durationSec` | Integer | sec | 구간 운동시간 |
| `paceSecondsPerKm` | `paceSecondsPerKm` | Integer | sec/km | 구간 페이스 |
| `averageHeartRate` | `averageHeartRate` | Integer \| null | bpm | 구간 샘플이 없으면 `null` |
| `averageCadence` | `averageCadence` | Integer \| null | spm | 구간 샘플이 없으면 `null` |
| `averagePower` | `averagePower` | Number \| null | watts | 구간 샘플이 없으면 `null` |
| `elevationGainM` | `elevationGainM` | Number \| null | m | 고도 샘플이 없으면 `null` |

구간 데이터가 없으면 `splits: []`로 보낸다.

## `workout.laps` (`WorkoutLap`)

Apple Watch 랩 버튼으로 사용자가 직접 나눈 구간이다. `HKWorkout.workoutActivities`에서 도출하며 길이가 불규칙하다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `id` | `id` | String | UUID | 활동(`HKWorkoutActivity`)의 UUID |
| `index` | `index` | Integer | - | 시작 시각 순으로 1부터 순차 증가 |
| `startOffsetSec` | `startOffsetSec` | Integer | sec | 워크아웃 시작 후 경과 초 |
| `durationSec` | `durationSec` | Integer | sec | 구간 운동시간 |
| `distanceKm` | `distanceKm` | Number | km | 거리 미측정 시 `0` |
| `paceSecondsPerKm` | `paceSecondsPerKm` | Integer \| null | sec/km | 거리가 `0`이면 `null` |
| `averageHeartRate` | `averageHeartRate` | Integer \| null | bpm | 구간 통계가 없으면 `null` |
| `averagePower` | `averagePower` | Number \| null | watts | 구간 통계가 없으면 `null` |
| `averageCadence` | `averageCadence` | Integer \| null | spm | 걸음 수가 없으면 `null` |

- 랩 버튼을 누르지 않은 워크아웃(활동 1개)은 `laps: []`다.
- Apple Watch가 아닌 서드파티 소스 기록은 활동 정보가 없어 `laps: []`가 될 수 있다.

## `workout.zoneSummaries` (`WorkoutZoneSummary`)

지표별 존 구성과 존별 체류 시간이다. HealthKit이 체류 시간을 이미 집계해 제공한다.

| 필드 | 엔티티 프로퍼티 | 타입 | 값 |
|---|---|---|---|
| `metric` | `metric` | String | `heartRate`, `power` |
| `source` | `source` | String \| null | `system`(자동 생성), `user`(건강 설정에서 직접 지정), `app`(앱 지정). 알 수 없으면 `null` |
| `durations` | `durations` | Array\<WorkoutZoneDuration\> | 아래 표 |

`durations` 항목:

| 필드 | 타입 | 단위 | 규칙 |
|---|---|---|---|
| `index` | Integer | - | 존 인덱스 |
| `minimum` | Number \| null | 지표 단위 | 첫 존은 하한이 없어 `null` |
| `maximum` | Number \| null | 지표 단위 | 마지막 존은 상한이 없어 `null` |
| `durationSec` | Integer | sec | 해당 존 체류 시간 |

- 존은 항상 연속적이고 겹치지 않는다.
- **iOS 27 이상에서만 수집된다.** 하위 버전이거나 사용자가 존을 구성하지 않았으면 `zoneSummaries: []`다.

## `workout.series` (`WorkoutSeries`)

**다운샘플된** 시계열이다. 원본 정밀도 시계열(`WorkoutSampleSet`)은 전송하지 않는다("전송 제외 항목" 참고).

**다운샘플 방식**: `sampleIntervalSec`(기본 **5초**) 버킷별 산술평균으로 축약한 뒤, 포인트 수가 상한(**2,000**)을 넘으면 균등 간격으로 골라 결정적으로 축소한다. 지표별 상한은 모두 2,000점이며 `elevation`도 같은 상한을 적용한다.

| 필드 | 엔티티 프로퍼티 | 타입 | 설명 |
|---|---|---|---|
| `sampleIntervalSec` | `sampleIntervalSec` | Integer \| null | 다운샘플 버킷 간격 (기본 `5`) |
| `heartRate` | `heartRate` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: bpm(Int) |
| `paceSecondsPerKm` | `paceSecondsPerKm` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: sec/km(Int) |
| `cadence` | `cadence` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: spm(Int) |
| `power` | `power` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: watts(Int) |
| `verticalOscillation` | `verticalOscillation` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: cm(**Number**) |
| `groundContactTime` | `groundContactTime` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: ms(Int) |
| `strideLength` | `strideLength` | Array\<{t, v}\> | `t`: 시작 후 초(Int), `v`: m(**Number**) |
| `elevation` | `elevation` | Array\<{distanceM, altitude}\> | 거리축 고도 프로파일. `distanceM`·`altitude`: m(Number) |
| `metadata` | `metadata` | Object | 지표별 다운샘플 이력. 아래 표 |

- 수집할 수 있는 시계열이 하나도 없으면 `series: null`이다.
- 개별 지표를 수집하지 못하면 해당 배열은 `[]`로 보내고 `metadata`에는 키를 넣지 않는다.
- **`v`의 타입이 지표별로 다르다.** 대부분은 정수로 반올림하지만, 수직 진폭(cm)·보폭 길이(m)는 값이 작아 정수 반올림 시 정보가 소멸하므로 소수를 유지한다.
- 시간축 고도 시계열이 필요하면 `series.elevation`(거리축)이 아니라 `route`의 `altitude`/`elapsedSec`를 사용한다.
- **평균 보폭(`averageStepLength`)에 대응하는 시계열은 없다.** 스칼라로만 전송한다. 시계열이 필요한 보폭 지표는 `strideLength`(러닝 보폭 길이)다.

### `series` 시계열 원소 (`SeriesPoint`)

`heartRate` · `paceSecondsPerKm` · `cadence` · `power` · `groundContactTime`의 원소다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `t` | `t` | Integer | sec | 워크아웃 시작 후 경과 초. 버킷 시작 시각(`버킷 인덱스 × sampleIntervalSec`) |
| `v` | `v` | Integer | 지표 단위 | 버킷 평균을 반올림한 정수 |

```json
{ "t": 5, "v": 138 }
```

### `series` 소수 시계열 원소 (`MetricSeriesPoint`)

`verticalOscillation` · `strideLength`의 원소다. 값이 작아 정수 반올림 시 정보가 소멸하므로 소수를 유지한다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `t` | `t` | Integer | sec | `SeriesPoint`와 동일 |
| `v` | `v` | Number | 지표 단위 | 버킷 평균. 반올림하지 않는다 |

```json
{ "t": 5, "v": 8.2 }
```

### `series.elevation` 원소 (`ElevationPoint`)

유일하게 시간축이 아닌 **거리축** 프로파일이다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `distanceM` | `distanceM` | Number | m | 시작점부터의 누적 거리 |
| `altitude` | `altitude` | Number | m | 해당 지점의 고도 |

```json
{ "distanceM": 50, "altitude": 13.1 }
```

경로 지점에서 직접 도출하므로 `route`가 `null`이거나 고도가 없으면 `[]`다.

### `series.metadata` (`SeriesSamplingMetadata`)

지표 이름을 키로 갖는 객체다. 수집하지 못한 지표는 키가 없다.

유효한 키는 시계열 필드명과 동일한 8종이다.

```text
heartRate, paceSecondsPerKm, cadence, power,
verticalOscillation, groundContactTime, strideLength, elevation
```

각 값의 필드:

| 필드 | 엔티티 프로퍼티 | 타입 | 값 | 설명 |
|---|---|---|---|---|
| `originalSampleCount` | `originalSampleCount` | Integer | - | 다운샘플 전 원본 샘플 개수 |
| `samplingMethod` | `samplingMethod` | String | `none`, `fixedIntervalAverage`, `uniform` | 최종 적용된 축약 방식 |

| `samplingMethod` | 의미 | 나타나는 지표 |
|---|---|---|
| `none` | 원본 배열을 그대로 사용 | **`elevation` 전용.** 거리축이라 시간 버킷 평균을 적용하지 않는다 |
| `fixedIntervalAverage` | 시간 버킷 평균만으로 상한 이하가 됨 | 시간축 7종 |
| `uniform` | 버킷 평균 후에도 상한을 넘어 균등 인덱스로 한 번 더 축소함 | 전체 8종 |

시간축 7종은 항상 버킷 평균을 거치므로 `none`이 나오지 않는다. 즉 `samplingMethod: "none"`은 `elevation`에서만 관측된다.

전송된 포인트 수만으로는 "원본이 원래 적었는지"와 "축약해서 줄었는지"를 구분할 수 없으므로 두 값을 함께 보낸다.

## 전송 제외 항목

다음은 엔티티에 존재하지만 요청 바디에 포함하지 않는다.

| 엔티티 프로퍼티 | 위치 | 제외 사유 |
|---|---|---|
| `Diary.id` | 최상위 | 로컬 전용 식별자(UUID). 서버는 자체 식별자를 발급한다 |
| `Diary.legacyShoe` | 최상위 | 카탈로그 식별자가 없는 구버전 로컬 데이터. 서버가 해석할 수 없어 `shoeId: null`로 대체한다. 위 "신발" 참고 |
| `HealthKitWorkout.runningTypeSource` | `workout` | `runningType`의 판별 근거(`healthKit`/`distanceInference`). 서버와 값은 합의했으나 **이번 계약에서는 전송하지 않는다.** 위 "러닝 타입" 참고 |
| `HealthKitWorkout.yearMonthDay` | `workout` | `startTime`에서 파생되는 값이므로 서버가 도출 가능 |
| `HealthKitWorkout.samples` | `workout` | 원시 시계열 8종(`WorkoutSampleSet`: 심박·페이스·케이던스·파워·수직 진폭·지면 접촉 시간·보폭·러닝 보폭). 아래 설명 참고 |

### 원시 시계열(`samples`)을 보내지 않는 이유

`WorkoutSampleSet`은 HealthKit이 기록한 샘플을 다운샘플 없이 원본 정밀도로 보유한다. 1시간 러닝이면 지표당 수천 포인트에 달해 요청 바디가 과도하게 커지므로 전송하지 않는다.

- **평균**은 `workout`의 스칼라 필드가 보존한다.
- **시계열**은 `series`(5초 간격 다운샘플)가 보존한다.

## `weather` 필드 (`WeatherData`, 자동 조회 원시 수치)

**WeatherKit이 자동 조회한 원시 수치만 담는다.** 사용자가 직접 고르는 날씨는 앱에서 제거했다(아래 "사용자 선택 날씨를 다루지 않는다" 참고).

| 필드 | 엔티티 프로퍼티 | 타입 | 단위/값 |
|---|---|---|---|
| `temperature` | `temperature` | Number | °C |
| `humidity` | `humidity` | Integer | % (0~100) |
| `windSpeed` | `windSpeed` | Number | m/s |
| `apparentTemperature` | `apparentTemperature` | Number \| null | °C (체감온도) |
| `cloudCover` | `cloudCover` | Number \| null | 0.0~1.0 (구름량) |
| `precipitationAmount` | `precipitationAmount` | Number \| null | mm (hourly forecast 구간의 누적 강수량) |

- 날씨 자동 조회에 실패하면 `weather: null`이다.
- 앞 세 필드(`temperature`·`humidity`·`windSpeed`)는 `weather`가 존재하면 항상 함께 존재한다.
- 뒤 세 필드는 **nullable이다.** 이유는 두 가지다.
  1. WeatherKit 응답에 해당 값이 없을 수 있다.
  2. **로컬에 저장된 기록을 나중에 전송하는 경우** 세 값이 `null`이 된다. 아래 참고.

> **영속 왕복 시 확장 원시값이 소실된다.** 이 세 값에는 SwiftData 컬럼을 두지 않았다. 날씨는 일지 생성 시점에 조회해 그 자리에서 전송하는 것이 정상 경로이므로 저장 왕복이 불필요하기 때문이다. 따라서 **구버전에서 만들어져 소급 이관되는 기록은 세 값이 `null`로 전송된다.** `temperature`·`humidity`·`windSpeed`는 컬럼이 있어 보존된다.

### 카테고리를 보내지 않는 이유

앱은 화면 표시를 위해 하늘 상태·바람·체감·습도를 4개 카테고리로 분류했으나, 이는 원시 수치에서 파생된 표시 전용 값이므로 전송하지 않는다. 등급 기준이 필요하면 서버가 원시 수치로 직접 분류한다.

**v1.1에서 확장 원시값 3종이 추가되면서 4개 카테고리가 모두 서버에서 재계산 가능해졌다.**

| 카테고리 | 분류 근거 | 서버 재계산 |
|---|---|---|
| 바람 등급 | `windSpeed` | 가능 |
| 습도 등급 | `humidity` | 가능 |
| 하늘 상태(맑음/흐림) | `cloudCover` | **가능** (v1.1에서 해소) |
| 체감 등급 | `apparentTemperature` | **가능** (v1.1에서 해소) |

### 사용자 선택 날씨를 다루지 않는다

이전 버전의 앱에는 사용자가 하늘 상태·바람·체감·습도를 직접 고르는 입력 단계가 있었고, 그 값을 `UserWeather`로 따로 보관했다. **이 기능을 앱에서 제거했다.**

날씨는 WeatherKit이 조회한 정량 수치만 취급한다. 같은 날씨를 두 갈래(측정값 / 주관 선택값)로 보관하면 어느 쪽이 참인지 정할 수 없고, 서버가 원시 수치로 등급을 재계산하는 이 계약과도 충돌하기 때문이다.

따라서 `UserWeather`와 그 4개 카테고리는 **요청 바디에 존재하지 않으며, 앞으로도 추가되지 않는다.**

## 최상위 사용자 입력 필드

| 필드 | 엔티티 프로퍼티 | 타입 | 규칙 |
|---|---|---|---|
| `painAreas` | `painAreas` | Array\<String\> | 통증이 없으면 `[]` |
| `runningStyle` | `runningStyle` | String \| null | `forefoot`, `midfoot`, `heelfoot` |
| `memo` | `memo` | String \| null | 비어 있으면 `null` |
| `shoeId` | `shoe?.id` | String \| null | 서버 신발 카탈로그의 `Shoe.id`. 아래 "신발" 참고 |
| `difficultyLevel` | `difficultyLevel` | Integer \| null | 1~5 (아래 매핑) |

### 신발 (`shoeId`)

신발은 **카탈로그 식별자만** 주고받는다. `GET /api/v1/shoes`로 받은 `Shoe.id`를 그대로 보내며, 브랜드·이름 같은 표시용 메타데이터는 전송하지 않는다.

`shoeId: null`은 두 가지 사유로 발생하며 **요청 바디만으로는 구분할 수 없다.**

1. 사용자가 신발을 선택하지 않았다.
2. 신발 API 도입 이전 버전에서 만들어진 기록이라 카탈로그 식별자가 아직 없다. 이 경우 앱이 순차적으로 카탈로그 식별자로 변환하며, 변환이 끝난 기록부터 `shoeId`가 채워진다.

두 경우를 서버가 구분하는 플래그는 **두지 않기로 확정했다**(아래 "서버 확인 요청사항" 6번).

### enum 값

`painAreas` (`PainArea`):

```text
knee, sole, shin, achilles, hip, shoulder, neck, waist, chest, calf, ankle, side
```

`runningStyle` (`RunninStyle`):

```text
forefoot, midfoot, heelfoot
```

`difficultyLevel` (`DifficultyLevel`, rawValue 전송):

| 값 | 의미 |
|---|---|
| `1` | veryEasy |
| `2` | easy |
| `3` | medium |
| `4` | hard |
| `5` | veryHard |

## null 및 빈 컬렉션 규칙

| 상황 | 전송값 |
|---|---|
| 미측정 `HealthKitWorkout` 스칼라 지표 | `0` |
| 거리 미측정(트레드밀 등) | `distance: 0`, `averagePaceSecondsPerKm: null` |
| 등반 고도 미측정 + 경로 없음 | `elevationAscended: null` |
| 기초대사 칼로리 없음 | `totalEnergyBurned: null` |
| 기록 당시 타임존을 알 수 없음 | `timeZone: null` |
| 경로 없음 | `route: null`, `routeOriginalPointCount: 0`, `routeSamplingMethod: "none"` |
| 경로 50,000점 초과 | 50,000점으로 축약, `routeSamplingMethod: "uniform"` |
| splits 없음 | `splits: []` |
| 랩 없음(랩 버튼 미사용) | `laps: []` |
| 존 없음(iOS 27 미만 등) | `zoneSummaries: []` |
| series 전체 없음 | `series: null` |
| series의 개별 지표 없음 | 해당 배열 `[]`, `metadata`에 키 없음 |
| 통증 없음 | `painAreas: []` |
| 러닝 스타일 미선택 | `runningStyle: null` |
| 메모 없음 | `memo: null` |
| 신발 미선택 | `shoeId: null` |
| 신발에 카탈로그 식별자가 없음(구버전 데이터) | `shoeId: null` |
| 난이도 미선택 | `difficultyLevel: null` |
| 날씨 자동 조회 실패 | `weather: null` |
| 날씨 확장 원시값 미취득 또는 로컬 복원분 | `apparentTemperature: null`, `cloudCover: null`, `precipitationAmount: null` |

## 서버 확인 요청사항 — 전부 해소됨

v1.0 시점의 확인 요청 8건과 v1.1 회신의 4건이 모두 확정됐다. 이력으로 남긴다.

| # | 질문 | 결론 |
|---|---|---|
| 1 | 미측정 스칼라를 `0`으로 보내고 `0 = 미측정`으로 해석하는가 | **수용.** 서버가 `0`을 `null`로 정규화한다. `averagePaceSecondsPerKm`·`elevationAscended`는 `0`이 유효값이라 `null`로 구분 |
| 2 | `series`의 `v`가 지표별로 Integer/Number로 갈리는 것 | **수용** |
| 3 | 원시 시계열(`samples`) 제외, 5초 다운샘플 `series`만 전송 | **수용** |
| 4 | 날씨를 원시 수치로만 받고 등급 분류는 서버가 수행 | **수용.** 나아가 서버가 원시값 확장을 요청해 `apparentTemperature`·`cloudCover`·`precipitationAmount`가 추가됐다 |
| 5 | UTC(`Z`) + `timeZone`(IANA) 분리 | **수용.** v1.1에서 `timeZone`이 nullable이 됐다 |
| 6 | 구버전 기록을 `shoeId: null`로 받는 것 | **수용.** "신발 미선택"과 구분하는 플래그는 두지 않는다 |
| 7 | `shoeId` 형식 제약이 있는가 | **형식 검증을 넣지 않는다.** 값은 서버 카탈로그에서 그대로 받은 id다 |
| 8 | `series.metadata`·route 메타데이터 형태 | **수용** |
| 9 | `Idempotency-Key` 제거 | **수용.** `(userId, workout.id)` 기준 409로 처리 |
| 10 | 강수 지표를 `precipitationAmount`(mm)로 | **수용.** `precipitationIntensity` 대신 채택 |
| 11 | 계약 버저닝을 URL 경로로 | **수용.** `schemaVersion`을 보내지 않는다 |
| 12 | 서버·로컬 저장 순서와 오프라인 지원 | **로컬 먼저 저장 후 `pending` 큐 등록**으로 확정 |

## 오류 처리

### 오류 응답 형식

```json
{
  "detail": {
    "code": "REQUEST_VALIDATION_FAILED",
    "message": "요청 값이 올바르지 않습니다.",
    "fields": [
      { "path": "workout.timeZone", "message": "유효하지 않은 값입니다." }
    ]
  }
}
```

- JSON 경로: `$.detail.code`
- 타입: `String`

| 코드 | 발생 상황 |
|---|---|
| `AUTH_REQUIRED` | 인증 실패 |
| `WORKOUT_ALREADY_EXISTS` | 동일 사용자의 동일 `workout.id`가 이미 저장됨 |
| `PAYLOAD_TOO_LARGE` | body 크기 초과 |
| `REQUEST_VALIDATION_FAILED` | 스키마·값 검증 실패 |
| `SHOE_NOT_FOUND` | `shoeId`가 카탈로그에 없음 |
| `INTERNAL_SERVER_ERROR` | 서버 내부 오류 |

### 저장 순서와 재시도 정책

앱은 **로컬 저장을 먼저 수행하고 `pending` 상태로 동기화 큐에 등록**한다. 사용자에게 보이는 저장 성공은 로컬 기준이므로 오프라인에서도 일지 작성이 막히지 않는다.

| 응답 | 클라이언트 처리 |
|---|---|
| `201` | 동기화 완료 |
| `409` `WORKOUT_ALREADY_EXISTS` | **이미 동기화된 것으로 간주**하고 재업로드를 중지한다 |
| `413` / `PAYLOAD_TOO_LARGE` | route를 추가 축약해 **새 payload로 재시도.** 동일 payload는 재시도하지 않는다 |
| `401` | 토큰 갱신 후 1회 재시도. 그래도 실패하면 큐를 멈추고 재로그인을 요구한다 |
| `422` | 자동 재시도하지 않고 동기화 실패로 처리한다 |
| 네트워크 오류 · `5xx` | exponential backoff로 재시도 |

### body 크기 제한

인코딩 결과가 **4.5MiB**를 넘으면 전송하지 않고 route를 순서 보존 균등 샘플링으로 추가 축약한 뒤 재인코딩한다.

- `routeOriginalPointCount`는 **최초 원본 개수**를 유지한다(추가 축약 전 값이 아니라 다운샘플 이전 원본).
- 추가 축약이 일어나면 `routeSamplingMethod`는 `uniform`이 된다. 원본이 50,000점 이하여서 `none`이었더라도 이 시점에 `uniform`으로 바뀐다.
- `413`은 저장 전에 거절되므로, 축약 후 **동일한 `workout.id`로 재시도할 수 있다.**
