//
//  DailyDetailFeatureTests.swift
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

@MainActor
@Suite("DailyDetailFeature")
struct DailyDetailFeatureTests {

    // MARK: - Initialization Tests

    @Test("onAppear: dates가 비어있으면 주 날짜 초기화 및 fetchWeekRecords 트리거")
    func onAppear_emptyDates_initializesWeekDatesAndFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedWeekDates = makeWeekDates(containing: testDate)
        let expectedDiaries = [makeDiary(yearMonthDay: testDate)]
        let expectedWorkouts = [makeHealthKitWorkout(yearMonthDay: testDate)]

        let initialState = DailyDetailFeature.State(selectedDate: testDate)

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: expectedDiaries,
            workouts: expectedWorkouts
        )

        // fetchWeekRecords → weekRecordsFetched 연쇄 이후의 in-flight effect는 skip
        sut.exhaustivity = .off

        // When
        await sut.send(.onAppear) {
            // Then
            $0.dates = expectedWeekDates
        }

        // Then - 최종 상태 확인
        await sut.skipReceivedActions()
        #expect(sut.state.diaries == Dictionary(grouping: expectedDiaries, by: \.workout.yearMonthDay))
        #expect(sut.state.workouts == Dictionary(grouping: expectedWorkouts, by: \.yearMonthDay))
        #expect(sut.state.isLoading == false)
    }

    @Test("onAppear: dates가 이미 있으면 dates 유지 및 fetchWeekRecords 트리거")
    func onAppear_existingDates_preservesDates() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingDates = makeWeekDates(containing: testDate)

        let initialState = DailyDetailFeature.State(selectedDate: testDate, dates: existingDates)

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        sut.exhaustivity = .off

        // When - dates는 유지되고 fetchWeekRecords만 트리거
        await sut.send(.onAppear)

        // Then - 최종 상태 확인 (dates는 변경되지 않음)
        await sut.skipReceivedActions()
        #expect(sut.state.dates == existingDates)
        #expect(sut.state.isLoading == false)
    }

    // MARK: - Date Selection Tests

    @Test("dateSelected: selectedDate만 변경")
    func dateSelected_changesOnlySelectedDate() async {
        // Given
        let initialDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: initialDate)
        let newSelectedDate = weekDates.first { $0 != initialDate } ?? weekDates[0]

        var initialState = DailyDetailFeature.State(selectedDate: initialDate)
        initialState.dates = weekDates

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.dateSelected(newSelectedDate)) {
            $0.selectedDate = newSelectedDate
        }
    }

    // MARK: - Week Navigation Tests

    @Test("weekChanged: 다음 주 이동 및 fetchWeekRecords 트리거")
    func weekChanged_forward_movesToNextWeekAndFetches() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let nextWeekStart = DateHelper.addWeeks(1, to: currentWeekDates.first!.toDate())
        let expectedNextWeekDates = DateHelper.getWeekDates(for: nextWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = currentWeekDates

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.weekChanged(offset: 1)) {
            // Then
            $0.dates = expectedNextWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = expectedNextWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = expectedNextWeekDates.first!
            }
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    @Test("weekChanged: 이전 주 이동")
    func weekChanged_backward_movesToPreviousWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let currentWeekDates = makeWeekDates(containing: testDate)
        let prevWeekStart = DateHelper.addWeeks(-1, to: currentWeekDates.first!.toDate())
        let expectedPrevWeekDates = DateHelper.getWeekDates(for: prevWeekStart).map { YearMonthDay(date: $0) }

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = currentWeekDates

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.weekChanged(offset: -1)) {
            // Then
            $0.dates = expectedPrevWeekDates

            let calendar = Calendar.current
            let currentWeekday = calendar.component(.weekday, from: testDate.toDate())
            if let newSelectedDate = expectedPrevWeekDates.first(where: {
                calendar.component(.weekday, from: $0.toDate()) == currentWeekday
            }) {
                $0.selectedDate = newSelectedDate
            } else {
                $0.selectedDate = expectedPrevWeekDates.first!
            }
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - Data Fetching Tests

    @Test("fetchWeekRecords: dates가 비어있으면 emptyWeekDates 에러")
    func fetchWeekRecords_emptyDates_returnsEmptyWeekDatesError() async {
        // Given
        let sut = TestStore(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        }

        // When
        await sut.send(.fetchWeekRecords)

        // Then
        await sut.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .emptyWeekDates
        }
    }

    @Test("fetchWeekRecords: 성공 시 diaries와 workouts 설정")
    func fetchWeekRecords_success_setsDiariesAndWorkouts() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)
        let expectedDiaries = [makeDiary(yearMonthDay: testDate, distance: 5.5)]
        let expectedWorkouts = [makeHealthKitWorkout(yearMonthDay: testDate, distance: 6.0)]

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: expectedDiaries,
            workouts: expectedWorkouts
        )

        // When
        await sut.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        // Then
        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
            $0.diaries = Dictionary(grouping: expectedDiaries, by: \.workout.yearMonthDay)
            $0.workouts = Dictionary(grouping: expectedWorkouts, by: \.yearMonthDay)
        }
    }

    @Test("fetchWeekRecords: 실패 시 에러 상태 설정")
    func fetchWeekRecords_failure_setsErrorState() async {
        // Given
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Network error" }
        }

        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = makeWeekDates(containing: testDate)

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        } withDependencies: {
            $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in
                throw TestError()
            }
            $0.persistencesClient.fetchRecords = { _, _ in [] }
        }

        // When
        await sut.send(.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        // Then
        await sut.receive(\.weekRecordsFetchFailed) {
            $0.isLoading = false
            $0.error = .fetchFailed(underlyingError: "Network error")
        }
    }

    // MARK: - Calendar Integration Tests

    @Test("calendarButtonTapped: Calendar 시트 표시")
    func calendarButtonTapped_showsCalendarSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.calendarButtonTapped) {
            $0.calendar = CalendarFeature.State(selectedDate: testDate)
        }
    }

    @Test("calendar dismiss: 시트 닫힘")
    func calendarDismiss_closesSheet() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.calendar = CalendarFeature.State(selectedDate: testDate)

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.calendar(.dismiss)) {
            $0.calendar = nil
        }
    }

    @Test("calendar navigateToDiary: 날짜 이동 및 fetchWeekRecords 트리거")
    func calendarNavigateToDiary_navigatesToDateAndFetches() async {
        // Given
        let currentDate = makeYearMonthDay(year: 2025, month: 11, day: 27)
        let selectedDate = makeYearMonthDay(year: 2025, month: 12, day: 10)
        let expectedWeekDates = makeWeekDates(containing: selectedDate)

        var initialState = DailyDetailFeature.State(selectedDate: currentDate)
        initialState.dates = makeWeekDates(containing: currentDate)
        initialState.calendar = CalendarFeature.State(selectedDate: selectedDate)

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.calendar(.presented(.navigateToDiary))) {
            // Then
            $0.calendar = nil
            $0.dates = expectedWeekDates
            $0.selectedDate = selectedDate
        }

        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }
}
