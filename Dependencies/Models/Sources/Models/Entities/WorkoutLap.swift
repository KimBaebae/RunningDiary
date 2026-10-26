//
//  WorkoutLap.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation

/// Apple Watch 랩 버튼으로 구분된 구간 요약. HealthKit `HKWorkout.workoutActivities`에서 도출한다.
/// 거리 기준으로 균등 분할하는 `WorkoutSplit`과 달리 사용자가 직접 나눈 구간이라 길이가 불규칙하다.
public struct WorkoutLap: Equatable, Sendable, Codable, Identifiable {
    public let id: UUID                        // HKWorkoutActivity의 UUID
    public let index: Int                      // 1부터
    public let startOffsetSec: TimeInterval    // 워크아웃 시작 후 경과 초
    public let durationSec: TimeInterval       // 구간 운동시간 (일시정지 제외)
    public let distanceKm: Double              // 구간 거리 (km)
    public let paceSecondsPerKm: Int?          // 구간 페이스 (sec/km). 거리가 0이면 nil
    public let averageHeartRate: Int?          // bpm. 구간 내 샘플이 없으면 nil
    public let averagePower: Double?           // watts
    public let averageCadence: Int?            // spm

    public init(
        id: UUID = UUID(),
        index: Int,
        startOffsetSec: TimeInterval,
        durationSec: TimeInterval,
        distanceKm: Double,
        paceSecondsPerKm: Int?,
        averageHeartRate: Int?,
        averagePower: Double?,
        averageCadence: Int?
    ) {
        self.id = id
        self.index = index
        self.startOffsetSec = startOffsetSec
        self.durationSec = durationSec
        self.distanceKm = distanceKm
        self.paceSecondsPerKm = paceSecondsPerKm
        self.averageHeartRate = averageHeartRate
        self.averagePower = averagePower
        self.averageCadence = averageCadence
    }
}
