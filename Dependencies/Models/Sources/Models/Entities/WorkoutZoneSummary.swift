//
//  WorkoutZoneSummary.swift
//  Models
//
//  Created by 김혜지 on 7/30/26.
//

import Foundation

/// 존을 구분하는 지표. HealthKit은 심박수와 사이클링 파워에 대해 존을 제공한다.
public enum WorkoutZoneMetric: String, Sendable, Codable, CaseIterable {
    case heartRate
    case power
}

/// 존 경계의 출처. 시스템 자동 생성 / 사용자가 건강 설정에서 직접 지정 / 앱이 커스텀 지정.
public enum WorkoutZoneSource: String, Sendable, Codable, CaseIterable {
    case system
    case user
    case app
}

/// 단일 존의 경계와 체류 시간.
/// 존은 항상 연속적이고 겹치지 않으며, 첫 존은 하한이 없고 마지막 존은 상한이 없다.
public struct WorkoutZoneDuration: Equatable, Sendable, Codable {
    public let index: Int                  // 존 인덱스
    public let minimum: Double?            // 하한. 첫 존은 nil
    public let maximum: Double?            // 상한. 마지막 존은 nil
    public let durationSec: TimeInterval   // 해당 존 체류 시간

    public init(
        index: Int,
        minimum: Double?,
        maximum: Double?,
        durationSec: TimeInterval
    ) {
        self.index = index
        self.minimum = minimum
        self.maximum = maximum
        self.durationSec = durationSec
    }
}

/// 한 지표에 대한 존 구성과 존별 체류 시간 묶음.
///
/// HealthKit이 존별 체류 시간을 이미 집계해 제공하므로(iOS 27+) 앱이 심박 샘플을 직접 버킷팅하지 않는다.
/// iOS 27 미만이거나 사용자가 존을 구성하지 않았으면 워크아웃의 `zoneSummaries`가 빈 배열이 된다.
public struct WorkoutZoneSummary: Equatable, Sendable, Codable {
    public let metric: WorkoutZoneMetric
    public let source: WorkoutZoneSource?      // 출처를 알 수 없으면 nil
    public let durations: [WorkoutZoneDuration]

    public init(
        metric: WorkoutZoneMetric,
        source: WorkoutZoneSource?,
        durations: [WorkoutZoneDuration]
    ) {
        self.metric = metric
        self.source = source
        self.durations = durations
    }
}
