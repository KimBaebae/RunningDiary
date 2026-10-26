//
//  PersistencesClientMutationTests.swift
//  RunDiaryTests
//

import Foundation
import Models
import PersistencesService
import Testing

@testable import RunDiary

@Suite("PersistencesClient 저장·수정·삭제")
struct PersistencesClientMutationTests {

    // MARK: - save Tests

    @Test("save: 새 기록 저장 성공")
    @MainActor
    func saveStoresNewRecord() async throws {
        let startTime = makeTestDate()
        let endTime = startTime.addingTimeInterval(3000)

        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 10.0,
                duration: 3000,
                averagePaceSecondsPerKm: 300,
                averageHeartRate: 160,
                averageCadence: 180,
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

        var savedRecord: Diary?

        let client = makeSaveClient { record in
            savedRecord = record
        }

        try await client.save(newRecord)

        #expect(savedRecord != nil)
        #expect(savedRecord?.id == newRecord.id)
        #expect(savedRecord?.workout.distance == 10.0)
        #expect(savedRecord?.workout.duration == 3000)
        #expect(savedRecord?.workout.averageHeartRate == 160)
    }

    @Test("save: 에러 발생 시 throw")
    @MainActor
    func saveThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case saveFailed
        }

        let client = makeSaveClient { _ in
            throw TestError.saveFailed
        }

        let startTime = makeTestDate()
        let newRecord = Diary(
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
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
                endDate: startTime.addingTimeInterval(1500)
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        await #expect(throws: TestError.saveFailed) {
            try await client.save(newRecord)
        }
    }

    // MARK: - update Tests

    @Test("update: 기존 기록 업데이트 성공")
    @MainActor
    func updateModifiesExistingRecord() async throws {
        let recordId = UUID()

        var updatedRecordId: UUID?
        var updatedDistance: Double?
        var updatedMemo: String?

        let client = makeUpdateClient { id, patch in
            updatedRecordId = id
            updatedDistance = patch.distance
            updatedMemo = patch.memo
        }

        try await client.updateRecord(
            recordId: recordId,
            patch: DiaryPatch(distance: 6.0, memo: "updated")
        )

        #expect(updatedRecordId == recordId)
        #expect(updatedDistance == 6.0)
        #expect(updatedMemo == "updated")
    }

    @Test("update: 에러 발생 시 throw")
    @MainActor
    func updateThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case updateFailed
        }

        let client = makeUpdateClient { _, _ in
            throw TestError.updateFailed
        }

        let recordId = UUID()

        await #expect(throws: TestError.updateFailed) {
            try await client.updateRecord(recordId: recordId, patch: DiaryPatch(distance: 5.0))
        }
    }

    // MARK: - delete Tests

    @Test("delete: 기록 삭제 성공")
    @MainActor
    func deleteRemovesRecord() async throws {
        let startTime = makeTestDate()
        let endTime = startTime.addingTimeInterval(1200)

        let recordToDelete = Diary(
            workout: HealthKitWorkout(
                distance: 3.0,
                duration: 1200,
                averagePaceSecondsPerKm: 400,
                averageHeartRate: 140,
                averageCadence: 160,
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

        var deletedRecord: Diary?

        let client = makeDeleteClient { record in
            deletedRecord = record
        }

        try await client.delete(recordToDelete)

        #expect(deletedRecord != nil)
        #expect(deletedRecord?.id == recordToDelete.id)
        #expect(deletedRecord?.workout.distance == 3.0)
    }

    @Test("delete: 에러 발생 시 throw")
    @MainActor
    func deleteThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case deleteFailed
        }

        let client = makeDeleteClient { _ in
            throw TestError.deleteFailed
        }

        let startTime = makeTestDate()
        let record = Diary(
            id: UUID(),
            workout: HealthKitWorkout(
                distance: 5.0,
                duration: 1500,
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
                endDate: startTime.addingTimeInterval(1500)
            ),
            painAreas: [],
            runningStyle: .midfoot,
            memo: nil
        )

        await #expect(throws: TestError.deleteFailed) {
            try await client.delete(record)
        }
    }
}
