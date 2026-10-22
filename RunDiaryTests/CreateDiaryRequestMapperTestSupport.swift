//
//  CreateDiaryRequestMapperTestSupport.swift
//  RunDiaryTests
//
//  계약: docs/api/create-diary-request.md (v1.1 확정본)
//
//  CreateDiaryRequestMapperTests·CreateDiaryRequestFieldMappingTests가 공유하는 헬퍼.
//  Models 스킴에는 test action이 없어 ModelsTests가 실행되지 않으므로, 실제로 도는
//  RunDiaryTests 타겟에 둔다.

import Foundation
import Models

// MARK: - HealthKitWorkout / Diary 생성

func makeMapperWorkout(
    id: UUID = UUID(),
    startDate: Date = Date(timeIntervalSince1970: 1_783_837_800),
    endDate: Date = Date(timeIntervalSince1970: 1_783_840_350),
    timeZone: TimeZone? = TimeZone(identifier: "Asia/Seoul"),
    runningType: RunningType = .outdoor,
    distance: Double = 7.42,
    duration: TimeInterval = 2_550,
    elapsedTime: TimeInterval? = 2_570,
    averagePaceSecondsPerKm: Int? = 344,
    averageHeartRate: Int = 152,
    averageCadence: Int = 174,
    averagePower: Double = 310.0,
    averageVerticalOscillation: Double = 8.4,
    averageGroundContactTime: Double = 236.0,
    averageStepLength: Double = 1.0,
    averageStrideLength: Double = 1.35,
    activeEnergyBurned: Double = 512.3,
    totalEnergyBurned: Double? = 598.1,
    elevationAscended: Double? = 42.0,
    restingHeartRate: Double = 58.0,
    heartRateRecoveryOneMinute: Double = 32.0,
    route: [RoutePoint]? = nil,
    splits: [WorkoutSplit] = [],
    laps: [WorkoutLap] = [],
    series: WorkoutSeries? = nil,
    zoneSummaries: [WorkoutZoneSummary] = []
) -> HealthKitWorkout {
    HealthKitWorkout(
        id: id,
        runningType: runningType,
        distance: distance,
        duration: duration,
        elapsedTime: elapsedTime,
        averagePaceSecondsPerKm: averagePaceSecondsPerKm,
        averageHeartRate: averageHeartRate,
        averageCadence: averageCadence,
        activeEnergyBurned: activeEnergyBurned,
        totalEnergyBurned: totalEnergyBurned,
        elevationAscended: elevationAscended,
        averageVerticalOscillation: averageVerticalOscillation,
        averageGroundContactTime: averageGroundContactTime,
        averageStepLength: averageStepLength,
        restingHeartRate: restingHeartRate,
        averagePower: averagePower,
        averageStrideLength: averageStrideLength,
        heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
        route: route,
        startDate: startDate,
        endDate: endDate,
        timeZone: timeZone,
        splits: splits,
        laps: laps,
        series: series,
        zoneSummaries: zoneSummaries
    )
}

func makeMapperDiary(
    workout: HealthKitWorkout,
    weather: WeatherData? = nil,
    painAreas: [PainArea] = [],
    runningStyle: RunninStyle? = .midfoot,
    memo: String? = nil,
    shoe: Shoe? = nil,
    legacyShoe: String? = nil,
    difficultyLevel: DifficultyLevel? = nil
) -> Diary {
    Diary(
        workout: workout,
        painAreas: painAreas,
        runningStyle: runningStyle,
        memo: memo,
        shoe: shoe,
        legacyShoe: legacyShoe,
        weather: weather,
        difficultyLevel: difficultyLevel
    )
}

func makeMapperRoutePoints(count: Int) -> [RoutePoint] {
    (0..<count).map { index in
        RoutePoint(
            latitude: 37.5 + Double(index) * 0.0001,
            longitude: 126.9 + Double(index) * 0.0001,
            altitude: Double(index),
            elapsedSec: Double(index)
        )
    }
}

func makeMapperCatalogShoe(id: String) -> Shoe {
    Shoe(
        id: id,
        brandName: "Nike",
        name: "Pegasus",
        nameKo: "페가수스",
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
