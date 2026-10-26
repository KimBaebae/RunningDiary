import Foundation
@testable import Models
import Testing

@Suite("PaceMapper")
struct PaceMapperTests {

    @Test("344초/km는 5'44\"로 포맷된다")
    func string_formatsSecondsPerKm() {
        // Given
        let expected = "5'44\""

        // When
        let result = PaceMapper.string(fromSecondsPerKm: 344)

        // Then
        #expect(result == expected)
    }

    @Test("초가 10 미만이면 0으로 패딩한다")
    func string_padsSecondsWithZero() {
        // Given
        let expected = "6'05\""

        // When
        let result = PaceMapper.string(fromSecondsPerKm: 365)

        // Then
        #expect(result == expected)
    }

    @Test("페이스가 0 이하면 빈 문자열을 반환한다")
    func string_isEmpty_whenNotPositive() {
        #expect(PaceMapper.string(fromSecondsPerKm: 0).isEmpty)
        #expect(PaceMapper.string(fromSecondsPerKm: -1).isEmpty)
    }

    @Test("운동시간과 거리로 평균 페이스를 산출한다")
    func secondsPerKm_calculatesFromDurationAndDistance() {
        // Given
        let expected = 344

        // When
        let result = PaceMapper.secondsPerKm(fromDurationSec: 2550, distanceKm: 7.42)

        // Then
        #expect(result == expected)
    }

    @Test("거리가 0이면 nil을 반환한다")
    func secondsPerKm_isNil_whenDistanceIsZero() {
        // When
        let result = PaceMapper.secondsPerKm(fromDurationSec: 1800, distanceKm: 0)

        // Then
        #expect(result == nil)
    }

    @Test("운동시간이 0이면 nil을 반환한다")
    func secondsPerKm_isNil_whenDurationIsZero() {
        // When
        let result = PaceMapper.secondsPerKm(fromDurationSec: 0, distanceKm: 5)

        // Then
        #expect(result == nil)
    }
}
