//
//  DiaryPatch.swift
//  RunDiary
//
//  Created by 김혜지 on 8/2/26.
//

import Foundation
import Models

/// 일지 부분 업데이트 요청.
///
/// nil인 필드는 "변경 없음"으로 취급한다.
public struct DiaryPatch: Sendable, Equatable {
    public var date: YearMonthDay?
    public var distance: Double?
    public var duration: TimeInterval?
    public var averagePace: String?
    public var averageHeartRate: Int?
    public var averageCadence: Int?
    public var painAreas: [PainArea]?
    public var runningStyle: RunninStyle?
    public var memo: String?
    public var shoes: String?
    public var weather: WeatherData?
    public var difficultyLevel: DifficultyLevel?
    public var routeData: Data?
    public var activeEnergyBurned: Double?
    public var runningVerticalOscillation: Double?
    public var runningGroundContactTime: Double?
    public var walkingStepLength: Double?
    public var restingHeartRate: Double?
    public var runningPower: Double?
    public var runningStrideLength: Double?
    public var heartRateRecoveryOneMinute: Double?
    public var startTime: Date?
    public var endTime: Date?

    public init(
        date: YearMonthDay? = nil,
        distance: Double? = nil,
        duration: TimeInterval? = nil,
        averagePace: String? = nil,
        averageHeartRate: Int? = nil,
        averageCadence: Int? = nil,
        painAreas: [PainArea]? = nil,
        runningStyle: RunninStyle? = nil,
        memo: String? = nil,
        shoes: String? = nil,
        weather: WeatherData? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        routeData: Data? = nil,
        activeEnergyBurned: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        walkingStepLength: Double? = nil,
        restingHeartRate: Double? = nil,
        runningPower: Double? = nil,
        runningStrideLength: Double? = nil,
        heartRateRecoveryOneMinute: Double? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) {
        self.date = date
        self.distance = distance
        self.duration = duration
        self.averagePace = averagePace
        self.averageHeartRate = averageHeartRate
        self.averageCadence = averageCadence
        self.painAreas = painAreas
        self.runningStyle = runningStyle
        self.memo = memo
        self.shoes = shoes
        self.weather = weather
        self.difficultyLevel = difficultyLevel
        self.routeData = routeData
        self.activeEnergyBurned = activeEnergyBurned
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.walkingStepLength = walkingStepLength
        self.restingHeartRate = restingHeartRate
        self.runningPower = runningPower
        self.runningStrideLength = runningStrideLength
        self.heartRateRecoveryOneMinute = heartRateRecoveryOneMinute
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Diary 전체 반영용 Patch

public extension DiaryPatch {
    /// 일지 전체를 그대로 반영하는 patch를 만든다.
    ///
    /// 신발 해제를 반영해야 하므로 `shoes`는 nil 대신 빈 문자열을 채운다.
    /// (nil은 "변경 없음"이라 해제가 무시된다.)
    static func fullUpdate(from record: Diary) -> DiaryPatch {
        DiaryPatch(
            date: record.workout.yearMonthDay,
            distance: record.workout.distance,
            duration: record.workout.duration,
            averagePace: record.workout.formattedAveragePace,
            averageHeartRate: record.workout.averageHeartRate,
            averageCadence: record.workout.averageCadence,
            painAreas: record.painAreas,
            runningStyle: record.runningStyle,
            memo: record.memo,
            shoes: record.shoe?.id ?? record.legacyShoe ?? "",
            weather: record.weather,
            difficultyLevel: record.difficultyLevel,
            routeData: RouteDataMapper.encode(record.workout.route),
            activeEnergyBurned: record.workout.activeEnergyBurned,
            runningVerticalOscillation: record.workout.averageVerticalOscillation,
            runningGroundContactTime: record.workout.averageGroundContactTime,
            walkingStepLength: record.workout.averageStepLength,
            restingHeartRate: record.workout.restingHeartRate,
            runningPower: record.workout.averagePower,
            runningStrideLength: record.workout.averageStrideLength,
            heartRateRecoveryOneMinute: record.workout.heartRateRecoveryOneMinute,
            startTime: record.workout.startTime,
            endTime: record.workout.endTime
        )
    }
}
