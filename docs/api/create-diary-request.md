# 다이어리 생성 API 요청 스키마

> 대상: 백엔드 개발자
> 목적: 현재 `Diary` 엔티티를 단일 진실 소스로 삼아 다이어리 생성 요청 바디의 직렬화 계약을 정의한다.
> 기준: `Dependencies/Models/Sources/Models/Entities/` 의 엔티티 정의

이 문서의 모든 필드는 앱 내부 `Diary` 엔티티와 그 하위 엔티티(`HealthKitWorkout`, `WeatherData`, `UserWeather`, `RoutePoint`, `WorkoutSplit`, `WorkoutLap`, `WorkoutZoneSummary`, `WorkoutSeries`)에서 도출한다. 엔티티에 존재하지 않는 필드는 이 계약에 포함하지 않는다. HealthKit·WeatherKit 원본 객체 자체는 직렬화하지 않으며, 각 값은 엔티티 프로퍼티가 정의한 단위·타입을 유지한 채 JSON 기본 타입으로 변환한다.

클라이언트 구현 범위와 수용 기준은 [다이어리 생성 API 클라이언트 구현 명세](./create-diary-client-implementation-spec.md)를 참고한다.

## 엔티티 → 요청 바디 매핑 개요

요청 바디는 `Diary` 엔티티 구조를 그대로 미러링한다. `Diary`가 최상위이며, `workout`·`weather`·`userWeather`는 중첩 객체, 나머지 사용자 입력 필드는 최상위에 나열한다.

| `Diary` 프로퍼티 | 요청 필드 | 타입 |
|---|---|---|
| `workout` | `workout` | Object (`HealthKitWorkout`) |
| `weather` | `weather` | Object \| null (`WeatherData`, WeatherKit 자동 조회·자동 분류) |
| `userWeather` | `userWeather` | Object \| null (`UserWeather`, 유저 직접 선택) |
| `painAreas` | `painAreas` | Array\<String\> |
| `runningStyle` | `runningStyle` | String \| null |
| `memo` | `memo` | String \| null |
| `shoes` | `shoes` | String \| null |
| `difficultyLevel` | `difficultyLevel` | Integer \| null |
| `id` | — | 전송 제외 (로컬 UUID, 아래 "전송 제외 항목" 참고) |

## 요청 헤더

| 헤더 | 필수 | 설명 |
|---|---|---|
| `Authorization` | ✅ | Bearer access token |
| `Content-Type` | ✅ | `application/json` |
| `Idempotency-Key` | ✅ | 다이어리 생성 시 발급한 UUID. 동일 요청의 재시도에서는 같은 값을 유지한다. |

`Idempotency-Key`는 논리적인 생성 요청 단위로 관리한다.

- 네트워크 오류나 401 갱신 후 같은 body를 재전송하면 기존 키를 유지한다.
- 사용자가 입력값을 변경해 새로운 생성 요청을 시작하면 새 키를 발급한다.
- 같은 키에 다른 body가 전달되는 경우의 오류 코드는 서버 정책 확인이 필요하다.

## 요청 바디 예시

```json
{
  "workout": {
    "id": "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
    "startTime": "2026-07-12T15:30:00+09:00",
    "endTime": "2026-07-12T16:12:30+09:00",
    "runningType": "outdoor",
    "distance": 7.42,
    "duration": 2550.0,
    "elapsedTime": 2570.0,
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
    "splits": [
      {
        "index": 1,
        "distanceKm": 1.0,
        "durationSec": 330.0,
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
        "durationSec": 600.0,
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
          { "index": 1, "minimum": null, "maximum": 120, "durationSec": 180.0 },
          { "index": 2, "minimum": 120, "maximum": 140, "durationSec": 420.0 },
          { "index": 3, "minimum": 140, "maximum": null, "durationSec": 1950.0 }
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
      ]
    }
  },
  "weather": {
    "temperature": 24.6,
    "humidity": 68,
    "windSpeed": 2.3,
    "skyCondition": "sunny",
    "windLevel": "moderate",
    "feelsLike": "hot",
    "humidityLevel": "dry"
  },
  "userWeather": {
    "skyCondition": "sunny",
    "windLevel": "moderate",
    "feelsLike": "hot",
    "humidityLevel": null
  },
  "painAreas": ["knee", "achilles"],
  "runningStyle": "midfoot",
  "memo": "컨디션 좋았음",
  "shoes": "Nike Pegasus 41",
  "difficultyLevel": 3
}
```

## `workout` 필드 (`HealthKitWorkout`)

| 필드 | 엔티티 프로퍼티 | 타입 | 단위/형식 | 규칙 |
|---|---|---|---|---|
| `id` | `id` | String | UUID | `HKWorkout.uuid`. 동일 운동에서 불변 |
| `startTime` | `startTime` | String | ISO 8601 | 로컬 오프셋 포함 (예: `+09:00`). 오프셋이 곧 기록 당시 타임존이다 |
| `endTime` | `endTime` | String | ISO 8601 | 로컬 오프셋 포함 |
| `runningType` | `runningType` | String | `outdoor`, `treadmill` | 아래 "러닝 타입" 참고 |
| `distance` | `distance` | Number | km | 트레드밀 등 거리 미측정 시 `0` |
| `duration` | `duration` | Number | sec | 운동시간. `HKWorkout.duration`(일시정지 제외). 소수 초 가능 |
| `elapsedTime` | `elapsedTime` | Number | sec | 경과시간. `endTime - startTime`(일시정지 포함) |
| `averagePaceSecondsPerKm` | `averagePaceSecondsPerKm` | Integer \| null | sec/km | 거리가 `0`이면 `null`. `splits`/`laps`/`series`와 단위가 동일하다 |
| `averageHeartRate` | `averageHeartRate` | Integer | bpm | 미측정 시 `0` |
| `averageCadence` | `averageCadence` | Integer | spm | 미측정 시 `0` |
| `averagePower` | `averagePower` | Number | watts | 미측정 시 `0` |
| `averageVerticalOscillation` | `averageVerticalOscillation` | Number | cm | 미측정 시 `0` |
| `averageGroundContactTime` | `averageGroundContactTime` | Number | ms | 미측정 시 `0` |
| `averageStepLength` | `averageStepLength` | Number | m | 미측정 시 `0` |
| `averageStrideLength` | `averageStrideLength` | Number | m | 미측정 시 `0` |
| `activeEnergyBurned` | `activeEnergyBurned` | Number | kcal | 활동 칼로리. 미측정 시 `0` |
| `totalEnergyBurned` | `totalEnergyBurned` | Number | kcal | 총 칼로리(활동 + 기초대사). 기초대사가 없으면 활동 칼로리와 같다 |
| `elevationAscended` | `elevationAscended` | Number \| null | m | 등반 고도. 미측정이고 경로도 없으면 `null` |
| `restingHeartRate` | `restingHeartRate` | Number | bpm | 미측정 시 `0` |
| `heartRateRecoveryOneMinute` | `heartRateRecoveryOneMinute` | Number | bpm | 운동 후 1분 심박 회복. 미측정 시 `0` |
| `route` | `route` | Array\<RoutePoint\> | - | 경로가 없으면 `[]` |
| `splits` | `splits` | Array | - | 1km 단위. 데이터가 없으면 `[]` |
| `laps` | `laps` | Array | - | 랩 버튼 구간. 데이터가 없으면 `[]` |
| `zoneSummaries` | `zoneSummaries` | Array | - | 심박·파워 영역. 데이터가 없으면 `[]` |
| `series` | `series` | Object \| null | - | 다운샘플 시계열. 수집 시계열이 없으면 `null` |

> **페이스는 숫자다.** `averagePaceSecondsPerKm`(sec/km, Integer)이며 표시용 문자열(`5'44"`)은 클라이언트가 포맷한다. `splits.paceSecondsPerKm`, `laps.paceSecondsPerKm`, `series.paceSecondsPerKm`과 단위가 같다.
>
> **미측정 스칼라 관례**: `HealthKitWorkout`의 숫자 스칼라 지표는 미측정 시 엔티티에서 `0`으로 채워진다(앱 표시 로직도 `0`을 "값 없음"으로 처리). 따라서 서버는 이들 필드의 `0`을 미측정으로 해석한다. 다만 `averagePaceSecondsPerKm`과 `elevationAscended`는 `0`이 유효값이 될 수 있어 미측정을 `null`로 구분한다.

### 러닝 타입 (`runningType`)

| 값 | 의미 |
|---|---|
| `outdoor` | 실외 달리기 |
| `treadmill` | 트레드밀(실내) |

HealthKit `HKMetadataKeyIndoorWorkout`을 1순위 근거로 판별하고, 메타데이터가 없으면 거리 측정 여부로 추정한다(거리가 `0`이면 `treadmill`). 트레드밀 기록은 `distance`가 `0`, `averagePaceSecondsPerKm`이 `null`, `route`가 `[]`인 경우가 일반적이며, 심박·칼로리·케이던스는 정상 기록된다.

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

- 경로가 없으면 `route: []`이다.
- `altitude`/`elapsedSec`는 앱의 구버전에서 저장된 기록을 복원한 경우 `null`이 될 수 있다.

## `workout.splits` (`WorkoutSplit`)

거리 기준 1km 단위 구간이다. 경로 데이터에서 산출하므로 경로가 없으면 비어 있다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위 | 규칙 |
|---|---|---|---|---|
| `index` | `index` | Integer | - | 1부터 순차 증가 |
| `distanceKm` | `distanceKm` | Number | km | 마지막 구간은 1km 미만 가능 |
| `durationSec` | `durationSec` | Number | sec | 구간 운동시간 |
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
| `startOffsetSec` | `startOffsetSec` | Number | sec | 워크아웃 시작 후 경과 초 |
| `durationSec` | `durationSec` | Number | sec | 구간 운동시간 |
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
| `durationSec` | Number | sec | 해당 존 체류 시간 |

- 존은 항상 연속적이고 겹치지 않는다.
- **iOS 27 이상에서만 수집된다.** 하위 버전이거나 사용자가 존을 구성하지 않았으면 `zoneSummaries: []`다.

## `workout.series` (`WorkoutSeries`)

**다운샘플된** 시계열이다. 원본 정밀도 시계열(`WorkoutSampleSet`)은 전송하지 않는다("전송 제외 항목" 참고).

**다운샘플 방식**: `sampleIntervalSec`(기본 **5초**) 버킷별 산술평균으로 축약한 뒤, 포인트 수가 상한(500)을 넘으면 균등 간격으로 골라 결정적으로 축소한다.

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

- 수집할 수 있는 시계열이 하나도 없으면 `series: null`이다.
- 개별 지표를 수집하지 못하면 해당 배열은 `[]`로 보낸다.
- **`v`의 타입이 지표별로 다르다.** 대부분은 정수로 반올림하지만, 수직 진폭(cm)·보폭 길이(m)는 값이 작아 정수 반올림 시 정보가 소멸하므로 소수를 유지한다.
- 시간축 고도 시계열이 필요하면 `series.elevation`(거리축)이 아니라 `route`의 `altitude`/`elapsedSec`를 사용한다.

## 전송 제외 항목

다음은 엔티티에 존재하지만 요청 바디에 포함하지 않는다.

| 엔티티 프로퍼티 | 위치 | 제외 사유 |
|---|---|---|
| `Diary.id` | 최상위 | 로컬 SwiftData 식별자(UUID). 서버는 자체 식별자를 발급하며, 멱등성은 `Idempotency-Key`로 보장한다 |
| `HealthKitWorkout.yearMonthDay` | `workout` | `startTime`에서 파생되는 값이므로 서버가 도출 가능 |
| `HealthKitWorkout.samples` | `workout` | 원시 시계열 8종(`WorkoutSampleSet`: 심박·페이스·케이던스·파워·수직 진폭·지면 접촉 시간·보폭·러닝 보폭). 아래 설명 참고 |

### 원시 시계열(`samples`)을 보내지 않는 이유

`WorkoutSampleSet`은 HealthKit이 기록한 샘플을 다운샘플 없이 원본 정밀도로 보유한다. 1시간 러닝이면 지표당 수천 포인트에 달해 요청 바디가 과도하게 커지므로 전송하지 않는다.

- **평균**은 `workout`의 스칼라 필드가 보존한다.
- **시계열**은 `series`(5초 간격 다운샘플)가 보존한다.
- 원본은 클라이언트 내 계산에만 쓰이며, HealthKit 조회 시에만 채워지고 영속 왕복 시 유실된다.

## `weather` 필드 (`WeatherData`, 자동 조회·자동 분류)

WeatherKit이 자동 조회한 원시 수치와, 그 수치를 앱이 자동 분류한 카테고리다.

| 필드 | 엔티티 프로퍼티 | 타입 | 단위/값 |
|---|---|---|---|
| `temperature` | `temperature` | Number | °C |
| `humidity` | `humidity` | Integer | % (0~100) |
| `windSpeed` | `windSpeed` | Number | m/s |
| `skyCondition` | `skyCondition` | String | `sunny`, `cloudy` |
| `windLevel` | `windLevel` | String | `weak`, `moderate`, `strong` |
| `feelsLike` | `feelsLike` | String | `cold`, `neutral`, `hot` |
| `humidityLevel` | `humidityLevel` | String | `dry`, `humid` |

- 날씨 자동 조회에 실패하면 `weather: null`이다.
- `skyCondition`/`windLevel`/`feelsLike`/`humidityLevel`은 원시 수치를 앱이 자동 분류한 값이며, 각 필드는 항상 존재한다.

## `userWeather` 필드 (`UserWeather`, 유저 직접 선택)

일기 작성 시 유저가 직접 고른 날씨 카테고리다. `weather`(자동)와 구분되며, 각 필드는 독립적으로 선택하지 않을 수 있어 개별 `null`이 가능하다.

| 필드 | 엔티티 프로퍼티 | 타입 | 값 |
|---|---|---|---|
| `skyCondition` | `skyCondition` | String \| null | `sunny`, `cloudy` |
| `windLevel` | `windLevel` | String \| null | `weak`, `moderate`, `strong` |
| `feelsLike` | `feelsLike` | String \| null | `cold`, `neutral`, `hot` |
| `humidityLevel` | `humidityLevel` | String \| null | `dry`, `humid` |

- 유저가 날씨를 전혀 선택하지 않았으면 `userWeather: null`이다.
- 일부 항목만 선택했으면 선택하지 않은 항목만 `null`이다.

## 최상위 사용자 입력 필드

| 필드 | 엔티티 프로퍼티 | 타입 | 규칙 |
|---|---|---|---|
| `painAreas` | `painAreas` | Array\<String\> | 통증이 없으면 `[]` |
| `runningStyle` | `runningStyle` | String \| null | `forefoot`, `midfoot`, `heelfoot` |
| `memo` | `memo` | String \| null | 비어 있으면 `null` |
| `shoes` | `shoes` | String \| null | 신발이 없으면 `null` |
| `difficultyLevel` | `difficultyLevel` | Integer \| null | 1~5 (아래 매핑) |

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
| 기초대사 칼로리 없음 | `totalEnergyBurned` = `activeEnergyBurned` |
| 경로 없음 | `route: []` |
| splits 없음 | `splits: []` |
| 랩 없음(랩 버튼 미사용) | `laps: []` |
| 존 없음(iOS 27 미만 등) | `zoneSummaries: []` |
| series 전체 없음 | `series: null` |
| series의 개별 지표 없음 | 해당 배열 `[]` |
| 통증 없음 | `painAreas: []` |
| 러닝 스타일 미선택 | `runningStyle: null` |
| 메모 없음 | `memo: null` |
| 신발 미선택 | `shoes: null` |
| 난이도 미선택 | `difficultyLevel: null` |
| 날씨 자동 조회 실패 | `weather: null` |
| 유저 날씨 미선택 | `userWeather: null` (일부만 선택 시 해당 항목만 `null`) |

## 서버 확인 요청사항

다음 항목은 최종 API 계약 전에 확인이 필요하다.

1. 미측정 스칼라 값을 `null` 대신 `0`으로 보내고 서버가 `0 = 미측정`으로 해석하는 정책을 수용할 수 있는가? (단 `averagePaceSecondsPerKm`·`elevationAscended`는 `0`이 유효값이라 `null`로 구분한다.)
2. `series`의 `v`가 지표별로 Integer/Number로 갈리는 것을 수용할 수 있는가? (수직 진폭·보폭 길이만 소수 유지)
3. 원시 시계열(`samples`)을 전송에서 제외하고 5초 다운샘플 `series`만 보내는 정책을 수용할 수 있는가? 서버가 원본 해상도를 요구한다면 별도 업로드 경로 협의가 필요하다.
4. `weather`(자동 분류)와 `userWeather`(유저 선택)를 별도 객체로 받을 수 있는가? 서버가 최종 표시에 어느 쪽을 우선하는지에 대한 정책이 필요하다.
5. `startTime`/`endTime`을 로컬 오프셋 포함 ISO 8601로 받는 것을 수용할 수 있는가? (별도 `timeZone` 필드는 보내지 않는다.)
6. `shoes`를 신발 문자열로 받는 것을 수용할 수 있는가? 서버가 신발 식별자(ObjectId) 매핑을 요구한다면 클라이언트 전송 형태를 재협의해야 한다.
7. 같은 `Idempotency-Key`와 같은 body의 재시도는 기존 성공 응답을 반환하고, 같은 `workout.id`가 다른 키로 재전송된 경우에만 409를 반환하는가?
8. 같은 `Idempotency-Key`에 다른 body가 전달되면 어떤 상태 코드와 오류 코드를 반환하는가?

> 이전 버전의 "숫자 페이스가 필요하면 `duration / distance`로 계산하는가?" 항목은 해소됐다. `averagePaceSecondsPerKm`(Integer, sec/km)를 직접 전송한다.

## 예상 오류 처리

| 상태 코드 | 클라이언트 해석 |
|---|---|
| `2xx` | 생성 성공 |
| `400` | 요청 스키마 또는 값 검증 실패 |
| `401` | access token 갱신 후 동일한 `Idempotency-Key`로 1회 재시도 |
| `409` | 이미 저장된 `workout.id` 또는 멱등성 충돌. 서버 오류 코드로 세부 원인 구분 필요 |
| `5xx` | 동일한 body와 `Idempotency-Key`를 유지하여 재시도 가능 |
