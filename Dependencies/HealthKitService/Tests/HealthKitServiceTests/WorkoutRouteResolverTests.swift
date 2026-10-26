//
//  WorkoutRouteResolverTests.swift
//  HealthKitServiceTests
//
//  Created by 김혜지 on 8/4/26.
//

import Models
import Testing

@testable import HealthKitService

@Suite("WorkoutRouteResolver.resolve")
struct WorkoutRouteResolverTests {

    @Test("실외 달리기에 지점이 있으면 원본 경로를 그대로 사용한다")
    func resolve_returnsPoints_whenOutdoorWithPoints() {
        // Given
        let expectedPoints = makePoints(count: 3)

        // When
        let result = WorkoutRouteResolver.resolve(runningType: .outdoor, points: expectedPoints)

        // Then
        #expect(result == expectedPoints)
    }

    @Test("실외 달리기라도 지점이 없으면 빈 배열이 아니라 nil이다")
    func resolve_returnsNil_whenOutdoorWithoutPoints() {
        // When
        let result = WorkoutRouteResolver.resolve(runningType: .outdoor, points: [])

        // Then
        #expect(result == nil)
    }

    @Test("트레드밀은 지점이 없으면 nil이다")
    func resolve_returnsNil_whenTreadmillWithoutPoints() {
        // When
        let result = WorkoutRouteResolver.resolve(runningType: .treadmill, points: [])

        // Then
        #expect(result == nil)
    }

    @Test("트레드밀은 HealthKit이 좌표를 남겼더라도 경로를 버리고 nil로 정규화한다")
    func resolve_discardsPoints_whenTreadmillWithPoints() {
        // Given
        let points = makePoints(count: 3)

        // When
        let result = WorkoutRouteResolver.resolve(runningType: .treadmill, points: points)

        // Then
        #expect(result == nil)
    }
}

// MARK: - Helper

private extension WorkoutRouteResolverTests {
    func makePoints(count: Int) -> [RoutePoint] {
        (0..<count).map { index in
            RoutePoint(
                latitude: 37.5 + Double(index) * 0.0001,
                longitude: 126.9 + Double(index) * 0.0001,
                altitude: Double(index),
                elapsedSec: Double(index)
            )
        }
    }
}
