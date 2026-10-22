//
//  CreateDiaryRequestMapperTests.swift
//  RunDiaryTests
//
//  계약: docs/api/create-diary-request.md (v1.1 확정본)
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  RouteDownsamplerTests와 같이 실제로 도는 이 타겟에 둔다.
//
//  workout 매핑(id·시간·타임존·스칼라·route·series.metadata)만 다룬다.
//  Diary 최상위 사용자 입력 필드(신발·메모·날씨)는 CreateDiaryRequestFieldMappingTests에 있다.
//  SUT 생성 헬퍼(makeMapperWorkout 등)는 CreateDiaryRequestMapperTestSupport에서 공유한다.

import Foundation
import Models
import Testing

@Suite("CreateDiaryRequestMapper - workout 매핑")
struct CreateDiaryRequestMapperTests {

    // MARK: - workout.id

    // DTO-01
    @Test("같은 HealthKitWorkout을 두 번 매핑해도 workout.id는 소문자 UUID로 동일하다")
    func request_from_mapsSameWorkoutIdAsLowercaseUUID() {
        // Given
        let workoutId = UUID(uuidString: "9F29B8D7-6A63-4F24-A1AC-62257C519F94")!
        let workout = makeMapperWorkout(id: workoutId)
        let diary = makeMapperDiary(workout: workout)
        let expectedId = "9f29b8d7-6a63-4f24-a1ac-62257c519f94"

        // When
        let firstRequest = CreateDiaryRequestMapper.request(from: diary)
        let secondRequest = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(firstRequest.workout.id == expectedId)
        #expect(secondRequest.workout.id == expectedId)
        #expect(firstRequest.workout.id == secondRequest.workout.id)
    }

    // MARK: - 미측정 스칼라

    // DTO-02
    @Test("미측정 스칼라 지표가 0이면 요청에도 0이 그대로 실린다")
    func request_from_keepsZeroForUnmeasuredScalars() {
        // Given
        let expectedZeroInt = 0
        let expectedZeroDouble = 0.0
        let workout = makeMapperWorkout(
            averageHeartRate: expectedZeroInt,
            averageCadence: expectedZeroInt,
            averagePower: expectedZeroDouble,
            averageVerticalOscillation: expectedZeroDouble,
            averageGroundContactTime: expectedZeroDouble,
            averageStepLength: expectedZeroDouble,
            averageStrideLength: expectedZeroDouble,
            activeEnergyBurned: expectedZeroDouble,
            restingHeartRate: expectedZeroDouble,
            heartRateRecoveryOneMinute: expectedZeroDouble
        )
        let diary = makeMapperDiary(workout: workout)

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.averageHeartRate == expectedZeroInt)
        #expect(request.workout.averageCadence == expectedZeroInt)
        #expect(request.workout.averagePower == expectedZeroDouble)
        #expect(request.workout.averageVerticalOscillation == expectedZeroDouble)
        #expect(request.workout.averageGroundContactTime == expectedZeroDouble)
        #expect(request.workout.averageStepLength == expectedZeroDouble)
        #expect(request.workout.averageStrideLength == expectedZeroDouble)
        #expect(request.workout.activeEnergyBurned == expectedZeroDouble)
        #expect(request.workout.restingHeartRate == expectedZeroDouble)
        #expect(request.workout.heartRateRecoveryOneMinute == expectedZeroDouble)
    }

    // MARK: - 시간 · 타임존

    // DTO-07
    @Test("startTime/endTime은 Z로 끝나는 UTC ISO 8601이고 timeZone은 IANA identifier다")
    func request_from_formatsStartEndTimeAndTimeZone() {
        // Given
        let fixedStart = Date(timeIntervalSince1970: 1_783_837_800)
        let fixedEnd = Date(timeIntervalSince1970: 1_783_840_350)
        let workout = makeMapperWorkout(
            startDate: fixedStart,
            endDate: fixedEnd,
            timeZone: TimeZone(identifier: "Asia/Seoul")
        )
        let diary = makeMapperDiary(workout: workout)
        let expectedStartTime = "2026-07-12T06:30:00Z"
        let expectedEndTime = "2026-07-12T07:12:30Z"
        let expectedTimeZone = "Asia/Seoul"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.startTime == expectedStartTime)
        #expect(request.workout.endTime == expectedEndTime)
        #expect(request.workout.timeZone == expectedTimeZone)
    }

    // DTO-08
    @Test("duration/elapsedTime이 소수 초면 반올림된 정수로 전달된다")
    func request_from_roundsFractionalDurationAndElapsedTime() {
        // Given
        let workout = makeMapperWorkout(duration: 1_800.6, elapsedTime: 1_800.6)
        let diary = makeMapperDiary(workout: workout)
        let expectedSeconds = 1_801

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.duration == expectedSeconds)
        #expect(request.workout.elapsedTime == expectedSeconds)
    }

    // MARK: - route 정규화

    // ROUTE-DTO-01
    @Test("route가 nil이면 파생 필드도 경로 없음 값이 된다")
    func request_from_normalizesRouteFields_whenRouteIsNil() {
        // Given
        let workout = makeMapperWorkout(route: nil)
        let diary = makeMapperDiary(workout: workout)
        let expectedOriginalPointCount = 0
        let expectedSamplingMethod = "none"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.route == nil)
        #expect(request.workout.routeOriginalPointCount == expectedOriginalPointCount)
        #expect(request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // ROUTE-DTO-02
    @Test("route가 빈 배열이면 nil과 동일하게 처리된다")
    func request_from_normalizesRouteFields_whenRouteIsEmpty() {
        // Given
        let workout = makeMapperWorkout(route: [])
        let diary = makeMapperDiary(workout: workout)
        let expectedOriginalPointCount = 0
        let expectedSamplingMethod = "none"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.route == nil)
        #expect(request.workout.routeOriginalPointCount == expectedOriginalPointCount)
        #expect(request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // ROUTE-DTO-03
    @Test("트레드밀인데 좌표가 있으면 route가 null로 정규화된다")
    func request_from_normalizesRouteToNil_whenTreadmillHasCoordinates() {
        // Given
        let route = makeMapperRoutePoints(count: 3)
        let workout = makeMapperWorkout(runningType: .treadmill, route: route)
        let diary = makeMapperDiary(workout: workout)
        let expectedOriginalPointCount = 0
        let expectedSamplingMethod = "none"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.route == nil)
        #expect(request.workout.routeOriginalPointCount == expectedOriginalPointCount)
        #expect(request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // ROUTE-DTO-04
    @Test("실외 달리기이고 경로 지점이 3개면 그대로 전달되고 원본 개수도 3이다")
    func request_from_keepsRoutePoints_whenOutdoorWithThreePoints() {
        // Given
        let route = makeMapperRoutePoints(count: 3)
        let workout = makeMapperWorkout(runningType: .outdoor, route: route)
        let diary = makeMapperDiary(workout: workout)
        let expectedPointCount = 3
        let expectedSamplingMethod = "none"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.route?.count == expectedPointCount)
        #expect(request.workout.routeOriginalPointCount == expectedPointCount)
        #expect(request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // MARK: - series.metadata

    // SERIES-META
    @Test("series.metadata의 SeriesMetric 키가 String으로 변환된다")
    func request_from_convertsSeriesMetadataKeysToString() {
        // Given
        let metadata: [SeriesMetric: SeriesSamplingMetadata] = [
            .heartRate: SeriesSamplingMetadata(originalSampleCount: 3_120, samplingMethod: .fixedIntervalAverage),
            .elevation: SeriesSamplingMetadata(originalSampleCount: 2, samplingMethod: .none),
        ]
        let series = WorkoutSeries(
            sampleIntervalSec: 5,
            heartRate: [SeriesPoint(t: 0, v: 132)],
            paceSecondsPerKm: [],
            cadence: [],
            elevation: [],
            metadata: metadata
        )
        let workout = makeMapperWorkout(series: series)
        let diary = makeMapperDiary(workout: workout)
        let expectedHeartRateKey = "heartRate"
        let expectedElevationKey = "elevation"

        // When
        let request = CreateDiaryRequestMapper.request(from: diary)

        // Then
        #expect(request.workout.series?.metadata.keys.contains(expectedHeartRateKey) == true)
        #expect(request.workout.series?.metadata.keys.contains(expectedElevationKey) == true)
    }
}
