//
//  WorkoutLapMapper.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation
import Models

/// HealthKit `HKWorkoutActivity`에서 추출한 원시 값. HealthKit 타입 의존을 이 경계에서 끊는다.
public struct WorkoutActivitySample: Equatable, Sendable {
    public let id: UUID
    public let startOffsetSec: TimeInterval    // 워크아웃 시작 후 경과 초
    public let durationSec: TimeInterval       // 활동 운동시간 (일시정지 제외)
    public let distanceMeters: Double?
    public let averageHeartRate: Double?       // bpm
    public let averagePower: Double?           // watts
    public let stepCount: Double?              // 활동 구간 총 걸음 수

    public init(
        id: UUID,
        startOffsetSec: TimeInterval,
        durationSec: TimeInterval,
        distanceMeters: Double?,
        averageHeartRate: Double?,
        averagePower: Double?,
        stepCount: Double?
    ) {
        self.id = id
        self.startOffsetSec = startOffsetSec
        self.durationSec = durationSec
        self.distanceMeters = distanceMeters
        self.averageHeartRate = averageHeartRate
        self.averagePower = averagePower
        self.stepCount = stepCount
    }
}

/// 활동 샘플을 랩(`WorkoutLap`)으로 변환하는 순수 계산 타입.
public enum WorkoutLapMapper {
    /// 활동 샘플을 시작 시각 순으로 정렬해 랩으로 변환한다.
    ///
    /// 활동이 1개뿐이면 사용자가 랩 버튼을 누르지 않은 워크아웃이므로 빈 배열을 반환한다.
    /// (단일 활동을 랩 1개로 노출하면 워크아웃 전체와 동일한 값이 중복 표시된다)
    public static func makeLaps(from activities: [WorkoutActivitySample]) -> [WorkoutLap] {
        guard activities.count > 1 else { return [] }

        let sorted = activities.sorted { $0.startOffsetSec < $1.startOffsetSec }

        return sorted.enumerated().map { index, activity in
            let distanceKm = (activity.distanceMeters ?? 0) / 1000

            return WorkoutLap(
                id: activity.id,
                index: index + 1,
                startOffsetSec: activity.startOffsetSec,
                durationSec: activity.durationSec,
                distanceKm: distanceKm,
                paceSecondsPerKm: PaceMapper.secondsPerKm(
                    fromDurationSec: activity.durationSec,
                    distanceKm: distanceKm
                ),
                averageHeartRate: activity.averageHeartRate.map { Int($0.rounded()) },
                averagePower: activity.averagePower,
                averageCadence: cadence(stepCount: activity.stepCount, durationSec: activity.durationSec)
            )
        }
    }

    /// 활동 구간의 총 걸음 수를 분당 걸음(spm)으로 환산한다. 걸음 수나 시간이 없으면 nil.
    private static func cadence(stepCount: Double?, durationSec: TimeInterval) -> Int? {
        guard let stepCount, durationSec > 0 else { return nil }

        let durationMinutes = durationSec / 60
        return Int((stepCount / durationMinutes).rounded())
    }
}
