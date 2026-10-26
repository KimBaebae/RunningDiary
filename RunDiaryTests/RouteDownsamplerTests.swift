//
//  RouteDownsamplerTests.swift
//  RunDiaryTests
//
//  Created by 김혜지 on 8/3/26.
//
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않는다.
//  PainAreasMapperTests와 같이 실제로 도는 이 타겟에 둔다.

import Foundation
import Models
import Testing

@Suite("RouteDownsampler.downsample")
struct RouteDownsamplerTests {

    // MARK: - 상한 미만 / 경계

    @Test("빈 경로는 빈 결과와 none을 반환한다")
    func downsample_returnsEmpty_whenRouteIsEmpty() {
        // Given
        let route: [RoutePoint] = []
        let expectedMethod = SeriesSamplingMethod.none

        // When
        let result = RouteDownsampler.downsample(route)

        // Then
        #expect(result.points.isEmpty)
        #expect(result.originalPointCount == 0)
        #expect(result.samplingMethod == expectedMethod)
    }

    @Test("서버 상한은 계약과 같은 50,000이다")
    func defaultMaxPoints_matchesServerContract() {
        // Given
        let expectedMaxPoints = 50_000

        // Then
        #expect(RouteDownsampler.defaultMaxPoints == expectedMaxPoints)
    }

    @Test("상한과 같은 50,000점은 축소 없이 원본을 유지하고 none으로 보고한다")
    func downsample_keepsOriginal_whenCountEqualsMaxPoints() {
        // Given
        let route = makeRoute(count: RouteDownsampler.defaultMaxPoints)
        let expectedMethod = SeriesSamplingMethod.none

        // When
        let result = RouteDownsampler.downsample(route)

        // Then
        #expect(result.points.count == RouteDownsampler.defaultMaxPoints)
        #expect(result.points == route)
        #expect(result.originalPointCount == RouteDownsampler.defaultMaxPoints)
        #expect(result.samplingMethod == expectedMethod)
    }

    // MARK: - 상한 초과

    @Test("50,001점은 50,000점으로 축소되고 원본 개수와 uniform을 보고한다")
    func downsample_reducesToMaxPoints_whenCountExceedsMaxPoints() {
        // Given
        let originalCount = RouteDownsampler.defaultMaxPoints + 1
        let route = makeRoute(count: originalCount)
        let expectedMethod = SeriesSamplingMethod.uniform

        // When
        let result = RouteDownsampler.downsample(route)

        // Then
        #expect(result.points.count == RouteDownsampler.defaultMaxPoints)
        #expect(result.originalPointCount == originalCount)
        #expect(result.samplingMethod == expectedMethod)
    }

    @Test("축소해도 첫 지점과 마지막 지점은 보존된다")
    func downsample_preservesEndpoints_whenReduced() {
        // Given
        let route = makeRoute(count: 1_000)
        let maxPoints = 10
        let expectedFirst = route.first
        let expectedLast = route.last

        // When
        let result = RouteDownsampler.downsample(route, maxPoints: maxPoints)

        // Then
        #expect(result.points.count == maxPoints)
        #expect(result.points.first == expectedFirst)
        #expect(result.points.last == expectedLast)
    }

    @Test("축소 후에도 경과초 오름차순이 유지된다")
    func downsample_preservesChronologicalOrder_whenReduced() {
        // Given
        let route = makeRoute(count: 1_000)
        let maxPoints = 50

        // When
        let result = RouteDownsampler.downsample(route, maxPoints: maxPoints)

        // Then
        let elapsed = result.points.compactMap(\.elapsedSec)
        #expect(elapsed.count == result.points.count)
        #expect(elapsed == elapsed.sorted())
    }

    @Test("동일한 입력으로 반복 호출해도 항상 같은 결과를 반환한다")
    func downsample_isDeterministic_whenCalledRepeatedly() {
        // Given
        let route = makeRoute(count: 1_000)
        let maxPoints = 37

        // When
        let firstResult = RouteDownsampler.downsample(route, maxPoints: maxPoints)
        let secondResult = RouteDownsampler.downsample(route, maxPoints: maxPoints)

        // Then
        #expect(firstResult == secondResult)
    }

    @Test("maxPoints가 1이면 첫 지점만 남긴다")
    func downsample_keepsFirstPointOnly_whenMaxPointsIsOne() {
        // Given
        let route = makeRoute(count: 100)
        let expectedMethod = SeriesSamplingMethod.uniform

        // When
        let result = RouteDownsampler.downsample(route, maxPoints: 1)

        // Then
        #expect(result.points == [route[0]])
        #expect(result.originalPointCount == 100)
        #expect(result.samplingMethod == expectedMethod)
    }
}

// MARK: - Helper

private extension RouteDownsamplerTests {
    /// 위도·경도·경과초가 순차 증가하는 경로를 만든다. 인덱스로 지점을 식별할 수 있다.
    func makeRoute(count: Int) -> [RoutePoint] {
        (0..<count).map { index in
            RoutePoint(
                latitude: 37.5 + Double(index) * 0.00001,
                longitude: 126.9 + Double(index) * 0.00001,
                altitude: Double(index),
                elapsedSec: TimeInterval(index)
            )
        }
    }
}
