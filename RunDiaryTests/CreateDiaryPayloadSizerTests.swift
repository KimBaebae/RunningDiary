//
//  CreateDiaryPayloadSizerTests.swift
//  RunDiaryTests
//
//  계약: docs/api/create-diary-request.md "body 크기 제한"
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  RouteDownsamplerTests와 같이 실제로 도는 이 타겟에 둔다.
//
//  limit은 작게(수백~수천 바이트) 준다. 실제 4.5MiB payload는 느리고
//  부동소수 인코딩 길이에 따라 불안정해진다.

import Foundation
import Models
import Testing

@Suite("CreateDiaryPayloadSizer.fit")
struct CreateDiaryPayloadSizerTests {

    // MARK: - 상한 이하

    // SIZE-01
    @Test("상한 이하이면 요청이 그대로 반환되고 routeSamplingMethod가 바뀌지 않는다")
    func fit_returnsRequestUnchanged_whenWithinLimit() throws {
        // Given
        let workout = makeWorkoutRequest(route: nil, routeOriginalPointCount: 0, routeSamplingMethod: "none")
        let request = makeRequest(workout: workout)
        let generousLimit = 100_000
        let expectedSamplingMethod = "none"

        // When
        let output = try CreateDiaryPayloadSizer.fit(request, limit: generousLimit)

        // Then
        #expect(output.request == request)
        #expect(output.request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // MARK: - 상한 초과 → 축소

    // DTO-12
    @Test("지점이 많은 route가 작은 limit을 넘으면 축소되고 원본 개수는 유지된다")
    func fit_reducesRoutePoints_whenExceedingSmallLimit() throws {
        // Given
        let originalPointCount = 3_000
        let route = makeRoute(count: originalPointCount)
        let workout = makeWorkoutRequest(
            route: route,
            routeOriginalPointCount: originalPointCount,
            routeSamplingMethod: "none"
        )
        let request = makeRequest(workout: workout)
        let smallLimit = 6_000
        let expectedSamplingMethod = "uniform"

        // When
        let output = try CreateDiaryPayloadSizer.fit(request, limit: smallLimit)

        // Then
        #expect(output.data.count <= smallLimit)
        #expect((output.request.workout.route?.count ?? 0) < originalPointCount)
        #expect(output.request.workout.routeOriginalPointCount == originalPointCount)
        #expect(output.request.workout.routeSamplingMethod == expectedSamplingMethod)
    }

    // MARK: - 축소 불가

    // SIZE-02
    @Test("상한 초과인데 route가 nil이면 irreducible을 던진다")
    func fit_throwsIrreducible_whenNoRouteExceedsLimit() {
        // Given
        let workout = makeWorkoutRequest(route: nil, routeOriginalPointCount: 0, routeSamplingMethod: "none")
        let request = makeRequest(workout: workout)
        let tinyLimit = 5

        // When / Then
        assertThrowsIrreducible {
            try CreateDiaryPayloadSizer.fit(request, limit: tinyLimit)
        }
    }

    // SIZE-03
    @Test("상한 초과인데 지점이 1개면 irreducible을 던진다")
    func fit_throwsIrreducible_whenSinglePointRouteExceedsLimit() {
        // Given
        let route = makeRoute(count: 1)
        let workout = makeWorkoutRequest(route: route, routeOriginalPointCount: 1, routeSamplingMethod: "none")
        let request = makeRequest(workout: workout)
        let tinyLimit = 5

        // When / Then
        assertThrowsIrreducible {
            try CreateDiaryPayloadSizer.fit(request, limit: tinyLimit)
        }
    }

    // SIZE-04
    @Test("지점 1개로 축소해도 상한을 초과하면 irreducible을 던진다")
    func fit_throwsIrreducible_whenEvenSinglePointCandidateExceedsLimit() {
        // Given
        let route = makeRoute(count: 10)
        let workout = makeWorkoutRequest(route: route, routeOriginalPointCount: 10, routeSamplingMethod: "none")
        let request = makeRequest(workout: workout)
        let tinyLimit = 5

        // When / Then
        assertThrowsIrreducible {
            try CreateDiaryPayloadSizer.fit(request, limit: tinyLimit)
        }
    }

    // MARK: - 결정성

    // SIZE-05
    @Test("같은 입력으로 두 번 호출해도 결과 지점 수가 같다")
    func fit_isDeterministic_whenCalledRepeatedly() throws {
        // Given
        let originalPointCount = 3_000
        let route = makeRoute(count: originalPointCount)
        let workout = makeWorkoutRequest(
            route: route,
            routeOriginalPointCount: originalPointCount,
            routeSamplingMethod: "none"
        )
        let request = makeRequest(workout: workout)
        let smallLimit = 6_000

        // When
        let firstOutput = try CreateDiaryPayloadSizer.fit(request, limit: smallLimit)
        let secondOutput = try CreateDiaryPayloadSizer.fit(request, limit: smallLimit)

        // Then
        #expect(firstOutput.request.workout.route?.count == secondOutput.request.workout.route?.count)
    }

    // MARK: - 상수

    // SIZE-06
    @Test("defaultLimitBytes는 4.5MiB(4,718,592바이트)와 같다")
    func defaultLimitBytes_equals4_5MiB() {
        // Given
        let expectedLimitBytes = 4_718_592

        // Then
        #expect(CreateDiaryPayloadSizer.defaultLimitBytes == expectedLimitBytes)
    }
}

// MARK: - Test Helpers

private extension CreateDiaryPayloadSizerTests {
    func makeRoute(count: Int) -> [RoutePointRequest] {
        (0..<count).map { index in
            RoutePointRequest(
                latitude: 37.5 + Double(index) * 0.00001,
                longitude: 126.9 + Double(index) * 0.00001,
                altitude: Double(index),
                elapsedSec: Double(index)
            )
        }
    }

    func makeWorkoutRequest(
        route: [RoutePointRequest]?,
        routeOriginalPointCount: Int,
        routeSamplingMethod: String
    ) -> WorkoutRequest {
        WorkoutRequest(
            id: "9f29b8d7-6a63-4f24-a1ac-62257c519f94",
            startTime: "2026-07-12T06:30:00Z",
            endTime: "2026-07-12T07:12:30Z",
            timeZone: "Asia/Seoul",
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
            activeEnergyBurned: 512.3,
            totalEnergyBurned: 598.1,
            elevationAscended: 42.0,
            restingHeartRate: 58.0,
            heartRateRecoveryOneMinute: 32.0,
            route: route,
            routeOriginalPointCount: routeOriginalPointCount,
            routeSamplingMethod: routeSamplingMethod,
            splits: [],
            laps: [],
            zoneSummaries: [],
            series: nil
        )
    }

    func makeRequest(workout: WorkoutRequest) -> CreateDiaryRequest {
        CreateDiaryRequest(
            workout: workout,
            weather: nil,
            painAreas: [],
            runningStyle: nil,
            memo: nil,
            shoeId: nil,
            difficultyLevel: nil
        )
    }

    /// 던져진 에러가 `CreateDiaryPayloadSizer.SizingError.irreducible`인지 확인한다.
    func assertThrowsIrreducible(
        _ operation: () throws -> CreateDiaryPayloadSizer.Output
    ) {
        do {
            _ = try operation()
            Issue.record("에러가 발생하지 않았다")
        } catch let error as CreateDiaryPayloadSizer.SizingError {
            guard case .irreducible = error else {
                Issue.record("irreducible이 아닌 다른 SizingError: \(error)")
                return
            }
        } catch {
            Issue.record("예상치 못한 에러 타입: \(error)")
        }
    }
}
