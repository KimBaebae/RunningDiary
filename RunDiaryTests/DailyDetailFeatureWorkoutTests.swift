//
//  DailyDetailFeatureWorkoutTests.swift
//  RunDiaryTests
//
//  Created by Claude on 1/19/26.
//

import CommonFoundation
import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

    // MARK: - filteredWorkoutsOnSelectedDate Tests

    @Test("filteredWorkoutsOnSelectedDate: diary와 startTime 일치하는 workout 제외")
    func filteredWorkouts_excludesWorkoutsMatchingDiaryStartTime() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let sharedStart = testDate.toDate()
        let diary = makeDiary(yearMonthDay: testDate, startOffset: 0)
        let matchedWorkout = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let unmatchedWorkout = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [diary]]
        state.workouts = [testDate: [matchedWorkout, unmatchedWorkout]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate == [unmatchedWorkout])
    }

    @Test("filteredWorkoutsOnSelectedDate: diary 없으면 모든 workout 포함")
    func filteredWorkouts_noDiaries_includesAllWorkouts() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let w1 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let w2 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.workouts = [testDate: [w1, w2]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate.count == 2)
    }

    @Test("filteredWorkoutsOnSelectedDate: workout 없으면 빈 배열")
    func filteredWorkouts_noWorkouts_returnsEmpty() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [diary]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate.isEmpty)
    }

    @Test("filteredWorkoutsOnSelectedDate: 여러 diary 중 일부만 매칭 → 나머지 workout 유지")
    func filteredWorkouts_partialMatch_keepsUnmatched() {
        // Given
        let testDate = makeTodayYearMonthDay()
        let d1 = makeDiary(yearMonthDay: testDate, startOffset: 0)
        let d2 = makeDiary(yearMonthDay: testDate, startOffset: 3600)
        let w1 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 0)
        let w2 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 3600)
        let w3 = makeHealthKitWorkout(yearMonthDay: testDate, startOffset: 7200)

        var state = DailyDetailFeature.State(selectedDate: testDate)
        state.diaries = [testDate: [d1, d2]]
        state.workouts = [testDate: [w1, w2, w3]]

        // When & Then
        #expect(state.filteredWorkoutsOnSelectedDate == [w3])
    }

    // MARK: - Fetch Side-Effect Tests

    @Test("weekRecordsFetched: 조회 시 persistence 쓰기(update) 부작용 없음")
    func weekRecordsFetched_nonZeroMetrics_skipsMigration() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let diary = makeDiary(yearMonthDay: testDate)
        var migrationCallCount = 0

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.persistencesClient.fetchRecords = { _, _ in [diary] }
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in [] }
            $0.persistencesClient.update = { _, _ in
                migrationCallCount += 1
            }
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.fetchWeekRecords)
        await sut.skipReceivedActions()

        // Then — makeDiary의 workout은 metrics > 0이므로 마이그레이션 미호출
        #expect(migrationCallCount == 0)
    }
