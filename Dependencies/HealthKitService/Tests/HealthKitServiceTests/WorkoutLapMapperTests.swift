import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("WorkoutLapMapper.makeLaps")
struct WorkoutLapMapperTests {

    @Test("활동이 없으면 빈 배열을 반환한다")
    func makeLaps_isEmpty_whenNoActivities() {
        // When
        let result = WorkoutLapMapper.makeLaps(from: [])

        // Then
        #expect(result.isEmpty)
    }

    @Test("활동이 하나뿐이면 랩 버튼을 누르지 않은 것으로 보고 빈 배열을 반환한다")
    func makeLaps_isEmpty_whenSingleActivity() {
        // Given
        let activities = [makeActivity(startOffsetSec: 0, durationSec: 1800, distanceMeters: 5_000)]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.isEmpty)
    }

    @Test("index는 시작 시각 순으로 1부터 순차 증가한다")
    func makeLaps_assignsSequentialIndex_orderedByStartOffset() {
        // Given
        let expectedIndexes = [1, 2, 3]
        let activities = [
            makeActivity(startOffsetSec: 600, durationSec: 300, distanceMeters: 1_000),
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 1_000),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.map(\.index) == expectedIndexes)
        #expect(result.map(\.startOffsetSec) == [0, 300, 600])
    }

    @Test("거리와 시간으로 구간 페이스를 산출한다")
    func makeLaps_calculatesPace_fromDistanceAndDuration() {
        // Given
        let expectedPace = 300
        let activities = [
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 1_000),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.first?.paceSecondsPerKm == expectedPace)
    }

    @Test("거리가 0인 랩의 페이스는 nil이다")
    func makeLaps_paceIsNil_whenDistanceIsZero() {
        // Given
        let activities = [
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 0),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: nil),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.paceSecondsPerKm == nil })
        #expect(result.allSatisfy { $0.distanceKm == 0 })
    }

    @Test("케이던스는 걸음 수를 분 단위 시간으로 나눠 spm으로 환산한다")
    func makeLaps_convertsCadence_toStepsPerMinute() {
        // Given
        // 5분 동안 850걸음 → 170 spm
        let expectedCadence = 170
        let activities = [
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 1_000, stepCount: 850),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000, stepCount: 850),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.first?.averageCadence == expectedCadence)
    }

    @Test("걸음 수가 없으면 케이던스는 nil이다")
    func makeLaps_cadenceIsNil_whenStepCountMissing() {
        // Given
        let activities = [
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 1_000, stepCount: nil),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000, stepCount: nil),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.allSatisfy { $0.averageCadence == nil })
    }

    @Test("심박수는 반올림한 Int로, 파워는 소수 정밀도로 보존한다")
    func makeLaps_roundsHeartRate_andPreservesPowerPrecision() {
        // Given
        let expectedHeartRate = 152
        let expectedPower = 310.5
        let activities = [
            makeActivity(
                startOffsetSec: 0,
                durationSec: 300,
                distanceMeters: 1_000,
                averageHeartRate: 151.6,
                averagePower: expectedPower
            ),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.first?.averageHeartRate == expectedHeartRate)
        #expect(result.first?.averagePower == expectedPower)
    }

    @Test("거리는 미터에서 km로 환산된다")
    func makeLaps_convertsDistance_toKilometers() {
        // Given
        let expectedDistanceKm = 1.234
        let activities = [
            makeActivity(startOffsetSec: 0, durationSec: 300, distanceMeters: 1_234),
            makeActivity(startOffsetSec: 300, durationSec: 300, distanceMeters: 1_000),
        ]

        // When
        let result = WorkoutLapMapper.makeLaps(from: activities)

        // Then
        #expect(result.first?.distanceKm == expectedDistanceKm)
    }
}

// MARK: - Helpers

private extension WorkoutLapMapperTests {
    func makeActivity(
        id: UUID = UUID(),
        startOffsetSec: TimeInterval,
        durationSec: TimeInterval,
        distanceMeters: Double?,
        averageHeartRate: Double? = nil,
        averagePower: Double? = nil,
        stepCount: Double? = nil
    ) -> WorkoutActivitySample {
        WorkoutActivitySample(
            id: id,
            startOffsetSec: startOffsetSec,
            durationSec: durationSec,
            distanceMeters: distanceMeters,
            averageHeartRate: averageHeartRate,
            averagePower: averagePower,
            stepCount: stepCount
        )
    }
}
