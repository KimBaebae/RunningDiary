# 0001. 다이어리 전송 계약과 payload 생성 코드

> 상태: 완료 · 이슈 #29 · 착수 2026-09-07 / 완료 2026-09-08
>
> 계약 정본: [다이어리 생성 API 요청 스키마](../api/create-diary-request.md)

## Ⅰ. 착수 전

### 문제

러닝 일지가 SwiftData 로컬에만 저장된다. 서버 전송 경로가 아예 없다.

`POST /api/v1/running-logs`의 필드·타입·단위·`null` 규칙은 계약 문서와 백엔드 회신(2026-08-14, Slack `C0A0MJ9NENP`)으로 **이미 전부 확정돼 있었다.** 없는 것은 그 JSON을 만들어내는 Swift 코드였다.

그런데 매퍼만으로는 해결되지 않는 것이 있었다. **계약이 요구하는 필드 4개에 앱 안에 값의 출처 자체가 없었다.**

| 계약 필드 | 착수 시점의 앱 |
|---|---|
| `weather.cloudCover` · `apparentTemperature` · `precipitationAmount` | WeatherKit이 받아오지만 `WeatherData`가 분류용 init 파라미터로 받아 `classify(...)`에 넘기고 **버렸다.** 저장 프로퍼티가 없다 |
| `workout.runningTypeSource` | `RunningTypeResolver`가 판별 **근거를 반환하지 않았다** |
| `workout.timeZone: null` | `WorkoutTimeZoneResolver`가 `.current`로 폴백해 **`null`이 나올 수 없었다** |
| `workout.totalEnergyBurned: null` | `active + (basal ?? 0)`이라 **`null`이 나올 수 없었다** |

그래서 순서가 엔티티 → DTO다. DTO부터 만들면 채울 값이 없는 필드가 남는다.

### 결정

#### 1. 이관은 별도 기능이 아니다

백엔드 회신 7번이 **모든 신규 일지를 "로컬 저장 먼저 → `pending` 큐 등록"**으로 규정했다. 그러면 기존 로컬 데이터의 소급 이관은 *"기존 레코드를 큐에 한 번 넣는 것"*이 되고 같은 엔진이 큐를 비운다.

**고르지 않은 쪽**: 이관 전용 업로드 경로를 따로 만드는 것. 재시도·오류 처리·진행률이 두 벌이 되고, 둘 중 한쪽에만 버그가 고쳐지는 상태로 갈라진다.

이 결정이 Phase 3~5의 형태를 전부 결정한다. → [0002](./0002-diary-sync-engine.md)

#### 2. 타임존을 모르면 `null`을 보낸다

기기 현재 타임존으로 폴백하지 않는다.

폴백을 두면 해외에서 기록한 러닝을 귀국 후 전송할 때 **틀린 타임존이 참값으로 저장되고, 서버는 그것이 폴백이었다는 사실을 영원히 알 수 없다.** `null`로 보내면 폴백 정책의 소유권이 서버로 넘어가고 서버는 그것이 자기 폴백임을 안다.

메타데이터 부재는 예외가 아니라 상시 경로다 — 서드파티 앱(Strava·Nike Run Club·Garmin) 기록과 수동 입력은 `HKMetadataKeyTimeZone`을 남기지 않는다.

같은 이유로 `totalEnergyBurned`도 옵셔널로 바꿨다. `active + (basal ?? 0)`은 기초대사가 없을 때 활동 칼로리와 **똑같은 값**을 총 칼로리 자리에 실어, 서버가 "기초대사가 0"과 "얻지 못함"을 구분할 수 없게 만든다.

#### 3. 날씨는 WeatherKit 조회 수치만 취급한다

사용자가 하늘 상태·바람·체감·습도를 직접 고르던 입력 단계(`UserWeather` + 카테고리 4종)를 앱에서 제거했다.

같은 날씨를 두 갈래(측정값 / 주관 선택값)로 보관하면 어느 쪽이 참인지 정할 수 없다. v1.1에서 원시값 3종이 추가되면서 **4개 카테고리가 모두 서버에서 재계산 가능해졌다.**

#### 4. `runningTypeSource`는 엔티티에만 두고 전송하지 않는다

값(`healthKit` / `distanceInference`)은 서버와 합의했지만 이번 계약에서는 싣지 않는다. 추정으로 판별된 기록의 비율이 실사용 데이터로 확인되기 전에는 **서버가 이 값으로 무엇을 분기할지 정할 근거가 없다.**

다만 계약 문서에서 조용히 빼지는 않았다. "합의했으나 이번 계약에서는 전송하지 않는다 + 필요하면 알려달라"로 명시했다. 백엔드가 기다리는 필드를 말없이 누락시키면 계약 문서의 신뢰가 깨진다.

#### 5. SwiftData 카테고리 컬럼 4개는 존치한다

카테고리를 제거했지만 `skyConditionRaw`·`windLevelRaw`·`feelsLikeRaw`·`humidityLevelRaw`는 남긴다.

**V4가 이 컬럼들을 한 번 재추가한 이력이 있다.** 또 지우면 세 번째 스키마 버전과 데이터 소멸을 감수해야 한다. 읽지 않는 컬럼이 남는 비용이 그보다 싸다.

반대로 날씨 원시값 3종에는 컬럼을 **두지 않았다.** 날씨는 일지 생성 시점에 조회해 그 자리에서 전송하는 것이 정상 경로라 저장 왕복이 불필요하다. 대신 로컬 복원분은 이 세 값이 `null`로 전송된다 — 계약 문서에 명시했다.

#### 6. 옵셔널 DTO는 커스텀 `encode(to:)`로 명시적 `null`을 낸다

합성 `Encodable`은 옵셔널에 `encodeIfPresent`를 써서 **키를 통째로 지운다.** 계약이 `String | null`처럼 값의 존재를 스키마로 규정하므로 "키 없음"과 "null"을 섞을 수 없다.

**고르지 않은 쪽**: 합성 `Encodable`에 맡기고 서버가 "키 없음 = null"로 받아주기를 기대하는 것. 계약 문서의 문자 그대로가 아니고, 나중에 서버가 엄격해지면 조용히 깨진다.

### 예상 위험

1. `Measurement.value`는 담긴 단위를 그대로 반환한다. `WeatherKitManager`가 `weather.temperature.value`를 변환 없이 쓰고 있어 **계약 단위(°C)와 어긋난 값이 이미 로컬 DB에 들어갔을 수 있다.**
2. Swift 딕셔너리 키가 enum이면 JSON 객체가 아니라 평탄 배열로 인코딩될 것이다. `series.metadata`가 여기 걸린다.
3. `HealthKitWorkout.timeZone`을 옵셔널로 바꾸면 소비처가 넓게 깨질 수 있다.
4. `RunningRecordPersistenceModel`에 `workout.id` 컬럼이 없다. 서버 중복 방지가 `(userId, workout.id)` 단일 근거인데 복원된 워크아웃은 **id가 매번 새 UUID**라, 이관을 두 번 돌리면 서버에 중복이 쌓인다.

### 미결

- `POST /api/v1/auth/refresh` 스키마 확정 여부 → Phase 2를 막고 있었다
- 메모 길이 제한이 계약 문서에는 없고 클라이언트 명세에만 있다

---

## Ⅱ. 완료 후

> 2026-09-08 · `7a77722`..`f53c21e` (7커밋)

### 맞은 예측 / 틀린 예측

| # | 예측 | 결과 |
|---|---|---|
| 1 | 기온 단위가 어긋나 잘못된 값이 저장됐을 수 있다 | **틀렸다.** WeatherKit은 SI(섭씨·m/s)로 준다. 로컬 DB의 기온은 정상이다. 다만 `Measurement.value`가 단위를 따른다는 사실 자체는 맞아서, 의도를 고정하려고 `.converted(to:)`를 명시했다(동작 무변화) |
| 2 | enum 키 딕셔너리가 평탄 배열이 된다 | **맞았다.** 실행으로 확인: `["heartRate", {...}]`. `[String:]`으로 바꾸지 않았으면 서버가 파싱에 실패했을 것이다 |
| 3 | `timeZone` 옵셔널화가 넓게 깨진다 | **틀렸다.** `HealthKitWorkout.timeZone`의 소비처가 init 외에 전혀 없었다. 파급 0, 테스트 단언 2건만 수정 |
| 4 | `workout.id` 컬럼 부재가 이관을 깨뜨린다 | 아직 검증 전. Phase 3에서 다룬다 → [0002](./0002-diary-sync-engine.md) |

3번을 예측 위험으로 잡은 것 자체는 낭비가 아니었다. 다만 **grep 한 번이면 착수 전에 답이 나왔다.** 이후로는 "넓게 깨질 것 같다"를 위험으로 적기 전에 소비처를 먼저 센다.

### 구현 중 드러난 것

**인코딩 동작은 추측하지 말고 실행해서 확인한다.** 아래 셋은 짧은 Swift 스크립트 한 번으로 전부 확정됐다.

| 확인한 것 | 결과 |
|---|---|
| `container.encode(nil옵셔널, forKey:)` | `"a":null` — 키가 남는다. `encodeIfPresent`와 다르다 |
| `[EnumKey: V]` 인코딩 | `["heartRate", {...}]` 평탄 배열. `[String: V]`는 객체 |
| `date.formatted(.iso8601)` | 기기 타임존과 무관하게 `2026-07-12T06:30:00Z`. **`ISO8601DateFormatter` 공유 인스턴스를 만들 필요가 없다**(Sendable 문제도 함께 사라진다) |

**pre-commit 훅은 `swiftlint lint --strict`다.** `file_length` 같은 *경고*가 에러로 승격돼 커밋을 막는다. 에이전트에 게이트를 시킬 때 `--quiet`만 쓰면 차단 사유가 보이지 않는다. → 게이트 지시에 `--strict`를 명시한다.

**`xcodebuild`가 `project.pbxproj` 항목을 재정렬하는 일이 있다.** 85줄이 바뀌었지만 공백 제거 후 정렬 비교로 내용이 동일함을 확인하고 되돌렸다. 새 테스트 파일은 동기화 그룹(`PBXFileSystemSynchronizedRootGroup`)으로 잡히므로 pbxproj 등록이 필요 없다.

**패키지마다 테스트 로그 형식이 다르다.** `HealthKitService`는 Swift Testing이라 `passed on 'Clone N'`이 나오지 않고 `✔ Test run with N tests in M suites passed`가 나온다. `grep -c 'passed on'`으로 세면 0건이 나와 "테스트가 안 돌았다"로 오독한다.

**계약과 구현이 어긋난 지점은 0건이었다.** 테스트 37건이 전부 첫 실행에 통과했다. 이는 계약 문서가 구현 착수 전에 v1.1로 확정돼 있었기 때문이지, 테스트가 약해서가 아니다 — 단언이 실제 JSON을 `keys.contains` + `is NSNull`로 검사하는지 개별 확인했다.

### 남은 부채

| 항목 | 내용 |
|---|---|
| **메모 2,000자 절단** | `create-diary-client-implementation-spec.md`(폐기됨)가 제한을 뒀고 계약 문서에는 없다. 현재 매퍼가 전송 시 절단한다. **전송 시 절단은 로컬에 2,100자가 남고 서버에 2,000자가 저장돼 둘이 영구히 어긋난다.** 결정 2("모르는 값을 아는 값처럼 저장하지 않는다")와 같은 종류의 문제이므로 입력 단계에서 막는 편이 옳다고 본다. 미결 |
| 미사용 L10n 키 | 날씨 카테고리 제거 후 String Catalog에 남았다. `/refresh-strings` 대상 |
| `AuthServiceTests` | 스킴에 test action이 없어 실행 불가 + 헬퍼가 자체 coder를 만들어 `AuthNetworkCoding` 불변식을 보호하지 못한다 |
| 토큰 갱신 | `TokenRefresher.refresh()`가 `AuthError.notImplemented`를 던진다. 호출 예정이 없어 우선순위에서 미뤘다 → [0002](./0002-diary-sync-engine.md) |

### 폐기한 문서

- `docs/api/IOS_DIARY_API_V1_1_REQUEST.md` — 백엔드의 v1.1 요청 초안(2026-08-05)
- `docs/api/ios-diary-api-v1-1-response.md` — 그에 대한 클라이언트 회신(2026-08-07)
- `docs/api/create-diary-client-implementation-spec.md` — 구현 전 클라이언트 명세

앞의 둘은 협의가 2026-08-14 백엔드 최종 회신으로 닫혔고, 결론이 계약 문서의 해소 표에 전부 반영됐다. 셋째는 절반이 구현으로 대체됐고 남은 절반은 [0002](./0002-diary-sync-engine.md)로 옮겼다.

원문이 필요하면 이 커밋 직전 리비전에서 꺼낸다.
