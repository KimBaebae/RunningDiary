//
//  CreateDiaryRequestEncodingTests.swift
//  RunDiaryTests
//
//  계약: docs/api/create-diary-request.md (v1.1 확정본)
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  RouteDownsamplerTests와 같이 실제로 도는 이 타겟에 둔다.
//
//  이 계약의 핵심은 "키 없음"과 "명시적 null"의 구분이다. `json[key] == nil`은 둘을
//  구분하지 못하므로, `keys.contains` + `is NSNull` 두 단언을 항상 함께 쓴다.

import Foundation
import Models
import Testing

@Suite("CreateDiaryRequest 인코딩")
struct CreateDiaryRequestEncodingTests {

    // MARK: - workout 내부 null / 빈 배열

    // DTO-03
    @Test("경로가 없으면 workout.route 키는 있고 값은 명시적 null이다")
    func encode_setsRouteKeyToNull_whenRouteIsNil() throws {
        // Given
        let workout = makeWorkoutRequest(route: nil, routeOriginalPointCount: 0, routeSamplingMethod: "none")
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("route"))
        #expect(workoutJSON["route"] is NSNull)
    }

    // DTO-04
    @Test("splits/laps/zoneSummaries가 없으면 null이 아닌 빈 배열로 인코딩된다")
    func encode_encodesEmptyArrays_whenSplitsLapsZonesAreEmpty() throws {
        // Given
        let workout = makeWorkoutRequest(splits: [], laps: [], zoneSummaries: [])
        let request = makeRequest(workout: workout)
        let expectedCount = 0

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("splits"))
        #expect((workoutJSON["splits"] as? [Any])?.count == expectedCount)
        #expect(workoutJSON.keys.contains("laps"))
        #expect((workoutJSON["laps"] as? [Any])?.count == expectedCount)
        #expect(workoutJSON.keys.contains("zoneSummaries"))
        #expect((workoutJSON["zoneSummaries"] as? [Any])?.count == expectedCount)
    }

    // DTO-05
    @Test("series가 없으면 workout.series 키는 있고 값은 명시적 null이다")
    func encode_setsSeriesKeyToNull_whenSeriesIsNil() throws {
        // Given
        let workout = makeWorkoutRequest(series: nil)
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("series"))
        #expect(workoutJSON["series"] is NSNull)
    }

    // DTO-10
    @Test("timeZone이 nil이면 키는 있고 값은 명시적 null이다")
    func encode_setsTimeZoneKeyToNull_whenTimeZoneIsNil() throws {
        // Given
        let workout = makeWorkoutRequest(timeZone: nil)
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("timeZone"))
        #expect(workoutJSON["timeZone"] is NSNull)
    }

    // DTO-11
    @Test("기초대사 미취득 시 totalEnergyBurned는 null이고 activeEnergyBurned는 실측값을 유지한다")
    func encode_setsTotalEnergyBurnedNull_whileKeepingActiveEnergyBurned() throws {
        // Given
        let expectedActiveEnergyBurned = 512.3
        let workout = makeWorkoutRequest(activeEnergyBurned: expectedActiveEnergyBurned, totalEnergyBurned: nil)
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("totalEnergyBurned"))
        #expect(workoutJSON["totalEnergyBurned"] is NSNull)
        #expect(workoutJSON["activeEnergyBurned"] as? Double == expectedActiveEnergyBurned)
    }

    // MARK: - 최상위 null / 빈 배열

    // DTO-06
    @Test("통증·메모가 없으면 painAreas는 빈 배열, memo는 명시적 null이다")
    func encode_encodesEmptyPainAreasAndNullMemo_whenAbsent() throws {
        // Given
        let workout = makeWorkoutRequest()
        let request = makeRequest(workout: workout, painAreas: [], memo: nil)
        let expectedCount = 0

        // When
        let json = try encodeJSON(request)

        // Then
        #expect(json.keys.contains("painAreas"))
        #expect((json["painAreas"] as? [Any])?.count == expectedCount)
        #expect(json.keys.contains("memo"))
        #expect(json["memo"] is NSNull)
    }

    // WEATHER-02
    @Test("날씨 조회 실패 시 최상위 weather 키는 있고 값은 명시적 null이다")
    func encode_setsWeatherKeyToNull_whenWeatherIsNil() throws {
        // Given
        let workout = makeWorkoutRequest()
        let request = makeRequest(workout: workout, weather: nil)

        // When
        let json = try encodeJSON(request)

        // Then
        #expect(json.keys.contains("weather"))
        #expect(json["weather"] is NSNull)
    }

    // MARK: - 회귀 방지 (전송 제외 항목)

    // DTO-09
    @Test("요청 JSON 최상위와 workout 어디에도 schemaVersion 키가 없다")
    func encode_omitsSchemaVersionKey_everywhere() throws {
        // Given
        let workout = makeWorkoutRequest()
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(!json.keys.contains("schemaVersion"))
        #expect(!workoutJSON.keys.contains("schemaVersion"))
    }

    // DTO-13
    @Test("요청 JSON 어디에도 runningTypeSource 키가 없다")
    func encode_omitsRunningTypeSourceKey_everywhere() throws {
        // Given
        let workout = makeWorkoutRequest()
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(!json.keys.contains("runningTypeSource"))
        #expect(!workoutJSON.keys.contains("runningTypeSource"))
    }

    // MARK: - 키 네이밍

    // KEY-01
    @Test("키 이름이 camelCase로 인코딩되고 snake_case 키는 존재하지 않는다")
    func encode_usesCamelCaseKeys() throws {
        // Given
        let workout = makeWorkoutRequest()
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])

        // Then
        #expect(workoutJSON.keys.contains("averagePaceSecondsPerKm"))
        #expect(!workoutJSON.keys.contains("average_pace_seconds_per_km"))
    }

    // MARK: - series.metadata 형태

    // SERIES-JSON
    @Test("series.metadata는 배열이 아니라 지표 이름을 키로 갖는 객체로 인코딩된다")
    func encode_encodesSeriesMetadataAsObject_notArray() throws {
        // Given
        let expectedOriginalSampleCount = 3_120
        let metadata: [String: SeriesSamplingMetadata] = [
            "heartRate": SeriesSamplingMetadata(originalSampleCount: expectedOriginalSampleCount, samplingMethod: .fixedIntervalAverage),
            "elevation": SeriesSamplingMetadata(originalSampleCount: 2, samplingMethod: .none),
        ]
        let series = WorkoutSeriesRequest(
            sampleIntervalSec: 5,
            heartRate: [SeriesPoint(t: 0, v: 132)],
            paceSecondsPerKm: [],
            cadence: [],
            power: [],
            verticalOscillation: [],
            groundContactTime: [],
            strideLength: [],
            elevation: [],
            metadata: metadata
        )
        let workout = makeWorkoutRequest(series: series)
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])
        let seriesJSON = try #require(workoutJSON["series"] as? [String: Any])
        let metadataJSON = try #require(seriesJSON["metadata"] as? [String: Any])
        let heartRateMetadata = try #require(metadataJSON["heartRate"] as? [String: Any])

        // Then
        #expect(heartRateMetadata["originalSampleCount"] as? Int == expectedOriginalSampleCount)
    }

    // MARK: - 중첩 배열 원소의 null

    // NULL-01
    @Test("splits/laps/zoneSummaries의 옵셔널 필드가 nil이면 원소 안에서도 키가 남고 명시적 null이다")
    func encode_keepsKeysAsNull_forNilOptionalFieldsInsideNestedArrays() throws {
        // Given
        let split = WorkoutSplitRequest(
            index: 1,
            distanceKm: 1.0,
            durationSec: 330,
            paceSecondsPerKm: 330,
            averageHeartRate: nil,
            averageCadence: nil,
            averagePower: nil,
            elevationGainM: nil
        )
        let lap = WorkoutLapRequest(
            id: "2f0f5a61-9c1d-4a9e-9f1b-7c0f4d2ab111",
            index: 1,
            startOffsetSec: 0,
            durationSec: 600,
            distanceKm: 1.72,
            paceSecondsPerKm: nil,
            averageHeartRate: nil,
            averagePower: nil,
            averageCadence: nil
        )
        let zoneSummary = WorkoutZoneSummaryRequest(
            metric: "heartRate",
            source: nil,
            durations: [WorkoutZoneDurationRequest(index: 1, minimum: nil, maximum: 120, durationSec: 180)]
        )
        let workout = makeWorkoutRequest(splits: [split], laps: [lap], zoneSummaries: [zoneSummary])
        let request = makeRequest(workout: workout)

        // When
        let json = try encodeJSON(request)
        let workoutJSON = try #require(json["workout"] as? [String: Any])
        let splitJSON = try #require((workoutJSON["splits"] as? [[String: Any]])?.first)
        let lapJSON = try #require((workoutJSON["laps"] as? [[String: Any]])?.first)
        let zoneJSON = try #require((workoutJSON["zoneSummaries"] as? [[String: Any]])?.first)
        let durationJSON = try #require((zoneJSON["durations"] as? [[String: Any]])?.first)

        // Then
        #expect(splitJSON.keys.contains("averageHeartRate"))
        #expect(splitJSON["averageHeartRate"] is NSNull)
        #expect(lapJSON.keys.contains("paceSecondsPerKm"))
        #expect(lapJSON["paceSecondsPerKm"] is NSNull)
        #expect(zoneJSON.keys.contains("source"))
        #expect(zoneJSON["source"] is NSNull)
        #expect(durationJSON.keys.contains("minimum"))
        #expect(durationJSON["minimum"] is NSNull)
    }
}

// MARK: - Test Helpers

private extension CreateDiaryRequestEncodingTests {
    func makeWorkoutRequest(
        timeZone: String? = "Asia/Seoul",
        activeEnergyBurned: Double = 512.3,
        totalEnergyBurned: Double? = 598.1,
        route: [RoutePointRequest]? = nil,
        routeOriginalPointCount: Int = 0,
        routeSamplingMethod: String = "none",
        splits: [WorkoutSplitRequest] = [],
        laps: [WorkoutLapRequest] = [],
        zoneSummaries: [WorkoutZoneSummaryRequest] = [],
        series: WorkoutSeriesRequest? = nil
    ) -> WorkoutRequest {
        WorkoutRequest(
            id: "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
            startTime: "2026-07-12T06:30:00Z",
            endTime: "2026-07-12T07:12:30Z",
            timeZone: timeZone,
            runningType: "outdoor",
            distance: 7.42,
            duration: 2_550,
            elapsedTime: 2_570,
            averagePaceSecondsPerKm: 344,
            averageHeartRate: 152,
            averageCadence: 174,
            averagePower: 310.0,
            averageVerticalOscillation: 8.4,
            averageGroundContactTime: 236.0,
            averageStepLength: 1.12,
            averageStrideLength: 1.35,
            activeEnergyBurned: activeEnergyBurned,
            totalEnergyBurned: totalEnergyBurned,
            elevationAscended: 42.0,
            restingHeartRate: 58.0,
            heartRateRecoveryOneMinute: 32.0,
            route: route,
            routeOriginalPointCount: routeOriginalPointCount,
            routeSamplingMethod: routeSamplingMethod,
            splits: splits,
            laps: laps,
            zoneSummaries: zoneSummaries,
            series: series
        )
    }

    func makeRequest(
        workout: WorkoutRequest,
        weather: WeatherRequest? = nil,
        painAreas: [String] = [],
        memo: String? = nil
    ) -> CreateDiaryRequest {
        CreateDiaryRequest(
            workout: workout,
            weather: weather,
            painAreas: painAreas,
            runningStyle: nil,
            memo: memo,
            shoeId: nil,
            difficultyLevel: nil
        )
    }

    func encodeJSON(_ request: CreateDiaryRequest) throws -> [String: Any] {
        let data = try JSONEncoder().encode(request)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
