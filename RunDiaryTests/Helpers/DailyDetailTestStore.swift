//
//  DailyDetailTestStore.swift
//  RunDiaryTests
//

import ComposableArchitecture
import Foundation
import Models

@testable import RunDiary

/// DailyDetailFeature 테스트용 TestStore.
///
/// 분할된 DailyDetail 테스트 파일들이 공유한다.
@MainActor
func makeDailyDetailStore(
    initialState: DailyDetailFeature.State,
    diaries: [Diary],
    workouts: [HealthKitWorkout]
) -> TestStore<DailyDetailFeature.State, DailyDetailFeature.Action> {
    TestStore(initialState: initialState) {
        DailyDetailFeature()
    } withDependencies: {
        $0.healthKitClient.fetchRunningDataBetweenDates = { _, _ in workouts }
        $0.persistencesClient.fetchRecords = { _, _ in diaries }
        $0.persistencesClient.update = { _, _ in }
        $0.shoeClient.fetchAllShoes = { [] }
    }
}
