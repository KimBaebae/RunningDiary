# 0002. 동기화 엔진과 로컬 데이터 소급 이관

> 상태: 착수 전 · 이슈 미생성(3개로 분할 예정) · 2026-09-09
>
> 선행: [0001](./0001-diary-request-contract.md) — payload 생성 코드는 완료됐다
> 계약 정본: [다이어리 생성 API 요청 스키마](../api/create-diary-request.md)
> 화면 의도: [07. 마이그레이션 로딩](../product/07-migration-loading.md)

## Ⅰ. 착수 전

### 문제

[0001](./0001-diary-request-contract.md)로 `Diary`를 요청 바디로 만드는 코드가 생겼지만, **그것을 실제로 보내는 경로가 없다.** 그리고 기존 사용자가 배포 버전으로 업데이트하면 로컬에 이미 쌓인 일지를 같은 API로 서버에 소급 이관해야 한다.

착수를 막는 것 4가지를 코드에서 직접 확인했다.

| # | 확인한 것 |
|---|---|
| 1 | `AuthenticatedNetworkService`는 `Authorization` 헤더를 **주입하지 않는다.** 같은 파일 20-25행에 그 이유와 TODO가 있다. 인증이 필요한 API가 아직 하나도 없어 아무도 만들지 않았다 |
| 2 | `NetworkError.httpError(statusCode:data:)`의 body를 도메인 오류로 옮기는 코드가 없다 |
| 3 | `RunningRecordPersistenceModel`의 컬럼 30개에 **`workout.id` 컬럼이 없다.** 복원된 워크아웃은 영속 스칼라로 재조립되므로 id가 매번 새 UUID다 |
| 4 | 동기화 상태를 저장할 곳이 없다. 컬럼 30개를 전수 확인했고 **재해석해서 쓸 수 있는 컬럼이 없다** |

3번이 이 작업에서 가장 무거운 제약이다. 서버 중복 방지가 `(userId, workout.id)` 단일 근거인데 id가 매번 달라지면 **이관을 두 번 돌릴 때 서버에 중복 레코드가 쌓이고**, `409 WORKOUT_ALREADY_EXISTS` 기반 "이미 동기화됨" 판정도 작동하지 않는다.

### 결정

#### 1. 로컬 저장 먼저, 그다음 큐 — 이관은 별도 기능이 아니다

백엔드 회신 7번이 모든 신규 일지를 "로컬 저장 성공 → `pending` 큐 등록"으로 규정했다. 그러면 소급 이관은 **"기존 레코드를 큐에 한 번 넣는 것"**이고 같은 엔진이 큐를 비운다.

> **폐기된 `create-diary-client-implementation-spec.md`는 반대를 권고했다** — "오프라인 생성이 요구사항이 아니라면 서버 성공 후 로컬 저장을 기본안으로 검토한다". 그 권고는 백엔드 회신 이전에 쓰였고, 회신이 순서를 지정하면서 뒤집혔다. 그 문서를 폐기한 이유 중 하나다.

이 순서의 부수 효과가 중요하다. **저장 성공 판정이 로컬 기준이므로 오프라인에서도 일지 작성 화면이 막히지 않는다.**

#### 2. 토큰 갱신은 이번 범위에서 뺀다

`TokenRefresher.refresh()`가 `AuthError.notImplemented`를 던져 401 경로가 죽어 있다. `RefreshTokenAPI.swift`에 엔드포인트와 스키마가 이미 적혀 있고 배선만 주석 처리돼 있다.

이관은 레코드 N건을 연속 전송하므로 중간 만료가 예외가 아니라 상시 경로다. 그런데 **`/api/v1/auth/refresh`를 호출할 예정이 아직 없어 스키마 확정을 우선순위에서 미뤘다**(사용자 판단, 2026-09-08).

따라서 401은 **"큐 전체 일시정지 + 재로그인 요구"**로만 처리한다. 이관은 동작하되 토큰이 만료되면 사용자가 다시 로그인해야 한다.

**고르지 않은 쪽**: 스키마가 확정될 때까지 Phase 전체를 미루는 것. 갱신 없이도 이관 자체는 성립하므로 막을 이유가 없다.

#### 3. `Authorization: Bearer`는 각 API가 자기 `headers`에서 구성한다

`AuthService`에 `AuthorizedRequestAPI` 프로토콜을 두고, 기본 `headers` 구현이 키체인 accessToken을 읽어 구성한다. `AuthenticatedNetworkService`가 주입하지 않는 것은 설계 의도이므로 그 계층을 바꾸지 않는다.

#### 4. 전송 직전 HealthKit 재조회 — 실패해도 버리지 않는다

소급 이관 경로에 한해 `startTime`으로 HealthKit을 좁게 재조회해 `HealthKitWorkout`을 다시 조립한다. 신규 생성은 조회 직후라 불필요하다.

같이 복구되는 값: `workout.id` · `timeZone` · `runningType` · `elapsedTime` · `totalEnergyBurned` · `elevationAscended` · `splits` · `laps` · `series` · `zoneSummaries`

| 항목 | 결정 | 이유 |
|---|---|---|
| 매칭 허용오차 | `±60초`. 다건이면 `startTime` 차 최소, 동률이면 `duration` 최근접 | 영속 컬럼 중 매칭 키로 쓸 수 있는 것은 `startTime`뿐이다(앱의 기존 중복 판정도 이 값을 쓴다) |
| 재조회 실패 | **레코드를 버리지 않는다.** `workout.id`에 `Diary.id`를 폴백으로 쓰고 로컬 값만으로 축소 전송 | "전송 불가"로 두면 권한을 껐거나 서드파티 앱 기록이 삭제된 사용자의 일지가 **영구히 서버에 없는 상태로 남는다.** `Diary.id`는 영속된 UUID라 재시도 간 안정적이므로 서버 중복 방지가 그대로 성립한다 |
| 수동 입력 기록 | 위 폴백으로 함께 처리 | 별도 경로를 두면 검증할 분기가 하나 더 는다 |

#### 5. 동기화 상태는 신규 엔티티로 분리한다

`RunningRecordSchemaV5`에 `DiarySyncStatePersistenceModel`을 추가한다. 기존 레코드 모델에 컬럼을 붙이지 않는다.

```
diaryId: UUID (unique)   stateRaw: String   // pending | synced | failed | unsyncable
serverLogId: String?     syncedAt: Date?
attemptCount: Int        lastErrorCode: String?   nextRetryAt: Date?
```

이유 둘. 동기화는 일지와 **다른 관심사**다. 그리고 `RunningRecordPersistenceModel`은 이미 V4에서 컬럼을 되돌린 이력이 있어 **더 흔들지 않는 편이 안전하다**([0001 결정 5](./0001-diary-request-contract.md)). 엔티티 추가는 lightweight migration이다.

#### 6. 진행 UI는 전체 화면이 아니라 상단 플로팅 토스트다

```
┌─────────────────────────────┐
│  ⟳  러닝 일지 동기화 중  12/34  │   자동 노출, 완료 시 자동 소멸
└─────────────────────────────┘
```

> ⚠️ [`docs/product/07-migration-loading.md`](../product/07-migration-loading.md)는 **전체 화면 모달로 조작을 차단**하는 안을 제안했다. 이 결정이 그것을 뒤집는다.

- 이관은 레코드 수 × 네트워크 왕복이라 길어질 수 있다. **업데이트 직후 첫 실행을 통째로 막으면 첫인상이 나쁘다**
- 로컬 데이터는 이미 완전히 사용 가능하다. **지금 UI 중 서버 데이터에 의존하는 화면이 하나도 없으므로** 막을 이유가 없다
- 실패분은 토스트를 탭해 설정 화면의 동기화 상세에서 재시도한다

전체 화면으로 되돌리고 싶으면 `AppFeature.Route`에 `.migrating`을 더하면 된다. **엔진과 상태는 그대로 재사용되므로 UI만 교체된다** — 이 결정을 되돌리는 비용을 낮게 유지하는 것이 설계 조건이다.

#### 7. `409 WORKOUT_ALREADY_EXISTS`는 실패가 아니라 동기화 성공이다

| 응답 | 처리 |
|---|---|
| `201` | `synced`. `serverLogId` 저장 |
| `409 WORKOUT_ALREADY_EXISTS` | **`synced`로 간주**하고 재업로드 중지 |
| `413` / `PAYLOAD_TOO_LARGE` | route를 더 축약해 **새 body로 1회 재시도.** 동일 payload 재시도 금지 |
| `401` | 결정 2에 따라 큐 전체 일시정지 + 재로그인 요구 |
| `422` | `failed`. 자동 재시도 없음. `detail.code` 보존 |
| 네트워크 · `5xx` | exponential backoff. `nextRetryAt` 기록 |

409를 실패로 두면 이미 서버에 있는 레코드를 영원히 재시도한다.

### 예상 위험

1. **이관 트리거의 멱등성.** `@AppStorage("diaryServerBackfillCompleted")` 플래그가 서지 않은 채 앱이 죽으면 다시 큐에 넣는다. 409 경로가 이를 흡수한다고 보지만, **재조회 실패로 `Diary.id` 폴백을 쓴 레코드**는 두 번째 시도에서도 같은 폴백 id가 나와야 한다. `Diary.id`가 영속 UUID라 성립할 것으로 본다 — 검증 대상.
2. **`PersistencesRepository`에 전체 조회가 없다.** `fetchRunningRecords(from:to:)`만 있다. 메서드를 추가해야 하고, 레코드가 많을 때 한 번에 다 읽는 것이 메모리에 안전한지 확인이 필요하다.
3. **재조회가 N건마다 HealthKit을 때린다.** 좁은 범위 조회지만 레코드 수만큼 반복된다. 느리면 배치 조회로 바꿔야 한다.
4. **`DiarySyncEngine`을 actor로 두고 큐를 직렬로 비운다.** 병렬 전송이 빠르겠지만 401 일시정지·backoff·진행률이 전부 복잡해진다. 직렬이 느려서 문제가 되면 그때 바꾼다.

### 미결

- **메모 2,000자 절단**([0001](./0001-diary-request-contract.md) 남은 부채). 전송 시 절단을 유지할지 입력 단계로 옮길지. 이관은 기존 메모를 그대로 올리므로 **여기서 결정이 실제 데이터에 반영된다**
- 이관 실패분의 사용자 노출 방식. 설정 화면 동기화 상세의 형태가 정해지지 않았다
- `/api/v1/auth/refresh` 스키마 (결정 2로 우회 중)

### 분할 예정

| 이슈 | 범위 |
|---|---|
| A | 결정 2·3·7 — Bearer 빌더, 오류 body 디코딩. 네트워크 계층만 |
| B | 결정 4·5 — HealthKit 재조회, 스키마 V5, 동기화 엔진, 신규 생성 경로 전환 |
| C | 결정 1·6 — 소급 이관 트리거와 진행 UI |

권장 PR 크기(500줄)를 넘기지 않기 위한 분할이다.

---

## Ⅱ. 완료 후

<!-- 구현 완료 후 작성한다. Ⅰ은 고치지 않는다. -->
