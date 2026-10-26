//
//  PersistencesClientIntegrationTests.swift
//  RunDiaryTests
//

import Foundation
import Models
import PersistencesService
import Testing

@testable import RunDiary

@Suite("PersistencesClient 통합")
struct PersistencesClientIntegrationTests {

    // MARK: - Integration Tests

    @Test("통합: fetch -> update -> fetch 흐름")
    @MainActor
    func integrationFetchUpdateFetch() async throws {
        let testDate = makeTestDate()
        let originalId = UUID()
        let startTime = makeTestDate()
        let endTime = startTime.addingTimeInterval(1500)

        var storage: [UUID: Diary] = [
            originalId: Diary(
                id: originalId,
                workout: HealthKitWorkout(
                    distance: 5.0,
                    duration: 1500,
                    averagePaceSecondsPerKm: 300,
                    averageHeartRate: 145,
                    averageCadence: 165,
                    activeEnergyBurned: 0,
                    averageVerticalOscillation: 0,
                    averageGroundContactTime: 0,
                    averageStepLength: 0,
                    restingHeartRate: 0,
                    averagePower: 0,
                    averageStrideLength: 0,
                    heartRateRecoveryOneMinute: 0,
                    startDate: startTime,
                    endDate: endTime
                ),
                painAreas: [],
                runningStyle: .forefoot,
                memo: nil
            ),
        ]

        let client = makePersistencesTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { _, _ in Array(storage.values) },
            save: { record in
                storage[record.id] = record
            },
            update: { recordId, patch in
                guard var existingRecord = storage[recordId] else { return }
                // Update only non-nil values
                if let distance = patch.distance {
                    let oldWorkout = existingRecord.workout
                    let newWorkout = HealthKitWorkout(
                        distance: distance,
                        duration: oldWorkout.duration,
                        averagePaceSecondsPerKm: oldWorkout.averagePaceSecondsPerKm,
                        averageHeartRate: oldWorkout.averageHeartRate,
                        averageCadence: oldWorkout.averageCadence,
                        activeEnergyBurned: oldWorkout.activeEnergyBurned,
                        averageVerticalOscillation: oldWorkout.averageVerticalOscillation,
                        averageGroundContactTime: oldWorkout.averageGroundContactTime,
                        averageStepLength: oldWorkout.averageStepLength,
                        restingHeartRate: oldWorkout.restingHeartRate,
                        averagePower: oldWorkout.averagePower,
                        averageStrideLength: oldWorkout.averageStrideLength,
                        heartRateRecoveryOneMinute: oldWorkout.heartRateRecoveryOneMinute,
                        route: oldWorkout.route,
                        startDate: oldWorkout.startTime,
                        endDate: oldWorkout.endTime
                    )
                    existingRecord = Diary(
                        id: existingRecord.id,
                        workout: newWorkout,
                        painAreas: existingRecord.painAreas,
                        runningStyle: existingRecord.runningStyle,
                        memo: existingRecord.memo,
                        shoe: existingRecord.shoe,
                        weather: existingRecord.weather,
                        difficultyLevel: existingRecord.difficultyLevel
                    )
                }
                storage[recordId] = existingRecord
            },
            delete: { record in
                storage.removeValue(forKey: record.id)
            }
        )

        let fetched = try await client.fetch(testDate)
        #expect(fetched != nil)
        #expect(fetched?.workout.distance == 5.0)

        try await client.updateRecord(recordId: originalId, patch: DiaryPatch(distance: 7.5))

        let fetchedAgain = try await client.fetch(testDate)
        #expect(fetchedAgain?.workout.distance == 7.5)
    }

    @Test("통합: save -> fetchRecords 흐름")
    @MainActor
    func integrationSaveFetchRecords() async throws {
        let startDate = makeTestDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        var storage: [UUID: Diary] = [:]

        let time1Start = makeTestDate()
        let time1End = time1Start.addingTimeInterval(1500)
        let time2Start = makeTestDate(day: 30)
        let time2End = time2Start.addingTimeInterval(2100)

        let client = makePersistencesTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { start, end in
                storage.values
                    .filter { $0.workout.startTime >= start && $0.workout.startTime <= end }
                    .sorted { $0.workout.startTime < $1.workout.startTime }
            },
            save: { record in
                storage[record.id] = record
            }
        )

        let record1 = Diary(
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
                averagePaceSecondsPerKm: 300,
                averageHeartRate: 145,
                averageCadence: 165,
                activeEnergyBurned: 0,
                averageVerticalOscillation: 0,
                averageGroundContactTime: 0,
                averageStepLength: 0,
                restingHeartRate: 0,
                averagePower: 0,
                averageStrideLength: 0,
                heartRateRecoveryOneMinute: 0,
                startDate: time1Start,
                endDate: time1End
            ),
            painAreas: [],
            runningStyle: .forefoot,
            memo: nil
        )

        let record2 = Diary(
            workout: HealthKitWorkout(
                distance: 7.0,
                duration: 2100,
                averagePaceSecondsPerKm: 300,
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
                startDate: time2Start,
                endDate: time2End
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        try await client.save(record1)
        try await client.save(record2)

        let records = try await client.fetchRecords(startDate, endDate)
        #expect(records.count == 2)
        #expect(records[0].workout.distance == 5.0)
        #expect(records[1].workout.distance == 7.0)
    }

    @Test("통합: save -> delete -> fetch 흐름")
    @MainActor
    func integrationSaveDeleteFetch() async throws {
        let testDate = makeTestDate()
        var storage: [UUID: Diary] = [:]

        let startTime = makeTestDate()
        let endTime = startTime.addingTimeInterval(1800)

        let client = makePersistencesTestClient(
            fetch: { date in
                storage.values.first { Calendar.current.isDate($0.workout.yearMonthDay.toDate(), inSameDayAs: date) }
            },
            fetchRecords: { _, _ in Array(storage.values) },
            save: { record in
                storage[record.id] = record
            },
            delete: { record in
                storage.removeValue(forKey: record.id)
            }
        )

        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 6.0,
                duration: 1800,
                averagePaceSecondsPerKm: 300,
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
                startDate: startTime,
                endDate: endTime
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        try await client.save(newRecord)

        let fetched = try await client.fetch(testDate)
        #expect(fetched != nil)

        try await client.delete(fetched!)

        let fetchedAgain = try await client.fetch(testDate)
        #expect(fetchedAgain == nil)
    }}
