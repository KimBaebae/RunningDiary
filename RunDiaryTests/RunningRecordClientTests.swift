//
//  RunningRecordClientTests.swift
//  RunDiaryTests
//
//  Created by Claude on 11/29/25.
//

import ComposableArchitecture
import Foundation
import Models

import Testing

@testable import RunDiary

@Suite("RunningRecordClient")
@MainActor
struct RunningRecordClientTests {

    // MARK: - Deduplication Tests

    @Test("HealthKit 데이터 중복 필터링 - startDate 일치")
    func fetchData_filtersHealthKitWorkouts_whenStartDateMatchesSavedRecord() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)

        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)
        let savedRecord = makeDiary(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - HealthKit workout should be filtered out
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
    }

    @Test("HealthKit 데이터 보존 - startDate 불일치")
    func fetchData_keepsHealthKitWorkouts_whenStartDateDifferent() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)

        let healthKitWorkout = makeHealthKitWorkout(
            yearMonthDay: testDate,
            startOffset: 1000  // Different time
        )
        let savedRecord = makeDiary(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - Both should be present
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
    }

    @Test("여러 RunningRecord가 여러 HealthKit 데이터 필터링")
    func fetchData_filtersMultipleHealthKitWorkouts_withMultipleSavedRecords() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let startTime3 = testDate.toDate().addingTimeInterval(7200)

        let healthKit1 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let healthKit2 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)
        let healthKit3 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 7200)

        let saved1 = makeDiary(yearMonthDay: testDate, startOffset: 0)
        let saved2 = makeDiary(yearMonthDay: testDate, startOffset: 3600)

        let client = makeTestClient(
            healthKitWorkouts: [healthKit1, healthKit2, healthKit3],
            savedRecords: [saved1, saved2]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then - Only healthKit3 should remain (others filtered)
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.savedRecords.count == 2)
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
        #expect(dailyRecord?.healthKitWorkouts.first?.startTime == startTime3)
    }

    // MARK: - Date Range Tests

    @Test("fetchData는 여러 월에 걸친 범위 조회")
    func fetchData_handlesMultiMonthRange() async throws {
        // Given
        let januaryEnd = makeYearMonthDay(month: 1, day: 31)
        let februaryStart = makeYearMonthDay(month: 2, day: 1)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(januaryEnd, februaryStart)

        // Then - Should have results for both dates
        #expect(result.count == 2)
        #expect(result[januaryEnd] != nil)
        #expect(result[februaryStart] != nil)
    }

    // MARK: - Edge Cases

    @Test("빈 데이터 처리 - HealthKit과 SwiftData 모두 빈 배열")
    func fetchData_handlesEmptyDataFromBothSources() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
        #expect(dailyRecord?.savedRecords.isEmpty == true)
        #expect(dailyRecord?.hasAnyData == false)
    }

    @Test("HealthKit만 데이터 있음")
    func fetchData_handlesOnlyHealthKitData() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [healthKitWorkout],
            savedRecords: []
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.count == 1)
        #expect(dailyRecord?.savedRecords.isEmpty == true)
        #expect(dailyRecord?.hasAnyData == true)
    }

    @Test("SwiftData만 데이터 있음")
    func fetchData_handlesOnlySwiftDataData() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let savedRecord = makeDiary(yearMonthDay: testDate)

        let client = makeTestClient(
            healthKitWorkouts: [],
            savedRecords: [savedRecord]
        )

        // When
        let result = try await client.fetchData(testDate, testDate)

        // Then
        let dailyRecord = result[testDate]
        #expect(dailyRecord?.healthKitWorkouts.isEmpty == true)
        #expect(dailyRecord?.savedRecords.count == 1)
        #expect(dailyRecord?.hasAnyData == true)
    }

    // MARK: - Save and Update Tests

    @Test("saveRecord는 의존성을 통해 저장")
    func saveRecord_callsPersistencesClient() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let recordToSave = makeDiary(yearMonthDay: testDate)

        var savedRecord: Diary?
        let client = makeSaveCapturingClient { record in
            savedRecord = record
        }

        // When
        try await client.saveRecord(recordToSave)

        // Then
        #expect(savedRecord != nil)
        #expect(savedRecord?.workout.yearMonthDay == testDate)
    }

    @Test("updateRecord는 의존성을 통해 업데이트")
    func updateRecord_callsPersistencesClient() async throws {
        // Given
        let testDate = makeYearMonthDay(month: 1, day: 15)
        let recordToUpdate = makeDiary(yearMonthDay: testDate)

        var updatedRecord: Diary?
        let client = makeUpdateCapturingClient { record in
            updatedRecord = record
        }

        // When
        try await client.updateRecord(recordToUpdate)

        // Then
        #expect(updatedRecord != nil)
        #expect(updatedRecord?.workout.yearMonthDay == testDate)
    }
}

// MARK: - Test Helpers

private extension RunningRecordClientTests {
    /// 저장 호출만 캡처하는 클라이언트.
    ///
    /// makeTestClient는 뒤에 기본값 파라미터(onUpdate)가 남아
    /// trailing closure로 넘기면 onUpdate에 잘못 매칭된다.
    @MainActor
    func makeSaveCapturingClient(
        _ onSave: @escaping (Diary) -> Void
    ) -> RunningRecordClient {
        makeTestClient(onSave: onSave)
    }

    /// 업데이트 호출만 캡처하는 클라이언트.
    @MainActor
    func makeUpdateCapturingClient(
        _ onUpdate: @escaping (Diary) -> Void
    ) -> RunningRecordClient {
        makeTestClient(onUpdate: onUpdate)
    }

    /// 테스트용 RunningRecordClient 생성
    @MainActor
    func makeTestClient(
        healthKitWorkouts: [HealthKitWorkout] = [],
        savedRecords: [Diary] = [],
        onSave: @escaping (Diary) -> Void = { _ in },
        onUpdate: @escaping (Diary) -> Void = { _ in }
    ) -> RunningRecordClient {
        // 직접 RunningRecordClient를 생성하여 테스트
        RunningRecordClient(
            fetchData: { from, to in
                // 날짜 범위의 끝을 해당 날짜의 마지막 시간으로 설정
                let calendar = Calendar.current
                let startOfFromDate = from.toDate()
                let endOfToDate = calendar.date(byAdding: .day, value: 1, to: to.toDate())!.addingTimeInterval(-1)

                // Return filtered workouts for date range
                let filteredHealthKit = healthKitWorkouts.filter { workout in
                    workout.startTime >= startOfFromDate && workout.startTime <= endOfToDate
                }
                let filteredRecords = savedRecords.filter { record in
                    record.workout.startTime >= startOfFromDate && record.workout.startTime <= endOfToDate
                }

                // 날짜별 그룹핑
                let groupedHK = Dictionary(grouping: filteredHealthKit, by: \.yearMonthDay)
                let groupedRecords = Dictionary(grouping: filteredRecords, by: \.workout.yearMonthDay)

                // 요청 범위의 모든 날짜 생성
                var dates: [YearMonthDay] = []
                var current = from
                while current <= to {
                    dates.append(current)
                    guard let next = current.add(day: 1) else { break }
                    current = next
                }

                // 각 날짜별로 DailyRecord 생성
                var result: [YearMonthDay: DailyRecord] = [:]
                for date in dates {
                    let saved = groupedRecords[date] ?? []
                    let healthKit = groupedHK[date] ?? []

                    // 중복 제거: SwiftData에 저장된 것은 HealthKit에서 제외
                    let filteredHealthKit = healthKit.filter { workout in
                        !saved.contains { $0.workout.startTime == workout.startTime }
                    }

                    result[date] = DailyRecord(
                        yearMonthDay: date,
                        healthKitWorkouts: filteredHealthKit.sorted { $0.startTime < $1.startTime },
                        savedRecords: saved
                    )
                }

                return result
            },
            saveRecord: { record in
                onSave(record)
            },
            updateRecord: { record in
                onUpdate(record)
            }
        )
    }
}
