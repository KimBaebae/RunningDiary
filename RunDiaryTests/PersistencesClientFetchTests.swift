//
//  PersistencesClientFetchTests.swift
//  RunDiaryTests
//

import Foundation
import Models
import PersistencesService
import Testing

@testable import RunDiary

@Suite("PersistencesClient fetch")
struct PersistencesClientFetchTests {

    // MARK: - fetch Tests

    @Test("fetch: 특정 날짜의 기록 조회 성공")
    @MainActor
    func fetchReturnsRecordForDate() async throws {
        let testDate = makeTestYearMonthDay()
        let startTime = makeTestDate()
        let endTime = startTime.addingTimeInterval(1800)

        let expectedRecord = Diary(
            workout: HealthKitWorkout(
                distance: 5.2,
                duration: 1800,
                averagePaceSecondsPerKm: 346,
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

        let client = makeFetchClient { date in
            #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
            return expectedRecord
        }

        let result = try await client.fetch(testDate.toDate())

        #expect(result != nil)
        #expect(result?.id == expectedRecord.id)
        #expect(result?.workout.yearMonthDay == testDate)
        #expect(result?.workout.distance == 5.2)
        #expect(result?.workout.duration == 1800)
        #expect(result?.workout.formattedAveragePace == "5'46\"")
        #expect(result?.workout.averageHeartRate == 150)
        #expect(result?.workout.averageCadence == 170)
        #expect(result?.runningStyle == .midfoot)
    }

    @Test("fetch: 기록이 없을 때 nil 반환")
    @MainActor
    func fetchReturnsNilWhenNoRecord() async throws {
        let testDate = makeTestYearMonthDay()

        let client = makeFetchClient { date in
            #expect(Calendar.current.isDate(date, inSameDayAs: testDate.toDate()))
            return nil
        }

        let result = try await client.fetch(testDate.toDate())
        #expect(result == nil)
    }

    @Test("fetch: 에러 발생 시 throw")
    @MainActor
    func fetchThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case fetchFailed
        }

        let client = makeFetchClient { _ in
            throw TestError.fetchFailed
        }

        await #expect(throws: TestError.fetchFailed) {
            try await client.fetch(Date.now)
        }
    }

    // MARK: - fetchRecords Tests

    @Test("fetchRecords: 날짜 범위의 여러 기록 조회")
    @MainActor
    func fetchRecordsReturnsMultipleRecords() async throws {
        let startDate = makeTestDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let time1Start = makeTestDate()
        let time1End = time1Start.addingTimeInterval(1500)
        let time2Start = makeTestDate(day: 30)
        let time2End = time2Start.addingTimeInterval(2250)

        let expectedRecords = [
            Diary(
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
            ),
            Diary(
                workout: HealthKitWorkout(
                    distance: 7.5,
                    duration: 2250,
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
            ),
        ]

        let client = makeFetchRecordsClient { start, end in
            #expect(Calendar.current.isDate(start, inSameDayAs: startDate))
            #expect(Calendar.current.isDate(end, inSameDayAs: endDate))
            return expectedRecords
        }

        let result = try await client.fetchRecords(startDate, endDate)

        #expect(result.count == 2)
        #expect(result[0].workout.distance == 5.0)
        #expect(result[0].runningStyle == .forefoot)
        #expect(result[1].workout.distance == 7.5)
        #expect(result[1].runningStyle == .midfoot)
    }

    @Test("fetchRecords: 기록이 없을 때 빈 배열 반환")
    @MainActor
    func fetchRecordsReturnsEmptyArray() async throws {
        let startDate = makeTestDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let client = makePersistencesTestClient()

        let result = try await client.fetchRecords(startDate, endDate)
        #expect(result.isEmpty)
    }

    @Test("fetchRecords: 에러 발생 시 throw")
    @MainActor
    func fetchRecordsThrowsErrorOnFailure() async throws {
        enum TestError: Error {
            case fetchFailed
        }

        let client = makeFetchRecordsClient { _, _ in
            throw TestError.fetchFailed
        }

        let startDate = makeTestDate()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        await #expect(throws: TestError.fetchFailed) {
            try await client.fetchRecords(startDate, endDate)
        }
    }
}
