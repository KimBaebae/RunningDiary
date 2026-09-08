import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("RunningTypeResolver.resolve")
struct RunningTypeResolverTests {

    @Test("실내 메타데이터가 true면 거리가 있어도 트레드밀이고 근거는 healthKit이다")
    func resolve_isTreadmill_whenIndoorMetadataIsTrue() {
        // Given
        let expectedType = RunningType.treadmill
        let expectedSource = RunningTypeSource.healthKit

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: true, distanceKm: 5.0)

        // Then
        #expect(result.type == expectedType)
        #expect(result.source == expectedSource)
    }

    @Test("실내 메타데이터가 false면 거리가 0이어도 실외 달리기고 근거는 healthKit이다")
    func resolve_isOutdoor_whenIndoorMetadataIsFalse() {
        // Given
        let expectedType = RunningType.outdoor
        let expectedSource = RunningTypeSource.healthKit

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: false, distanceKm: 0)

        // Then
        #expect(result.type == expectedType)
        #expect(result.source == expectedSource)
    }

    @Test("메타데이터가 없고 거리가 0이면 트레드밀로 추정하고 근거는 distanceInference다")
    func resolve_isTreadmill_whenMetadataMissingAndDistanceIsZero() {
        // Given
        let expectedType = RunningType.treadmill
        let expectedSource = RunningTypeSource.distanceInference

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: nil, distanceKm: 0)

        // Then
        #expect(result.type == expectedType)
        #expect(result.source == expectedSource)
    }

    @Test("메타데이터가 없고 거리가 있으면 실외 달리기로 추정하고 근거는 distanceInference다")
    func resolve_isOutdoor_whenMetadataMissingAndDistanceExists() {
        // Given
        let expectedType = RunningType.outdoor
        let expectedSource = RunningTypeSource.distanceInference

        // When
        let result = RunningTypeResolver.resolve(isIndoorWorkout: nil, distanceKm: 7.42)

        // Then
        #expect(result.type == expectedType)
        #expect(result.source == expectedSource)
    }
}
