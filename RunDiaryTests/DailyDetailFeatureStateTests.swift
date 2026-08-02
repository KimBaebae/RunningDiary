//
//  DailyDetailFeatureStateTests.swift
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
@Suite("DailyDetailFeature 상태·통합")
struct DailyDetailFeatureStateTests {

    // MARK: - Computed Properties Tests

    @Test("diariesOnSelectedDate: 선택 날짜의 diaries 반환")
    func diariesOnSelectedDate_returnsDiariesForSelectedDate() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedDiary = makeDiary(yearMonthDay: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.diaries = [testDate: [expectedDiary]]

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(sut.state.diariesOnSelectedDate == [expectedDiary])
    }

    @Test("workoutsOnSelectedDate: 선택 날짜의 workouts 반환")
    func workoutsOnSelectedDate_returnsWorkoutsForSelectedDate() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.workouts = [testDate: [expectedWorkout]]

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        #expect(sut.state.workoutsOnSelectedDate == [expectedWorkout])
    }

    // MARK: - Refresh Tests

    @Test("refreshCurrentWeek: fetchWeekRecords 트리거")
    func refreshCurrentWeek_triggersFetchWeekRecords() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = makeWeekDates(containing: testDate)

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.refreshCurrentWeek)

        // Then
        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - CreateDiary Integration Tests

    @Test("createRecord: CreateDiary를 추가 모드로 표시")
    func createRecord_opensCreateDiaryInAddMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let healthKitWorkout = makeHealthKitWorkout(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When
        await sut.send(.createRecord(healthKitWorkout))

        // Then
        #expect(sut.state.createDiary != nil)
        #expect(sut.state.createDiary?.existingRecord == nil)
        #expect(sut.state.createDiary?.healthKitWorkout == healthKitWorkout)
    }

    @Test("editRecord: CreateDiary를 편집 모드로 표시")
    func editRecord_opensCreateDiaryInEditMode() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let diary = makeDiary(yearMonthDay: testDate)

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
        }

        sut.exhaustivity = .off

        // When & Then
        await sut.send(.editRecord(diary)) {
            $0.createDiary = CreateDiaryFeature.State(
                existingRecord: diary,
                healthKitWorkout: diary.workout
            )
        }
    }

    @Test("createDiary dismiss: 시트 닫힘")
    func createDiaryDismiss_closesSheet() async {
        // Given
        var initialState = DailyDetailFeature.State()
        initialState.createDiary = CreateDiaryFeature.State(
            existingRecord: nil,
            healthKitWorkout: makeHealthKitWorkout(yearMonthDay: makeTodayYearMonthDay())
        )

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.createDiary(.dismiss)) {
            $0.createDiary = nil
        }
    }

    @Test("createDiary recordSaved: 주 단위 새로고침")
    func createDiarySaved_refreshesWeek() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let weekDates = makeWeekDates(containing: testDate)

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.dates = weekDates
        initialState.createDiary = CreateDiaryFeature.State(
            existingRecord: nil,
            healthKitWorkout: makeHealthKitWorkout(yearMonthDay: testDate)
        )

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        // When
        await sut.send(.createDiary(.presented(.recordSaved))) {
            $0.createDiary = nil
        }

        // Then
        await sut.receive(\.fetchWeekRecords) {
            $0.isLoading = true
            $0.error = nil
        }

        await sut.receive(\.weekRecordsFetched) {
            $0.isLoading = false
        }
    }

    // MARK: - Settings Integration Tests

    @Test("settingsButtonTapped: Settings 화면 표시")
    func settingsButtonTapped_opensSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        }

        sut.exhaustivity = .off

        // When & Then
        await sut.send(.settingsButtonTapped) {
            $0.settings = SettingsFeature.State()
        }
    }

    @Test("settings dismiss: 화면 닫힘")
    func settingsDismiss_closesSettings() async {
        // Given
        let testDate = makeTodayYearMonthDay()

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.settings = SettingsFeature.State()

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.settings(.dismiss)) {
            $0.settings = nil
        }
    }

    // MARK: - Preload Tests

    @Test("preloadRequested: weatherTrademark이 nil이면 fetch 트리거")
    func preloadRequested_noTrademark_fetchesTrademark() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let expectedTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        let sut = TestStore(initialState: DailyDetailFeature.State(selectedDate: testDate)) {
            DailyDetailFeature()
        } withDependencies: {
            $0.weatherClient.fetchTrademark = { expectedTrademark }
            $0.shoeClient.fetchAllShoes = { [] }
        }

        // .merge로 전송되는 액션들의 순서가 비결정적이므로 exhaustivity off
        sut.exhaustivity = .off

        // When
        await sut.send(.preloadRequested)

        // Then
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == expectedTrademark)
    }

    @Test("preloadRequested: weatherTrademark이 이미 있으면 fetch 생략")
    func preloadRequested_existingTrademark_skipsFetch() async {
        // Given
        let testDate = makeTodayYearMonthDay()
        let existingTrademark = WeatherTrademark(
            imageURL: URL(string: "https://example.com/icon.png"),
            legalPageURL: URL(string: "https://example.com/legal")
        )

        var initialState = DailyDetailFeature.State(selectedDate: testDate)
        initialState.weatherTrademark = existingTrademark

        let sut = makeDailyDetailStore(
            initialState: initialState,
            diaries: [],
            workouts: []
        )

        sut.exhaustivity = .off

        // When
        await sut.send(.preloadRequested)

        // Then - 최종 상태 확인 (weatherTrademark은 변경되지 않음)
        await sut.skipReceivedActions()
        #expect(sut.state.weatherTrademark == existingTrademark)
    }

    // MARK: - Error Handling Tests

    @Test("weekRecordsFetchFailed: 에러 상태 설정")
    func weekRecordsFetchFailed_setsErrorState() async {
        // Given
        let expectedError = DailyDetailError.fetchFailed(underlyingError: "Network error")

        var initialState = DailyDetailFeature.State()
        initialState.isLoading = true

        let sut = TestStore(initialState: initialState) {
            DailyDetailFeature()
        }

        // When & Then
        await sut.send(.weekRecordsFetchFailed(expectedError)) {
            $0.isLoading = false
            $0.error = expectedError
        }
    }
}
