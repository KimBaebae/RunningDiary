# 다이어리 생성 API 클라이언트 구현 명세

> 대상: RunDiary iOS 개발자
> 관련 계약: [다이어리 생성 API 요청 스키마 협의안](./create-diary-request.md)
> 백엔드 협의: [v1.1 추가 요청](./IOS_DIARY_API_V1_1_REQUEST.md) → [회신](./ios-diary-api-v1-1-response.md)
> 목적: 현재 앱 상태와 목표 API 계약의 차이를 정의하고 구현·테스트 범위를 명확히 한다.
> 기준 코드: `Dependencies/Models`, `Dependencies/HealthKitService`, `Dependencies/PersistencesService`

## 목표

HealthKit, WeatherKit, 사용자 입력으로 구성한 다이어리를 서버 생성 API에 안전하게 전송한다.

- HealthKit 원본 UUID를 운동 식별자로 보존한다.
- 화면 표시용 엔티티가 아닌 전용 API DTO를 사용한다.
- 대용량 route와 series를 서버 상한에 맞춰 결정적으로 다운샘플링한다.
- 날씨는 원시 수치만 전송하고 표시용 카테고리는 클라이언트에 남긴다.

## 진행 상태

| 영역 | 상태 | 비고 |
|---|---|---|
| `workout.id`에 `HKWorkout.uuid` 보존 | ✅ 완료 | `HealthKitManager+WorkoutAssembly.swift` |
| 숫자형 페이스 | ✅ 완료 | `averagePaceSecondsPerKm: Int?` |
| splits 산출 | ✅ 완료 | `WorkoutSplitCalculator` |
| `timeZone` 보존 | 🔶 부분 | `WorkoutTimeZoneResolver`. 값은 실리지만 **"모름"을 표현하지 못한다**(§8-A) |
| series 상한 2,000 · 샘플링 메타데이터 | ✅ 완료 | `WorkoutSeriesBuilder`, `WorkoutSeries.metadata` |
| route 옵셔널화 (트레드밀 정규화 포함) | ✅ 완료 | `HealthKitWorkout.route: [RoutePoint]?`, `WorkoutRouteResolver` |
| route 다운샘플러 | ✅ 완료 | `RouteDownsampler`. 호출은 DTO 매퍼 몫 |
| 신발 카탈로그 id / 레거시 문자열 분리 | ✅ 완료 | `Diary.shoe`, `Diary.legacyShoe` |
| 레거시 신발 마이그레이션 | 🔶 부분 | `ShoeIdMigrator` 구현. **실행 시점 미배선** |
| 요청 DTO와 매퍼 | ⏳ 미착수 | 아래 "2. 서버 요청 DTO와 매퍼" |
| 생성 네트워크 Client | ⏳ 미착수 | 아래 "3. 다이어리 생성 네트워크 Client" |
| 전송 직전 body 크기 가드 | ⏳ 미착수 | §8-A. **SimpleNetwork 개선 선행**(§8-D) |
| `timeZone` 옵셔널화 | ⏳ 미착수 | §8-A |
| `runningTypeSource` | ⏳ 미착수 | §8-A |
| `totalEnergyBurned` 옵셔널화 | ⏳ 미착수 | §8-A |
| 날씨 원시값 3종 보존 | ⏳ 미착수 | §8-A |
| 오류 body 디코딩 | ⏳ 미착수 | §8-A. **SimpleNetwork 개선 선행**(§8-D) |
| 로컬 복원분 HealthKit 재조회 | ⏳ 미착수 | §8-B. 영속 왕복 소실의 해법 |
| 유저 선택(체감) 날씨 제거 | ⏳ 미착수 | §8-C. **별도 이슈 분리 권고** |

## 현재 상태와 차이

| 영역 | 현재 상태 | 필요한 작업 |
|---|---|---|
| 서버 생성 API | `RunningRecordClient.saveRecord`는 SwiftData에만 저장 | POST RequestAPI, 응답 DTO, 네트워크 Client 추가 |
| 시간 | `startTime`/`endTime`이 `Date`, `timeZone`은 엔티티에 존재하나 모를 때 기기 현재값으로 채움 | UTC ISO 8601 `Z` 문자열, IANA identifier, 정수 초 변환 매퍼. **`timeZone` 옵셔널화**(§8-A) |
| duration | `TimeInterval`(Double) | 반올림한 정수 초로 변환 |
| 미측정 지표 | 상세 조회 실패값을 `0`으로 치환 | 현재 정책 유지. 서버와 `0 = 미측정` 합의 및 DTO 테스트 |
| route | 엔티티가 `[RoutePoint]?`로 "없음"을 표현. 상한은 미적용 | DTO에서 `RouteDownsampler` 호출 및 메타데이터 산출 |
| series | 2,000점 상한·지표별 메타데이터 산출 완료 | DTO 매핑 및 JSON 형태 확정 |
| 신발 | `shoe`(카탈로그)와 `legacyShoe`(로컬) 분리 완료 | `shoeId`에 `shoe?.id`만 매핑, 레거시는 `null` |
| 메모 | 빈 문자열만 `nil` 처리, 길이 제한 없음 | 공백 처리 정책 및 2,000자 제한 추가 |
| 날씨 | `WeatherData`가 원시 수치와 분류 카테고리를 함께 보관. `cloudCover`·`apparentTemperature`는 조회하고도 버림 | 원시 수치만 DTO에 매핑하고 **확장 원시값을 보존**(§8-A). 분류 카테고리와 `userWeather`는 **앱에서 제거**(§8-C) |

## 지표 이름 매핑

HealthKit identifier와 엔티티 프로퍼티명이 다르다. 요청 필드명은 엔티티를 따른다.

| HealthKit identifier | 엔티티 프로퍼티 / 요청 필드 | 단위 |
|---|---|---|
| `runningVerticalOscillation` | `averageVerticalOscillation` | cm |
| `runningGroundContactTime` | `averageGroundContactTime` | ms |
| `walkingStepLength` | `averageStepLength` | m |
| `restingHeartRate` | `restingHeartRate` | bpm |
| `runningPower` | `averagePower` | watts |
| `runningStrideLength` | `averageStrideLength` | m |
| `heartRateRecoveryOneMinute` | `heartRateRecoveryOneMinute` | bpm |

시계열도 같은 규칙을 따른다(`series.verticalOscillation`, `series.groundContactTime`, `series.strideLength`). `averageStepLength`는 스칼라만 전송하며 시계열에는 포함하지 않는다.

`restingHeartRate`는 워크아웃 당일 전체의 `discreteAverage`, `heartRateRecoveryOneMinute`는 종료 후 5분 구간에서 산출한다. 둘 다 시계열이 아니라 스칼라다.

## 구현 범위

### 1. HealthKit 운동 식별자 — 완료, 잔여 과제 있음

`makeWorkout(from:)`이 `HealthKitWorkout(id: workout.uuid, ...)`로 HealthKit 원본 UUID를 보존한다. `HKWorkoutActivity`의 UUID도 `WorkoutLap.id`에 그대로 실린다.

**잔여 과제**: `RunningRecordPersistenceModel`에 `workoutId` 컬럼이 없어 로컬 저장 후 복원하면 `HealthKitWorkout.id`가 새 UUID로 바뀐다. 서버 전송에 `workout.id`가 필수이므로, 로컬 저장분을 전송하려면 컬럼 추가가 선행돼야 한다. HealthKit 조회 직후 전송하는 경로는 영향이 없다.

또한 앱의 중복 판정이 `RunningRecordClient`에서 UUID가 아니라 `startTime` 비교로 이뤄진다. 서버 409(중복 workout) 정책과 어긋날 수 있어 함께 검토한다.

### 2. 서버 요청 DTO와 매퍼

앱 도메인 모델을 직접 `Encodable`로 만들지 않고 서버 계약 전용 타입을 추가한다. `Diary`·`HealthKitWorkout`·`WeatherData`·`PainArea`는 `Encodable`을 채택하지 않았고, `Shoe`는 `Decodable`만 채택하므로 DTO는 필수다.

권장 구조:

```text
CreateDiaryRequest
├── WorkoutRequest
│   ├── RoutePointRequest
│   ├── WorkoutSplitRequest
│   ├── WorkoutLapRequest
│   ├── WorkoutZoneSummaryRequest
│   └── WorkoutSeriesRequest
├── WeatherRequest
└── DiaryInputRequest
```

`WeatherRequest`는 WeatherKit 원시 수치만 갖는다 — `temperature`·`humidity`·`windSpeed`에 더해 `apparentTemperature`·`cloudCover`(+강수)를 §8-A에서 추가한다. `WeatherData`의 분류 카테고리(`skyCondition`·`windLevel`·`feelsLike`·`humidityLevel`)와 `Diary.userWeather`는 DTO에 포함하지 않으며, **앱에서도 제거 예정**이다(§8-C).

DTO 매퍼의 책임:

- `HealthKitWorkout.id`를 UUID 문자열로 변환
- `Date`를 UTC ISO 8601 `Z` 문자열로 변환
- `HealthKitWorkout.timeZone?.identifier`를 `timeZone`으로 설정. 모르면 명시적 JSON `null`(§8-A)
- `duration`·`elapsedTime`·`durationSec`·`startOffsetSec`를 반올림한 정수 초로 변환
- `averagePaceSecondsPerKm`를 그대로 전송(재계산하지 않는다)
- `route`가 있으면 `RouteDownsampler.downsample`을 적용하고 `routeOriginalPointCount`·`routeSamplingMethod`를 함께 채움
- `route`가 `nil`이면 명시적 JSON `null` + `routeOriginalPointCount: 0` + `routeSamplingMethod: "none"`
- `WorkoutSeries.metadata`를 지표 이름 키 객체로 인코딩
- `shoe?.id`만 `shoeId`로 매핑하고 `legacyShoe`는 전송하지 않음
- `series`, `memo`, `weather`가 없을 때 명시적 JSON `null` 인코딩. 날씨 조회에 실패하면 `weather: null`을 보내며 일부 필드만 담은 객체를 만들지 않는다
- `splits`, `laps`, `zoneSummaries`, `painAreas`, 개별 series가 없을 때 빈 배열 인코딩

주의할 두 가지:

1. Swift 합성 `Encodable`은 optional `nil` 키를 생략한다. 서버가 명시적 `null`을 요구하는 필드는 커스텀 `encode(to:)` 또는 동등한 인코딩 전략이 필요하다.
2. 네트워크 계층의 `URLSessionService`가 `keyEncodingStrategy = .convertToSnakeCase`로 고정돼 있다. 계약은 camelCase(`averagePaceSecondsPerKm`)이므로 그대로 두면 `average_pace_seconds_per_km`로 나간다. **§8-D에서 인코더 소유권과 함께 해결한다** — 그 전까지의 대안은 DTO에 명시적 `CodingKeys`를 전부 다는 것뿐이다.

### 3. 다이어리 생성 네트워크 Client

**인증이 필요하므로 `AuthService`의 `AuthenticatedNetworkService` → `SimpleNetwork` 경로를 탄다.** `CoreNetwork`가 아니다. 401 갱신·1회 재시도가 이미 그 계층에 있다.

필요 구성:

- POST용 `CreateDiaryRequestAPI` (`POST /api/v1/running-logs`)
- `Authorization: Bearer` 헤더 구성 — `AuthenticatedNetworkService`가 주입하지 않으므로 **각 API가 자기 `headers`에서 키체인 accessToken을 읽어 구성**해야 한다
- 성공 응답 DTO (`id`·`source`·`workoutId`·`createdAt`)
- 서버 오류 body 및 `detail.code` 디코딩 (§8-D 선행)
- `409 WORKOUT_ALREADY_EXISTS`를 중복 workout 도메인 오류로 매핑
- 로컬 저장과 서버 저장의 실행 순서 및 실패 복구 정책

현재 네트워크 계층의 제약(§8-D에서 해결):

- `RequestAPI.Response`가 `Decodable` 필수라 빈 바디 201 응답을 받을 수 없다. 빈 응답 타입이 필요하다.
- `NetworkError.httpError(statusCode:)`만 던져 오류 body를 파싱하지 않는다. `detail.code` 구분이 불가능하다.
- 인코딩을 내부에서 수행해 전송 직전 `Data.count`를 잴 수 없다.

> 멱등성 헤더는 도입하지 않는다(회신 §3.1). 서버가 유지를 요구하면 `HTTPHeader.custom(name:value:)`로 추가하고 그때 키 관리 정책을 함께 정한다.

저장 순서는 별도 결정이 필요하다.

| 방식 | 장점 | 위험 |
|---|---|---|
| 서버 성공 후 로컬 저장 | 서버와 로컬의 성공 상태가 명확함 | 서버 성공 후 로컬 저장 실패 복구 필요 |
| 로컬 저장 후 서버 전송 | 오프라인 작성에 유리함 | 동기화 상태와 재전송 큐 필요 |

오프라인 생성이 요구사항이 아니라면 초기 구현은 서버 성공 후 로컬 저장을 기본안으로 검토한다.

### 4. route 제한 및 메타데이터 — 완료

`RouteDownsampler`(`Dependencies/Models/Sources/Models/Mappers/`)가 담당한다.

- 원본이 50,000점 이하면 그대로 사용하고 `samplingMethod = .none`
- 초과 시 균등 인덱스로 정확히 50,000점까지 축소하고 `samplingMethod = .uniform`
- 첫 지점과 마지막 지점 보존
- 같은 입력에 항상 같은 출력(결정적)
- 위도·경도 순서 및 시간 순서 보존
- `originalPointCount`는 축약 전 지점 수

엔티티 `HealthKitWorkout.route`는 `[RoutePoint]?`이며 지도 렌더링 품질을 위해 **원본 지점 수를 그대로 유지한다**. 축약은 DTO 매퍼가 전송 시점에만 호출한다.

"경로 없음"은 도메인·영속·와이어 세 계층 모두 `nil`/`null`로 표현하며 빈 배열을 만들지 않는다. `WorkoutRouteResolver`가 판정하고, **트레드밀은 HealthKit이 좌표를 남겼더라도 `nil`로 정규화**해 "트레드밀인데 경로가 있는" 조합을 배제한다. `RouteDataMapper`도 같은 규칙으로 `nil` ↔ `Data?`를 왕복한다.

경로 형태 보존 품질이 부족하면 Douglas-Peucker 같은 공간 기반 단순화를 별도로 비교한다.

**미해결**: 현재 구현은 첫 번째 `HKWorkoutRoute`만 사용한다(`routes.first`). HealthKit이 여러 route sample을 반환하는 경우 결합할지 첫 항목만 사용할지 정책과 테스트가 필요하다.

### 5. series 메타데이터와 상한 — 완료

`WorkoutSeriesBuilder`가 지표별로 `SeriesSamplingMetadata`(원본 개수 + 적용 방식)를 반환하고, `WorkoutSeries.metadata`가 이를 보관한다.

- 상한은 `WorkoutSeriesBuilder.defaultMaxPoints = 2_000` (기존 500에서 상향)
- 5초 버킷 평균만으로 상한 이하가 되면 `fixedIntervalAverage`
- 버킷 평균 후에도 상한을 넘어 균등 축소를 거치면 `uniform`
- `elevation`은 거리축이라 버킷 평균을 쓸 수 없어 `capPoints`로 개수 상한만 적용하고 `none`/`uniform`으로 보고
- 원본 샘플이 0인 지표는 `metadata`에서 제외
- 8축이 모두 비면 `series: nil`, 일부만 비면 해당 배열 `[]`

| 값 | 의미 |
|---|---|
| `none` | 원본 배열 사용 |
| `fixedIntervalAverage` | 고정 시간 버킷의 평균값 사용 |
| `uniform` | 최대 개수에 맞춘 균등 인덱스 선택 |

### 6. 사용자 입력 검증

- `painAreas`가 비어 있으면 `[]`로 보낸다.
- 메모가 비어 있으면 `null`로 보낸다.
- 메모는 최대 2,000자로 제한한다.
- 공백만 있는 메모를 `null`로 볼지 서버와 동일한 trim 정책을 사용한다.
- `shoeId`는 `Diary.shoe?.id`(카탈로그 id)만 담는다. `legacyShoe`만 있는 기록은 `shoeId: null`이다.

`shoeId`에 ObjectId 24자리 hexadecimal 형식 검증은 **넣지 않는다.** 값은 서버 카탈로그(`GET /api/v1/shoes`)에서 그대로 받은 id라 클라이언트가 형식을 재검증할 근거가 없고, 검증을 강제하면 레거시 슬러그가 남은 기록이 전송 자체를 못 하게 된다. 형식 요구가 있다면 서버 확인 항목(협의안 7번)으로 처리한다.

현재 화면은 신발 선택을 필수로 검증하지만, 레거시 기록을 편집하는 경로에서는 `shoeId: null`이 나갈 수 있다.

### 7. 레거시 신발 마이그레이션

`Diary`는 신발을 두 갈래로 보관한다.

| 프로퍼티 | 의미 |
|---|---|
| `shoe: Shoe?` | 카탈로그로 해석된 신발. `id`는 항상 서버 `Shoe.id` |
| `legacyShoe: String?` | 카탈로그로 해석되지 않은 저장 원본 문자열 |

둘은 상호배타적이다. `RunningRecordPersistenceModel.toDomain(shoeResolver:)`이 resolver 성공 여부로 갈라 채우고, `fromDomain`은 `shoe?.id ?? legacyShoe`를 같은 `shoes` 컬럼에 되돌린다. **SwiftData 스키마는 늘리지 않는다.**

`ShoeIdMigrator`(`RunDiary/Sources/Core/Storage/`)가 레거시 문자열을 카탈로그 id로 해석한다.

1. id 완전 일치 — 카탈로그 로드 전에 복원돼 `legacyShoe`로 떨어진 정상 기록
2. 표시 이름 일치 — 옛 `ShoeStorage` 슬러그(`"nike-alphafly-3"`). `LegacyShoeMapper`로 이름을 복원한 뒤 공백·하이픈·대소문자를 제거해 카탈로그와 비교

해석한 id를 `DiaryPatch(shoes:)`로 같은 컬럼에 덮어쓰면, 다음 로드부터 resolver가 해석에 성공해 `Diary.shoe`로 복원된다. 카탈로그 id는 이름으로 환원되지 않아 2단계에서 걸러지므로 이미 마이그레이션된 기록에 다시 적용해도 안전하다.

**미배선**: 마이그레이션 실행 시점은 아직 정하지 않았다. 현재는 순수 계산만 제공하고 앱 시작 경로에 연결하지 않았다.

### 8. v1.1 요청 반영 항목

백엔드의 [v1.1 추가 요청](./IOS_DIARY_API_V1_1_REQUEST.md)과 그에 대한 [회신](./ios-diary-api-v1-1-response.md)에서 파생된 작업이다.

§8-A는 서버 계약과 공유하는 항목이고, **§8-B~D는 회신 문서에 담지 않은 클라이언트 내부 과제**다.

#### 8-A. 서버 계약 반영

| 항목 | 변경 지점 | 비고 |
|---|---|---|
| body 5MiB 가드 | 인코딩 → `Data.count` 확인 → 4.5MiB 초과 시 route 재축약 → 재인코딩 | **§8-D 선행 필요.** `routeOriginalPointCount`는 최초 원본을 유지하고 `routeSamplingMethod`는 `uniform`이 된다 |
| 중복 전송 방지 | `409 WORKOUT_ALREADY_EXISTS`를 **성공 동기화로 간주**하고 재업로드 중지 | `Idempotency-Key` 헤더는 도입하지 않는다(회신 §3.1). 서버가 유지를 요구하면 `HTTPHeader.custom` 한 줄이라 되돌리기 쉽다 |
| `schemaVersion` | 전송하지 않는다 | 서버가 부재를 `1`로 처리한다(회신 §3.2). 버저닝은 URL 경로가 담당 |
| `timeZone` 옵셔널화 | `WorkoutTimeZoneResolver.resolve`에서 `.current` 폴백을 **제거하고 `TimeZone?` 반환**. `HealthKitWorkout.timeZone`도 `TimeZone?`. 표시 호출부는 `?? .current` | 기존 `TZ-02`("메타데이터 없음 → `.current` 대체")가 **명세 변경으로 깨지므로 함께 재작성**한다 |
| `runningTypeSource` | `RunningTypeResolver.resolve`가 판별 근거를 함께 반환 | 값은 `healthKit` / `distanceInference` 2종. `runningType`은 `outdoor \| treadmill` 이분법 유지 |
| `totalEnergyBurned` 옵셔널화 | `HealthKitWorkout.totalEnergyBurned: Double` → `Double?`. `HealthKitManager+WorkoutAssembly`의 `active + (basal ?? 0)`을 basal 유무로 분기 | 기본값 `0` 제거 시 호출부·프리뷰·테스트 파급을 함께 확인한다 |
| 날씨 원시값 보존 | `WeatherData`에 `apparentTemperature`·`cloudCover`(+강수) **저장 프로퍼티** 추가 | `WeatherKitManager`가 이미 이 값들을 받아 분류에만 쓰고 버리므로 **전달만 하면 된다.** SwiftData 컬럼은 추가하지 않는다 — 날씨는 생성 시점에 조회·전송되어 영속 왕복이 불필요하다 |
| 오류 body 디코딩 | `detail.code` 기반 분기 (`409 WORKOUT_ALREADY_EXISTS`, `422 SHOE_NOT_FOUND` 등) | **§8-D 선행 필요.** 현재 네트워크 계층이 오류 body를 버리고 상태 코드만 전달한다 |

#### 8-B. 로컬 복원분은 전송 전 HealthKit 재조회로 채운다

`RunningRecordPersistenceModel`에 대응 컬럼이 없어, SwiftData에서 복원한 `Diary`만으로는 서버 계약을 채울 수 없다.

소실되는 값: `workout.id`(HKWorkout.uuid) · `timeZone` · `runningType` · `elapsedTime` · `totalEnergyBurned` · `elevationAscended` · `splits` · `laps` · `series` · `zoneSummaries` · `samples`

**방침**: 스키마를 확장하지 않고, **전송 직전 HealthKit에서 해당 워크아웃을 재조회해 `HealthKitWorkout`을 다시 조립한다.**

이러면 `workout.id`가 항상 실제 `HKWorkout.uuid`가 되어 서버의 `workout.id` 기반 409 중복 방지가 성립한다. 이는 회신 §3.1(`Idempotency-Key` 제거 제안)의 실질적 전제이기도 하다.

확정해야 할 것:

1. **매칭 키** — 영속 컬럼 중 후보는 `startTime`뿐이다(앱의 기존 중복 판정도 `startTime` 기반). 허용 오차와 다건 매칭 시 선택 규칙을 정한다.
2. **재조회 실패 처리** — HealthKit 권한 철회, 원본 워크아웃 삭제, 매칭 0건. 전송 중단인지 로컬 값만으로 축소 전송인지 정한다.
3. **수동 입력 기록** — HealthKit 유래가 아닌 기록은 재조회 대상이 없다. 전송 대상에서 제외할지 별도 경로를 둘지 정한다.
4. **적용 범위** — 신규 생성 경로는 이미 HealthKit 조회 직후라 재조회가 불필요하다. **소급 동기화 경로에만** 적용한다.

#### 8-C. 유저 선택(체감) 날씨 제거

**결정**: 날씨는 WeatherKit·HealthKit이 조회한 **정량 수치만** 취급하고, 사용자가 직접 고르던 체감 날씨 데이터는 앱에서 제거한다.

> 서버 계약에는 변화가 없다. [요청 스키마 문서](./create-diary-request.md)가 이미 `Diary.userWeather`와 `WeatherData`의 카테고리 4종을 **"전송 제외 항목"**으로 명시해, 요청 바디에 포함된 적이 없기 때문이다. 따라서 회신 문서에는 적지 않는다.

영향 범위가 작지 않다. **별도 이슈로 분리하기를 권고한다.**

| 계층 | 대상 |
|---|---|
| 도메인 | `UserWeather.swift` 삭제, `Diary.userWeather` 제거, `WeatherData`의 `skyCondition`·`windLevel`·`feelsLike`·`humidityLevel` 및 `classify(...)` 제거 |
| 영속 | `RunningRecordPersistenceModel`의 `skyConditionRaw`·`windLevelRaw`·`feelsLikeRaw`·`humidityLevelRaw` 4개 컬럼 |
| UI | `Step2WeatherView`, `StepNavigationBar`, `CreateDiaryFeature`의 관련 State/Action 및 스텝 진행 로직 |
| 테스트 | `WeatherDataTests`, `CreateDiaryFeatureTests`, `UserWeatherMigrationTests`, `LightweightMigrationTests` |

**영속 컬럼 처리는 결정이 필요하다.**

- **(권장) 컬럼 존치, 도메인·UI만 제거** — 마이그레이션 없이 끝난다. 이 4개 컬럼은 `RunningRecordSchemaV4`가 "유저 선택 날씨 필드 **재추가**"라고 기록하고 있어 **제거했다가 되돌린 이력**이 있다. 다시 제거하면 기존 사용자의 입력 데이터가 소멸하고 세 번째 스키마 버전이 필요하다.
- (대안) `RunningRecordSchemaV5`를 신설해 컬럼 삭제 — 스키마는 깔끔해지지만 마이그레이션과 데이터 소멸을 감수한다.

#### 8-D. SimpleNetwork 개선 요청

인증이 필요한 다이어리 API는 `AuthenticatedNetworkService` → `SimpleNetwork`(`github.com/khyeji98/SimpleNetwork`) 경로를 탄다. 그런데 §8-A의 두 항목이 **라이브러리 구조 때문에 앱 코드에서 해결되지 않는다.**

1. **body 크기를 잴 수 없다** — `URLSessionService`가 `RequestAPI.body: Encodable`을 받아 **내부에서** 인코딩한다. 호출부는 최종 `Data.count`를 볼 수 없어 "전송 직전 4.5MiB 확인"을 구현할 수 없다.
2. **오류 body가 버려진다** — `NetworkError.httpError(statusCode:)`가 상태 코드만 담아 서버가 내려주는 `detail.code`를 읽을 수 없다.
3. (동반) **인코더가 `.convertToSnakeCase`로 고정** — 계약은 camelCase다. 위 §2 주의사항 2번과 **같은 지점(인코더 소유권)**에서 함께 해결된다.

아래 프롬프트로 SimpleNetwork 저장소에서 작업을 시작한다.

> **SimpleNetwork 개선 요청 prompt** (현재 1.1.0)
>
> ```
> SimpleNetwork에 세 가지를 추가해줘. 소비자는 RunDiary 앱이고, 대용량(수 MiB) JSON body를
> 서버 크기 제한에 맞춰 보내야 하는 요구가 생겼어. 기존 RequestAPI 채택 타입들이
> 깨지지 않도록 전부 기본 구현을 제공해서 하위 호환을 유지해줘.
>
> 1. 요청 인코딩 결과를 호출부가 확인할 수 있게 해줘.
>    현재 URLSessionService가 RequestAPI.body(Encodable)를 내부에서 인코딩해버려서,
>    호출부가 전송 직전 Data.count를 알 수 없어. 서버가 "UTF-8 JSON 전체 5MiB 초과 시 413"
>    정책이라 앱이 4.5MiB를 넘으면 payload를 축약한 뒤 재인코딩해야 해.
>    다음 중 하나 이상으로 풀어줘:
>    (a) 라이브러리가 쓰는 것과 동일한 인코더를 공개 API로 노출해 호출부가 미리 인코딩·측정
>    (b) RequestAPI가 이미 인코딩된 Data를 body로 넘길 수 있는 경로 제공
>    (c) 전송 직전 body Data를 넘겨받는 훅
>    선호는 (a)+(b) 조합이야. 호출부가 측정하고, 축약 후 확정된 Data를 그대로 전송할 수 있어야 해.
>
> 2. JSONEncoder의 keyEncodingStrategy를 요청별로 지정할 수 있게 해줘.
>    지금 .convertToSnakeCase로 고정돼 있는데, 새 API 계약은 camelCase(averagePaceSecondsPerKm)야.
>    현재는 각 DTO에 명시적 CodingKeys를 전부 손으로 다는 것 말고 방법이 없어.
>    RequestAPI 레벨에서 인코딩 전략을 오버라이드할 수 있게 하고, 기본값은 지금 동작(.convertToSnakeCase)을
>    유지해서 기존 API가 영향받지 않게 해줘.
>
> 3. NetworkError.httpError가 응답 body를 함께 실어줘.
>    지금은 httpError(statusCode:)라 상태 코드만 알 수 있어. 서버가 오류 본문에
>    detail.code(WORKOUT_ALREADY_EXISTS, SHOE_NOT_FOUND 등)를 담아 보내는데
>    앱이 이걸 읽을 수 없어서 같은 상태 코드의 원인을 구분하지 못해.
>    원본 Data(와 가능하면 HTTPURLResponse)를 케이스에 포함하고,
>    호출부가 원하는 타입으로 디코딩할 수 있는 헬퍼를 붙여줘.
>    기존 패턴 매칭(case .httpError(let statusCode))이 깨지지 않는 형태를 우선 검토해줘.
>    깨야 한다면 major 버전을 올리고 마이그레이션 노트를 남겨줘.
>
> 셋 다 테스트를 포함하고, README에 사용 예시를 추가해줘.
> ```

이 요청이 반영되기 전에는 §8-A의 "body 5MiB 가드"와 "오류 body 디코딩"을 착수하지 않는다.

`CoreNetwork`(로컬 패키지)에도 같은 제약이 있으나, 다이어리 API는 인증 경로라 SimpleNetwork만 개선하면 된다. CoreNetwork 정리는 별건으로 남긴다.

## 알려진 한계

### 영속 왕복에서 소실되는 값 — 재조회로 복구한다

로컬 저장 후 복원하면 `workout.id`를 비롯한 워크아웃 상세가 사라지지만, **전송 직전 HealthKit 재조회로 복구한다**(§8-B). 스키마 확장은 하지 않는다.

재조회로 복구할 수 없는 경우만 잔여 한계로 남는다.

- HealthKit 권한이 철회됐거나 원본 워크아웃이 삭제된 기록
- HealthKit 유래가 아닌 수동 입력 기록

`timeZone`은 옵셔널화 이후 소실이 **왜곡이 아니라 명시적 결측**이 된다. 재조회에 실패하면 기기 현재 타임존으로 덮어쓰지 않고 `timeZone: null`로 전송한다.

## TDD 구현 순서

코드 구현 시 프로젝트 규칙에 따라 테스트를 먼저 추가한다.

1. 날짜·timezone·duration·단위 변환 DTO 매퍼 테스트
2. 0 기본값과 null/빈 배열 JSON 인코딩 테스트
3. camelCase 키 인코딩 테스트(`convertToSnakeCase` 충돌 회귀 방지)
4. route DTO의 빈 배열 → `null` 및 다운샘플 메타데이터 매핑 테스트
5. series `metadata` JSON 형태 테스트
6. `shoeId` 매핑 테스트(카탈로그 / 레거시 / 미선택)
7. `weather` 원시값 매핑 및 조회 실패 시 `null` 인코딩 테스트
8. memo 2,000자 제한 테스트
9. 401, 409, 5xx 오류 매핑과 재시도 테스트
10. 서버 성공과 로컬 저장 연계 테스트
11. `timeZone` nil → `null` 인코딩, `totalEnergyBurned` nil → `null` 인코딩 테스트 (§8-A)
12. body 크기 초과 시 route 재축약 테스트 (§8-A, §8-D 선행)
13. 복원 Diary의 HealthKit 재조회 테스트 (§8-B)

프로젝트 테스트 규칙을 따른다.

- Swift Testing의 `@Test`에 한국어 설명 사용
- TestStore 또는 SUT 생성은 private `make*` 헬퍼로 캡슐화
- 기대값을 action/assertion 전에 상수로 선언
- TCA reducer는 `await store.send`, `await store.receive` 패턴 사용

> **테스트 배치 주의**: `Models` 스킴에는 test action이 없어 `Dependencies/Models/Tests/ModelsTests/`는 xcodebuild로 실행되지 않는다. Models 계층 테스트는 `PainAreasMapperTests`·`RouteDownsamplerTests`처럼 `RunDiaryTests` 타겟에 둔다.

## 핵심 테스트 케이스

| ID | 시나리오 | 기대 결과 | 상태 |
|---|---|---|---|
| `DTO-01` | 동일 HKWorkout을 두 번 매핑 | 동일한 `workout.id` | ⏳ |
| `DTO-02` | 미측정 스칼라 지표 | 해당 값 `0` | ⏳ |
| `DTO-03` | 경로 없음 | JSON에 `"route": null` 포함 (빈 배열 아님) | ⏳ |
| `DTO-04` | splits 없음 | JSON에 `"splits": []` 포함 | ⏳ |
| `DTO-05` | series 없음 | JSON에 `"series": null` 포함 | ⏳ |
| `DTO-06` | 통증 및 메모 없음 | `painAreas: []`, `memo: null` | ⏳ |
| `DTO-07` | 시각 매핑 | `startTime`이 `Z` 표기, `timeZone`이 IANA identifier | ⏳ |
| `DTO-08` | duration 매핑 | 정수 초 | ⏳ |
| `DTO-09` | 요청 JSON 전체 | `schemaVersion` 키와 `Idempotency-Key` 헤더가 **없음** (회신 §3.1·§3.2 회귀 방지) | ⏳ |
| `DTO-10` | `timeZone`이 nil | JSON에 `"timeZone": null` 포함 | ⏳ |
| `DTO-11` | 기초대사 미취득 | `totalEnergyBurned: null`, `activeEnergyBurned`는 실측값 유지 | ⏳ |
| `DTO-12` | 인코딩 결과가 4.5MiB 초과 | route 재축약 후 4.5MiB 이하, `routeOriginalPointCount`는 **최초 원본 유지**, method `uniform` | ⏳ |
| `DTO-13` | `runningTypeSource` 매핑 | 메타데이터 있으면 `healthKit`, 없으면 `distanceInference` | ⏳ |
| `TZ-01` | 메타데이터에 타임존 있음 | 해당 타임존 사용 | ✅ |
| `TZ-02` | 메타데이터 없음 / 알 수 없는 identifier | **`nil` 반환** (기존 `TimeZone.current` 대체에서 변경 — §8-A) | ⏳ |
| `ROUTE-00` | 트레드밀 / 실외+지점 없음 | `route == nil` (빈 배열 아님) | ✅ |
| `ROUTE-01` | route 50,000점 | 원본 유지, method `none` | ✅ |
| `ROUTE-02` | route 50,001점 | 최대 50,000점, 양 끝 보존, method `uniform` | ✅ |
| `ROUTE-03` | 동일 입력 반복 호출 | 항상 같은 결과 | ✅ |
| `SERIES-01` | 원본 3,000점 | 결과 2,000점 이하, 원본 개수 보존, method `uniform` | ✅ |
| `SERIES-02` | 버킷 평균만으로 상한 이하 | method `fixedIntervalAverage` | ✅ |
| `SERIES-03` | elevation 상한 초과 | 2,000점으로 축소, method `uniform` | ✅ |
| `SHOE-01` | resolver 해석 성공 | `shoe` 채워지고 `legacyShoe`는 nil | ✅ |
| `SHOE-02` | resolver 해석 실패 | `legacyShoe`에 원본 보존, `shoe`는 nil | ✅ |
| `SHOE-03` | 레거시 슬러그 마이그레이션 | 이름 일치로 카탈로그 id 반환 | ✅ |
| `SHOE-04` | 카탈로그에 없는 레거시 | 매핑하지 않음 | ✅ |
| `WEATHER-01` | 날씨 조회 성공 | `weather`에 원시 수치만 포함, 카테고리 키 없음 | ⏳ |
| `WEATHER-02` | 날씨 조회 실패 | JSON에 `"weather": null` 포함 | ⏳ |
| `WEATHER-03` | 확장 원시값 매핑 | `apparentTemperature`·`cloudCover`가 WeatherKit 조회값 그대로 전달됨 | ⏳ |
| `ERROR-01` | 기존 workoutId로 새 요청 | duplicate workout 도메인 오류 | ⏳ |
| `ERROR-02` | `409 WORKOUT_ALREADY_EXISTS` 수신 | `detail.code`로 판별해 **성공 동기화로 간주**, 재업로드 중지 | ⏳ |
| `SYNC-01` | 복원 Diary 전송 | `startTime`으로 HealthKit 재조회해 `workout.id`가 원본 `HKWorkout.uuid`로 복구됨 | ⏳ |
| `SYNC-02` | 재조회 실패(권한 철회 / 원본 삭제 / 매칭 0건) | §8-B 2번에서 정한 정책대로 처리 | ⏳ |

## 수용 기준

- 서버 생성 요청에 HealthKit 원본 UUID가 포함된다.
- 동일 `workout.id` 재전송에 대한 서버 409를 도메인 오류로 구분한다.
- 요청의 날짜, timezone, 단위, null 및 빈 배열 표현이 서버 계약과 일치한다.
- route는 50,000점, series 각 지표는 2,000점을 초과하지 않는다.
- 모든 다운샘플링은 결정적이며 원본 개수와 적용 방식을 함께 보낸다.
- 신발은 카탈로그 `Shoe.id`만 전송하며 레거시 문자열은 전송하지 않는다.
- 날씨는 원시 수치만 전송하며 표시용 카테고리는 요청에 포함되지 않는다.
- 409 응답 원인을 사용자 또는 재시도 정책이 구분할 수 있다.
- **인코딩된 요청 body가 4.5MiB를 넘지 않는다.**
- **타임존을 모르는 기록은 기기 현재값으로 채우지 않고 `null`로 전송한다.**
- 관련 단위 테스트와 reducer 테스트가 통과한다.

## 구현 전 확인이 필요한 항목

### 서버 회신 대기

[v1.1 회신](./ios-diary-api-v1-1-response.md)의 확인 요청 4건이다.

1. `Idempotency-Key` 제거를 수용하는지 (유지한다면 §2.3 충돌 해소 방식 택일 필요)
2. 강수 지표를 `precipitationAmount`(mm)로 받을 수 있는지
3. 계약 버저닝을 URL 경로로 가르는 데 동의하는지 (아니라면 `schemaVersion`을 채워 보낸다)
4. 서버 저장과 로컬 저장의 순서 및 오프라인 지원 여부

추가로 오류 응답 body의 형태(`detail.code`의 JSON 경로와 타입)를 확정받아야 디코딩 타입을 맞출 수 있다.

### 클라이언트 내부 미결정

5. §8-B — 재조회 매칭 키의 허용 오차·다건 매칭 규칙, 재조회 실패 처리, 수동 입력 기록 취급
6. §8-C — 유저 선택 날씨 영속 컬럼을 존치할지 `RunningRecordSchemaV5`로 삭제할지
7. §8-D — SimpleNetwork 개선 반영 시점 (§8-A의 body 크기 가드·오류 body 디코딩이 여기에 막혀 있다)
8. 여러 `HKWorkoutRoute`가 존재할 때 결합 정책
9. 레거시 신발 마이그레이션 실행 시점

### 해소된 항목

| 기존 질문 | 결론 |
|---|---|
| 미측정 스칼라 `0` 정책 수용 여부 | 서버 수용. `0`을 `null`로 정규화한다(요청 문서 §1) |
| POST endpoint·인증 방식·성공 response body | `POST /api/v1/running-logs`, `Authorization: Bearer`, 응답 형태는 요청 문서 §4에 확정 |
| `series.metadata`·route 메타데이터 JSON 형태 | 서버 수용(요청 문서 §1) |
| `shoeId` 형식 제약과 마이그레이션 전 `null` | 서버 수용. 형식 검증은 넣지 않는다(위 §6) |
| 날씨 원시 수치만 받는지 | 서버가 원시값 확장을 오히려 요청. 구름량·체감온도 보관이 §8-A 작업으로 확정 |
| 로컬 다이어리 동기화 시 `workoutId` 영속 컬럼 | 컬럼을 추가하지 않고 **HealthKit 재조회로 해결**(§8-B) |

위 미결정 항목이 확정되기 전에는 네트워크 요청 DTO의 공개 계약과 재시도 로직을 최종 구현하지 않는다.
