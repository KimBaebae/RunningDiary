//
//  LivePersistencesRepository.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Models
import SwiftData

@MainActor
public final class LivePersistencesRepository: PersistencesRepository {
    // ModelContext : 데이터 변경을 추적하고 저장/조회/삭제를 실행하는 중심 객체
    private let modelContext: ModelContext
    private let cache = NSCache<YearMonthDayCacheKey, DiaryArrayCacheValue>()

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func fetchRunningRecord(
        for date: Date,
        shoeResolver: @escaping @Sendable (String) -> Shoe?
    ) async throws -> Diary? {
        let yearMonthDay = YearMonthDay(date: date)
        let cacheKey = YearMonthDayCacheKey(yearMonthDay)

        // 1. 캐시 확인
        if let cachedValue = cache.object(forKey: cacheKey) {
            return cachedValue.diaries.first
        }

        // 2. 캐시 미스: DB 조회
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let predicate = #Predicate<RunningRecordPersistenceModel> { record in
            record.date >= startOfDay && record.date < endOfDay
        }

        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        let models = try modelContext.fetch(descriptor)
        let records = models.map { $0.toDomain(shoeResolver: shoeResolver) }

        // 3. 캐시에 저장
        cache.setObject(DiaryArrayCacheValue(records), forKey: cacheKey)

        return records.first
    }

    public func fetchRunningRecords(
        from startDate: Date,
        to endDate: Date,
        shoeResolver: @escaping @Sendable (String) -> Shoe?
    ) async throws -> [Diary] {
        // 1. 요청 범위의 날짜들 추출
        let requestedDates = generateDateRange(from: startDate, to: endDate)

        // 2. 캐시 히트 확인
        let missingDates = requestedDates.filter { cache.object(forKey: YearMonthDayCacheKey($0)) == nil }

        // 3. 캐시 미스인 날짜만 DB 조회
        if !missingDates.isEmpty {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let end = calendar.startOfDay(for: endDate)

            let predicate = #Predicate<RunningRecordPersistenceModel> { record in
                record.date >= start && record.date <= end
            }

            let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let models = try modelContext.fetch(descriptor)
            let fetchedRecords = models.map { $0.toDomain(shoeResolver: shoeResolver) }

            // 4. 날짜별로 그룹핑하여 캐시에 저장
            let groupedRecords = Dictionary(grouping: fetchedRecords, by: \.workout.yearMonthDay)
            for date in missingDates {
                let cacheKey = YearMonthDayCacheKey(date)
                let cacheValue = DiaryArrayCacheValue(groupedRecords[date] ?? [])
                cache.setObject(cacheValue, forKey: cacheKey)
            }
        }

        // 5. 캐시에서 결과 추출
        let result = requestedDates.flatMap { cache.object(forKey: YearMonthDayCacheKey($0))?.diaries ?? [] }

        return result
    }

    public func saveRunningRecord(_ record: Diary) async throws {
        let model = RunningRecordPersistenceModel.fromDomain(record)
        modelContext.insert(model)

        do {
            try modelContext.save()
            // 캐시 invalidate
            cache.removeObject(forKey: YearMonthDayCacheKey(record.workout.yearMonthDay))
        } catch {
            throw PersistencesError.saveFailed
        }
    }

    public func updateRunningRecord(recordId: UUID, patch: DiaryPatch) async throws {
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(predicate: predicate)

        guard let existingModel = try modelContext.fetch(descriptor).first else {
            throw PersistencesError.notFound
        }

        // nil이 아닌 값만 할당
        Self.applyWorkoutSummary(patch, to: existingModel)
        Self.applyDiaryDetails(patch, to: existingModel)
        Self.applyWorkoutMetrics(patch, to: existingModel)

        do {
            try modelContext.save()
            let yearMonthDay = YearMonthDay(date: existingModel.date)
            cache.removeObject(forKey: YearMonthDayCacheKey(yearMonthDay))
        } catch {
            throw PersistencesError.updateFailed
        }
    }

    public func deleteRunningRecord(_ record: Diary) async throws {
        let recordId = record.id
        let predicate = #Predicate<RunningRecordPersistenceModel> { $0.id == recordId }
        let descriptor = FetchDescriptor<RunningRecordPersistenceModel>(
            predicate: predicate
        )

        guard let model = try modelContext.fetch(descriptor).first else {
            throw PersistencesError.notFound
        }

        modelContext.delete(model)

        do {
            try modelContext.save()

            // 캐시 invalidate
            cache.removeObject(forKey: YearMonthDayCacheKey(record.workout.yearMonthDay))
        } catch {
            throw PersistencesError.deleteFailed
        }
    }

    // MARK: - Patch 적용

    /// 워크아웃 요약(날짜·거리·시간·페이스·심박·케이던스)을 반영한다.
    private static func applyWorkoutSummary(
        _ patch: DiaryPatch,
        to model: RunningRecordPersistenceModel
    ) {
        if let date = patch.date { model.date = date.toDate() }
        if let distance = patch.distance { model.distance = distance }
        if let duration = patch.duration { model.duration = duration }
        if let averagePace = patch.averagePace { model.averagePace = averagePace }
        if let averageHeartRate = patch.averageHeartRate { model.averageHeartRate = averageHeartRate }
        if let averageCadence = patch.averageCadence { model.averageCadence = averageCadence }
    }

    /// 사용자가 기록하는 일지 항목(통증·주법·메모·신발·날씨·난이도·경로)을 반영한다.
    private static func applyDiaryDetails(
        _ patch: DiaryPatch,
        to model: RunningRecordPersistenceModel
    ) {
        if let painAreas = patch.painAreas { model.painAreasRawData = PainAreasMapper.encode(painAreas) }
        if let runningStyle = patch.runningStyle { model.runningStyleRaw = runningStyle.rawValue }
        if let memo = patch.memo { model.memo = memo }
        if let shoes = patch.shoes { model.shoes = shoes }
        if let weather = patch.weather {
            model.temperature = weather.temperature
            model.humidity = weather.humidity
            model.windSpeed = weather.windSpeed
        }
        if let difficultyLevel = patch.difficultyLevel { model.difficultyLevelRaw = difficultyLevel.rawValue }
        if let routeData = patch.routeData { model.routeData = routeData }
    }

    /// HealthKit에서 가져오는 상세 지표와 운동 시각을 반영한다.
    private static func applyWorkoutMetrics(
        _ patch: DiaryPatch,
        to model: RunningRecordPersistenceModel
    ) {
        if let value = patch.activeEnergyBurned { model.activeEnergyBurned = value }
        if let value = patch.runningVerticalOscillation { model.runningVerticalOscillation = value }
        if let value = patch.runningGroundContactTime { model.runningGroundContactTime = value }
        if let value = patch.walkingStepLength { model.walkingStepLength = value }
        if let value = patch.restingHeartRate { model.restingHeartRate = value }
        if let value = patch.runningPower { model.runningPower = value }
        if let value = patch.runningStrideLength { model.runningStrideLength = value }
        if let value = patch.heartRateRecoveryOneMinute { model.heartRateRecoveryOneMinute = value }
        if let startTime = patch.startTime { model.startTime = startTime }
        if let endTime = patch.endTime { model.endTime = endTime }
    }

    // MARK: - Helper Methods

    private func generateDateRange(from startDate: Date, to endDate: Date) -> [YearMonthDay] {
        var dates: [YearMonthDay] = []
        let calendar = Calendar.current

        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while current <= end {
            dates.append(YearMonthDay(date: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}
