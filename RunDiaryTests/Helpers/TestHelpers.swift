//
//  TestHelpers.swift
//  RunDiaryTests
//
//  Created by Claude on 1/19/26.
//

import CommonFoundation
import Foundation
import Models

@testable import RunDiary

// MARK: - Date Helpers

/// 오늘 날짜의 YearMonthDay 반환
func makeTodayYearMonthDay() -> YearMonthDay {
    YearMonthDay(date: Date())
}

/// YearMonthDay 생성 헬퍼
/// - Parameters:
///   - year: 연도 (기본값: 현재 연도)
///   - month: 월 (기본값: 1)
///   - day: 일 (기본값: 1)
/// - Returns: 지정된 날짜의 YearMonthDay
func makeYearMonthDay(
    year: Int? = nil,
    month: Int = 1,
    day: Int = 1
) -> YearMonthDay {
    let calendar = Calendar.current
    let currentYear = year ?? calendar.component(.year, from: Date())
    return YearMonthDay(year: currentYear, month: month, day: day)
}

/// 주 날짜 배열 생성 헬퍼
func makeWeekDates(containing date: YearMonthDay) -> [YearMonthDay] {
    DateHelper.getWeekDates(for: date.toDate()).map { YearMonthDay(date: $0) }
}

// MARK: - Model Helpers

/// HealthKitWorkout 생성 헬퍼
func makeHealthKitWorkout(
    yearMonthDay: YearMonthDay,
    runningType: RunningType = .outdoor,
    distance: Double = 5.0,
    duration: TimeInterval = 1800,
    averagePaceSecondsPerKm: Int? = 360,
    averageHeartRate: Int = 150,
    averageCadence: Int = 170,
    route: [RoutePoint] = [],
    splits: [WorkoutSplit] = [],
    laps: [WorkoutLap] = [],
    series: WorkoutSeries? = nil,
    zoneSummaries: [WorkoutZoneSummary] = [],
    samples: WorkoutSampleSet = .empty,
    startOffset: TimeInterval = 0
) -> HealthKitWorkout {
    let startDate = yearMonthDay.toDate().addingTimeInterval(startOffset)
    return HealthKitWorkout(
        runningType: runningType,
        distance: distance,
        duration: duration,
        averagePaceSecondsPerKm: averagePaceSecondsPerKm,
        averageHeartRate: averageHeartRate,
        averageCadence: averageCadence,
        activeEnergyBurned: 350.0,
        totalEnergyBurned: 420.0,
        elevationAscended: 30.0,
        averageVerticalOscillation: 8.0,
        averageGroundContactTime: 240.0,
        averageStepLength: 1.0,
        restingHeartRate: 60.0,
        averagePower: 300.0,
        averageStrideLength: 1.0,
        heartRateRecoveryOneMinute: 20.0,
        route: route,
        startDate: startDate,
        endDate: startDate.addingTimeInterval(duration),
        splits: splits,
        laps: laps,
        series: series,
        zoneSummaries: zoneSummaries,
        samples: samples
    )
}

/// Diary 생성 헬퍼
func makeDiary(
    yearMonthDay: YearMonthDay,
    distance: Double = 5.0,
    duration: TimeInterval = 1800,
    averagePaceSecondsPerKm: Int? = 360,
    averageHeartRate: Int = 150,
    averageCadence: Int = 170,
    startOffset: TimeInterval = 0
) -> Diary {
    let workout = makeHealthKitWorkout(
        yearMonthDay: yearMonthDay,
        distance: distance,
        duration: duration,
        averagePaceSecondsPerKm: averagePaceSecondsPerKm,
        averageHeartRate: averageHeartRate,
        averageCadence: averageCadence,
        startOffset: startOffset
    )
    return Diary(
        workout: workout,
        runningStyle: .midfoot
    )
}

/// metrics가 모두 0인 Diary 생성 헬퍼 (마이그레이션 테스트용)
func makeDiaryWithZeroMetrics(
    yearMonthDay: YearMonthDay,
    startTime: Date? = nil
) -> Diary {
    let start = startTime ?? yearMonthDay.toDate()
    let workout = HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePaceSecondsPerKm: 360,
        averageHeartRate: 150,
        averageCadence: 170,
        activeEnergyBurned: 0,
        averageVerticalOscillation: 0,
        averageGroundContactTime: 0,
        averageStepLength: 0,
        restingHeartRate: 0,
        averagePower: 0,
        averageStrideLength: 0,
        heartRateRecoveryOneMinute: 0,
        startDate: start,
        endDate: start.addingTimeInterval(1800)
    )
    return Diary(workout: workout, runningStyle: .midfoot)
}

/// RoutePoint 생성 헬퍼
func makeRoutePoint(
    latitude: Double = 37.5665,
    longitude: Double = 126.9780,
    altitude: Double? = 12.4,
    elapsedSec: TimeInterval? = 0
) -> RoutePoint {
    RoutePoint(latitude: latitude, longitude: longitude, altitude: altitude, elapsedSec: elapsedSec)
}

/// WorkoutLap 생성 헬퍼
func makeWorkoutLap(
    index: Int = 1,
    startOffsetSec: TimeInterval = 0,
    durationSec: TimeInterval = 300,
    distanceKm: Double = 1.0,
    paceSecondsPerKm: Int? = 300,
    averageHeartRate: Int? = 150,
    averagePower: Double? = 280.0,
    averageCadence: Int? = 170
) -> WorkoutLap {
    WorkoutLap(
        index: index,
        startOffsetSec: startOffsetSec,
        durationSec: durationSec,
        distanceKm: distanceKm,
        paceSecondsPerKm: paceSecondsPerKm,
        averageHeartRate: averageHeartRate,
        averagePower: averagePower,
        averageCadence: averageCadence
    )
}

/// WorkoutZoneSummary 생성 헬퍼
func makeWorkoutZoneSummary(
    metric: WorkoutZoneMetric = .heartRate,
    source: WorkoutZoneSource? = .system,
    durations: [WorkoutZoneDuration] = [
        WorkoutZoneDuration(index: 1, minimum: nil, maximum: 120, durationSec: 300),
        WorkoutZoneDuration(index: 2, minimum: 120, maximum: 150, durationSec: 900),
        WorkoutZoneDuration(index: 3, minimum: 150, maximum: nil, durationSec: 600),
    ]
) -> WorkoutZoneSummary {
    WorkoutZoneSummary(metric: metric, source: source, durations: durations)
}

/// Shoe 생성 헬퍼
func makeShoe(
    id: String,
    brand: String,
    name: String? = nil
) -> Shoe {
    Shoe(
        id: id,
        brandName: brand,
        name: name ?? id,
        nameKo: name ?? id,
        category: [:],
        subcategory: [:],
        tags: [],
        imageUrl: nil,
        reviewSummary: nil,
        pros: [],
        cons: [],
        description: nil
    )
}
