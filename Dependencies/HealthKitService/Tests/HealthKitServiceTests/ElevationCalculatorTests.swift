import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("ElevationCalculator.ascent")
struct ElevationCalculatorTests {

    @Test("고도 샘플이 없으면 nil을 반환한다")
    func ascent_isNil_whenAltitudesEmpty() {
        // When
        let result = ElevationCalculator.ascent(of: [])

        // Then
        #expect(result == nil)
    }

    @Test("고도 샘플이 하나면 상승분이 0이다")
    func ascent_isZero_whenSingleAltitude() {
        // Given
        let expected = 0.0

        // When
        let result = ElevationCalculator.ascent(of: [12.4])

        // Then
        #expect(result == expected)
    }

    @Test("단조 상승 구간은 전체 상승분을 합산한다")
    func ascent_sumsGain_whenMonotonicallyIncreasing() {
        // Given
        let expected = 6.0

        // When
        let result = ElevationCalculator.ascent(of: [10, 12, 14, 16])

        // Then
        #expect(result == expected)
    }

    @Test("하강분은 무시하고 양의 변화량만 합산한다")
    func ascent_ignoresDescent_andSumsOnlyPositiveDelta() {
        // Given
        // 10 → 20(+10) → 5(무시) → 15(+10)
        let expected = 20.0

        // When
        let result = ElevationCalculator.ascent(of: [10, 20, 5, 15])

        // Then
        #expect(result == expected)
    }

    @Test("단조 하강 구간은 상승분이 0이다")
    func ascent_isZero_whenMonotonicallyDecreasing() {
        // Given
        let expected = 0.0

        // When
        let result = ElevationCalculator.ascent(of: [30, 20, 10])

        // Then
        #expect(result == expected)
    }
}
