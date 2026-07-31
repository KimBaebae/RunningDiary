//
//  HealthKitManager+LapExtraction.swift
//  HealthKitService
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation
import HealthKit
import Models

extension HealthKitManager {
    /// `HKWorkout.workoutActivities`(iOS 16+)에서 랩을 도출한다.
    ///
    /// 활동은 워크아웃 객체가 이미 보유하고 통계도 함께 들고 있어 추가 쿼리가 발생하지 않는다.
    /// 랩 버튼을 누르지 않은 워크아웃은 활동이 1개뿐이며, 이 경우 `WorkoutLapMapper`가 빈 배열을 반환한다.
    func makeLaps(from workout: HKWorkout) -> [WorkoutLap] {
        let activities = workout.workoutActivities.map { activity in
            WorkoutActivitySample(
                id: activity.uuid,
                startOffsetSec: activity.startDate.timeIntervalSince(workout.startDate),
                durationSec: activity.duration,
                distanceMeters: activity.statistics(for: HKQuantityTypeCatalog.distanceWalkingRunning)?
                    .sumQuantity()?
                    .doubleValue(for: HKUnitCatalog.meter),
                averageHeartRate: activity.statistics(for: HKQuantityTypeCatalog.heartRate)?
                    .averageQuantity()?
                    .doubleValue(for: HKUnitCatalog.bpm),
                averagePower: activity.statistics(for: HKQuantityTypeCatalog.runningPower)?
                    .averageQuantity()?
                    .doubleValue(for: HKUnitCatalog.watt),
                stepCount: activity.statistics(for: HKQuantityTypeCatalog.stepCount)?
                    .sumQuantity()?
                    .doubleValue(for: .count())
            )
        }

        return WorkoutLapMapper.makeLaps(from: activities)
    }
}
