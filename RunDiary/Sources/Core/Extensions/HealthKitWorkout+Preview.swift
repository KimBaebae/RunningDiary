//
//  HealthKitWorkout+Preview.swift
//  RunDiary
//

import Foundation
import Models

extension HealthKitWorkout {
    static var preview: HealthKitWorkout {
        HealthKitWorkout(
            distance: 5.32,
            duration: 1860,
            averagePaceSecondsPerKm: 350,
            averageHeartRate: 148,
            averageCadence: 172,
            activeEnergyBurned: 450.0,
            totalEnergyBurned: 528.0,
            elevationAscended: 42.0,
            averageVerticalOscillation: 8.2,
            averageGroundContactTime: 240.0,
            averageStepLength: 1.1,
            restingHeartRate: 58.0,
            averagePower: 245.0,
            averageStrideLength: 1.2,
            heartRateRecoveryOneMinute: 22.0,
            route: previewRoute,
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .second, value: 1860, to: .now)!,
            splits: previewSplits,
            laps: previewLaps,
            zoneSummaries: previewZoneSummaries
        )
    }

    /// 트레드밀 기록. 거리·경로가 없어 페이스를 산출할 수 없는 상태를 재현한다.
    static var previewTreadmill: HealthKitWorkout {
        HealthKitWorkout(
            runningType: .treadmill,
            distance: 0,
            duration: 1800,
            averagePaceSecondsPerKm: nil,
            averageHeartRate: 142,
            averageCadence: 168,
            activeEnergyBurned: 380.0,
            totalEnergyBurned: 445.0,
            averageVerticalOscillation: 7.8,
            averageGroundContactTime: 248.0,
            averageStepLength: 1.05,
            restingHeartRate: 60.0,
            averagePower: 230.0,
            averageStrideLength: 1.15,
            heartRateRecoveryOneMinute: 19.0,
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .second, value: 1800, to: .now)!
        )
    }

    private static var previewRoute: [RoutePoint] {
        [
            RoutePoint(latitude: 37.5665, longitude: 126.9780, altitude: 12.4, elapsedSec: 0),
            RoutePoint(latitude: 37.5668, longitude: 126.9783, altitude: 13.1, elapsedSec: 30),
            RoutePoint(latitude: 37.5672, longitude: 126.9789, altitude: 15.8, elapsedSec: 60),
        ]
    }

    private static var previewSplits: [WorkoutSplit] {
        [
            WorkoutSplit(
                index: 1,
                distanceKm: 1.0,
                durationSec: 345,
                paceSecondsPerKm: 345,
                averageHeartRate: 144,
                averageCadence: 170,
                averagePower: 240.0,
                elevationGainM: 8.2
            ),
            WorkoutSplit(
                index: 2,
                distanceKm: 1.0,
                durationSec: 352,
                paceSecondsPerKm: 352,
                averageHeartRate: 150,
                averageCadence: 173,
                averagePower: 248.0,
                elevationGainM: 12.4
            ),
        ]
    }

    private static var previewLaps: [WorkoutLap] {
        [
            WorkoutLap(
                index: 1,
                startOffsetSec: 0,
                durationSec: 600,
                distanceKm: 1.72,
                paceSecondsPerKm: 349,
                averageHeartRate: 145,
                averagePower: 242.0,
                averageCadence: 171
            ),
            WorkoutLap(
                index: 2,
                startOffsetSec: 600,
                durationSec: 1260,
                distanceKm: 3.60,
                paceSecondsPerKm: 350,
                averageHeartRate: 151,
                averagePower: 247.0,
                averageCadence: 173
            ),
        ]
    }

    private static var previewZoneSummaries: [WorkoutZoneSummary] {
        [
            WorkoutZoneSummary(
                metric: .heartRate,
                source: .system,
                durations: [
                    WorkoutZoneDuration(index: 1, minimum: nil, maximum: 120, durationSec: 180),
                    WorkoutZoneDuration(index: 2, minimum: 120, maximum: 140, durationSec: 420),
                    WorkoutZoneDuration(index: 3, minimum: 140, maximum: 160, durationSec: 960),
                    WorkoutZoneDuration(index: 4, minimum: 160, maximum: 175, durationSec: 240),
                    WorkoutZoneDuration(index: 5, minimum: 175, maximum: nil, durationSec: 60),
                ]
            ),
        ]
    }
}
