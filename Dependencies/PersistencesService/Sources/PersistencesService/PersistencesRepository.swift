//
//  PersistencesRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models

public protocol PersistencesRepository {
    func fetchRunningRecord(
        for date: Date,
        shoeResolver: @escaping @Sendable (String) -> Shoe?
    ) async throws -> Diary?
    func fetchRunningRecords(
        from startDate: Date,
        to endDate: Date,
        shoeResolver: @escaping @Sendable (String) -> Shoe?
    ) async throws -> [Diary]
    func saveRunningRecord(_ record: Diary) async throws
    func updateRunningRecord(
        recordId: UUID,
        date: YearMonthDay?,
        distance: Double?,
        duration: TimeInterval?,
        averagePace: String?,
        averageHeartRate: Int?,
        averageCadence: Int?,
        painAreas: [PainArea]?,
        runningStyle: RunninStyle?,
        memo: String?,
        shoes: String?,
        weather: WeatherData?,
        difficultyLevel: DifficultyLevel?,
        routeData: Data?,
        activeEnergyBurned: Double?,
        runningVerticalOscillation: Double?,
        runningGroundContactTime: Double?,
        walkingStepLength: Double?,
        restingHeartRate: Double?,
        runningPower: Double?,
        runningStrideLength: Double?,
        heartRateRecoveryOneMinute: Double?,
        startTime: Date?,
        endTime: Date?
    ) async throws
    func deleteRunningRecord(_ record: Diary) async throws
}

// MARK: - 신발 복원이 필요 없는 호출부용 기본 구현

public extension PersistencesRepository {
    func fetchRunningRecord(for date: Date) async throws -> Diary? {
        try await fetchRunningRecord(for: date) { _ in nil }
    }

    func fetchRunningRecords(from startDate: Date, to endDate: Date) async throws -> [Diary] {
        try await fetchRunningRecords(from: startDate, to: endDate) { _ in nil }
    }
}
