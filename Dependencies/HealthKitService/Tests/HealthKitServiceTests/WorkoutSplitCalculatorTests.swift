import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("WorkoutSplitCalculator.makeSplits")
struct WorkoutSplitCalculatorTests {

    // MARK: - 빈 입력

    @Test("route가 비어있으면 빈 배열을 반환한다")
    func makeSplits_returnsEmpty_whenRouteEmpty() {
        // Given
        let expectedSplits: [WorkoutSplit] = []

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: [], heartRate: [], cadence: [])

        // Then
        #expect(result == expectedSplits)
    }

    // MARK: - 정확한 N km 경계

    @Test("총 거리가 정확히 N km면 스플릿 N개가 각각 1.0km로 산출된다")
    func makeSplits_producesExactSplits_whenTotalDistanceIsExactMultiple() {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
            (offset: 600, cumulativeMeters: 2_000, altitude: nil),
            (offset: 900, cumulativeMeters: 3_000, altitude: nil),
        ]
        let expectedSplitCount = 3
        let expectedDistanceKm = 1.0
        let expectedPaceSecondsPerKm = 300

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        #expect(result.count == expectedSplitCount)
        for split in result {
            #expect(split.distanceKm == expectedDistanceKm)
            #expect(split.paceSecondsPerKm == expectedPaceSecondsPerKm)
        }
        #expect(result.map(\.index) == [1, 2, 3])
    }

    // MARK: - 마지막 부분 구간

    @Test("마지막 구간이 1km 미만이면 실제 거리로 포함된다")
    func makeSplits_includesPartialLastSplit_whenRemainderUnderOneKm() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
            (offset: 600, cumulativeMeters: 2_000, altitude: nil),
            (offset: 750, cumulativeMeters: 2_500, altitude: nil),
        ]
        let expectedSplitCount = 3
        let expectedLastDistanceKm = 0.5
        let expectedLastDurationSec = 150.0
        let expectedLastPaceSecondsPerKm = 300

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        #expect(result.count == expectedSplitCount)
        let lastSplit = try #require(result.last)
        #expect(lastSplit.distanceKm == expectedLastDistanceKm)
        #expect(lastSplit.durationSec == expectedLastDurationSec)
        #expect(lastSplit.paceSecondsPerKm == expectedLastPaceSecondsPerKm)
    }

    // MARK: - 구간별 HR/cadence 없음 → nil

    @Test("HR/cadence 샘플이 없는 구간은 각각 nil로 산출된다")
    func makeSplits_returnsNilAverages_whenSegmentHasNoSamples() {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
            (offset: 600, cumulativeMeters: 2_000, altitude: nil),
            (offset: 900, cumulativeMeters: 3_000, altitude: nil),
        ]
        let heartRate: [(offset: TimeInterval, value: Double)] = [(offset: 150, value: 150)]
        let cadence: [(offset: TimeInterval, value: Double)] = [(offset: 750, value: 170)]
        let expectedHeartRates: [Int?] = [150, nil, nil]
        let expectedCadences: [Int?] = [nil, nil, 170]

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: heartRate, cadence: cadence)

        // Then
        #expect(result.map(\.averageHeartRate) == expectedHeartRates)
        #expect(result.map(\.averageCadence) == expectedCadences)
    }

    // MARK: - 고도 상승

    @Test("고도 변화가 있으면 elevationGainM은 양의 변화 합과 일치한다")
    func makeSplits_calculatesElevationGain_asSumOfPositiveDeltas() {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: 100.0),
            (offset: 300, cumulativeMeters: 1_000, altitude: 110.0),
            (offset: 600, cumulativeMeters: 2_000, altitude: 105.0),
            (offset: 900, cumulativeMeters: 3_000, altitude: 120.0),
        ]
        let expectedGains: [Double?] = [10.0, 0.0, 15.0]

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        #expect(result.map(\.elevationGainM) == expectedGains)
    }

    @Test("구간에 고도 샘플이 하나도 없으면 elevationGainM은 nil이다")
    func makeSplits_returnsNilElevationGain_whenNoAltitudeSamples() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
        ]

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        let split = try #require(result.first)
        #expect(split.elevationGainM == nil)
    }

    @Test("구간에 고도 샘플이 1개뿐이면 elevationGainM은 nil이 아닌 0.0이다")
    func makeSplits_returnsZeroElevationGain_whenOnlyOneAltitudeSample() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: 50.0),
            (offset: 150, cumulativeMeters: 500, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
        ]
        let expectedElevationGain = 0.0

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        let split = try #require(result.first)
        #expect(split.elevationGainM == expectedElevationGain)
    }

    // MARK: - 구간 평균 파워

    @Test("구간에 속한 파워 샘플의 평균이 소수 정밀도로 산출된다")
    func makeSplits_averagesPower_preservingFraction() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
        ]
        let power: [(offset: TimeInterval, value: Double)] = [
            (offset: 0, value: 300.0),
            (offset: 150, value: 310.5),
            (offset: 300, value: 320.0),
        ]
        let expectedAveragePower = 310.1666666666667
        let tolerance = 0.0001

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [], power: power)

        // Then
        let split = try #require(result.first)
        let averagePower = try #require(split.averagePower)
        #expect(abs(averagePower - expectedAveragePower) < tolerance)
    }

    @Test("파워 샘플을 넘기지 않으면 averagePower는 nil이다")
    func makeSplits_averagePowerIsNil_whenPowerSamplesOmitted() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
        ]

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [])

        // Then
        let split = try #require(result.first)
        #expect(split.averagePower == nil)
    }

    @Test("구간 범위 밖의 파워 샘플은 평균에 포함되지 않는다")
    func makeSplits_excludesPowerSamplesOutsideSplitRange() throws {
        // Given
        let route: [(offset: TimeInterval, cumulativeMeters: Double, altitude: Double?)] = [
            (offset: 0, cumulativeMeters: 0, altitude: nil),
            (offset: 300, cumulativeMeters: 1_000, altitude: nil),
            (offset: 600, cumulativeMeters: 2_000, altitude: nil),
        ]
        let power: [(offset: TimeInterval, value: Double)] = [
            (offset: 0, value: 300.0),
            (offset: 450, value: 400.0),
        ]
        let expectedFirstSplitPower = 300.0
        let expectedSecondSplitPower = 400.0

        // When
        let result = WorkoutSplitCalculator.makeSplits(route: route, heartRate: [], cadence: [], power: power)

        // Then
        #expect(result.count == 2)
        #expect(result.first?.averagePower == expectedFirstSplitPower)
        #expect(result.last?.averagePower == expectedSecondSplitPower)
    }
}
