import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("RunningTypeResolver.resolve")
struct RunningTypeResolverTests {

    @Test("실내 메타데이터가 true면 거리가 있어도 트레드밀이다")
    func resolve_isTreadmill_whenIndoorMetadataIsTrue() {
        // Given
        let expected = RunningType.treadmill

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: true, distanceKm: 5.0)

        // Then
        #expect(result == expected)
    }

    @Test("실내 메타데이터가 false면 거리가 0이어도 실외 달리기다")
    func resolve_isOutdoor_whenIndoorMetadataIsFalse() {
        // Given
        let expected = RunningType.outdoor

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: false, distanceKm: 0)

        // Then
        #expect(result == expected)
    }

    @Test("메타데이터가 없고 거리가 0이면 트레드밀로 추정한다")
    func resolve_isTreadmill_whenMetadataMissingAndDistanceIsZero() {
        // Given
        let expected = RunningType.treadmill

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: nil, distanceKm: 0)

        // Then
        #expect(result == expected)
    }

    @Test("메타데이터가 없고 거리가 있으면 실외 달리기로 추정한다")
    func resolve_isOutdoor_whenMetadataMissingAndDistanceExists() {
        // Given
        let expected = RunningType.outdoor

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: nil, distanceKm: 7.42)

        // Then
        #expect(result == expected)
    }
}
