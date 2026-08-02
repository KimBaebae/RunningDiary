//
//  CreateDiaryFeatureFlowTests.swift
//  RunDiaryTests
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

// MARK: - onAppear

@MainActor
@Suite("CreateDiaryFeature.onAppear")
struct CreateDiaryFeatureOnAppearTests {

    @Test("기존 기록 수정 시 날씨 조회 생략, 신발만 로드")
    func onAppear_existingRecord_loadsOnlyShoes() async {
        let shoe = makeShoe(id: "s1")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoe: shoe)
        var weatherFetchCalled = false

        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        await store.send(.onAppear) {
            $0.isShoesLoading = true
        }
        await store.receive(\.shoesLoaded) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
            $0.selectedShoe = shoe
        }

        #expect(weatherFetchCalled == false)
    }

    @Test("새 기록 + workout에 routeData 없음 → 신발만 로드")
    func onAppear_newRecordNoRoute_loadsOnlyShoes() async {
        let shoe = makeShoe(id: "s1")
        var weatherFetchCalled = false

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        store.exhaustivity = .off
        await store.send(.onAppear)
        await store.skipReceivedActions()

        #expect(weatherFetchCalled == false)
    }

    @Test("새 기록 + workout에 routeData 있음 → 날씨 조회 발생")
    func onAppear_newRecordWithRoute_fetchesWeather() async {
        await ShoeCache.shared.reset()
        var weatherFetchCalled = false

        let route = [
            makeRoutePoint(latitude: 37.5, longitude: 127.0),
            makeRoutePoint(latitude: 37.6, longitude: 127.1),
        ]

        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                healthKitWorkout: makeWorkoutWithRoute(route: route)
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.shoeClient.fetchAllShoes = { [] }
            $0.weatherClient.fetchWeather = { _, _ in
                weatherFetchCalled = true
                return WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
            }
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }

        store.exhaustivity = .off
        await store.send(.onAppear)
        await store.skipReceivedActions()

        #expect(weatherFetchCalled == true)
    }
}

// MARK: - shoesLoaded matching

@MainActor
@Suite("CreateDiaryFeature.shoesLoaded")
struct CreateDiaryFeatureShoesLoadedTests {

    @Test("저장된 신발이 목록 도착 시 정식 항목으로 교체됨")
    func shoesLoaded_matchesExistingRecordShoe() async {
        let shoe = makeShoe(id: "existing-shoe")
        // 목록 없이 복원된 기록은 메타데이터가 빈 최소 엔티티를 갖는다.
        let storedShoe = Shoe.unresolved(id: "existing-shoe", displayName: "existing-shoe")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoe: storedShoe)
        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
        }

        await store.send(.shoesLoaded([shoe])) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
            $0.selectedShoe = shoe
        }
    }

    @Test("저장된 신발이 목록에 없으면 selectedShoe를 비움")
    func shoesLoaded_noMatchingShoe_clearsSelectedShoe() async {
        let shoe = makeShoe(id: "other-shoe")
        let storedShoe = Shoe.unresolved(id: "not-in-list", displayName: "not-in-list")
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot, shoe: storedShoe)
        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
        }

        await store.send(.shoesLoaded([shoe])) {
            $0.isShoesLoading = false
            $0.shoes = [shoe]
            $0.selectedShoe = nil
        }
    }

    @Test("shoesLoadFailed → isShoesLoading = false")
    func shoesLoadFailed_clearsShoesLoading() async {
        let store = makeStore { $0.isShoesLoading = true }
        await store.send(.shoesLoadFailed) {
            $0.isShoesLoading = false
        }
    }
}

// MARK: - saveRecord new vs update

@MainActor
@Suite("CreateDiaryFeature.saveRecord 신규 vs 수정")
struct CreateDiaryFeatureSaveRouteTests {

    @Test("existingRecord nil → saveRecord 호출, updateRecord 미호출")
    func saveRecord_newDiary_callsSaveNotUpdate() async {
        var saveCallCount = 0
        var updateCallCount = 0
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in saveCallCount += 1 }
            $0.runningRecordClient.updateRecord = { _ in updateCallCount += 1 }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(saveCallCount == 1)
        #expect(updateCallCount == 0)
    }

    @Test("existingRecord 있음 → updateRecord 호출, saveRecord 미호출")
    func saveRecord_existingDiary_callsUpdateNotSave() async {
        var saveCallCount = 0
        var updateCallCount = 0
        let shoe = makeShoe()
        let existing = Diary(workout: makeWorkout(), runningStyle: .midfoot)

        let store = TestStore(
            initialState: CreateDiaryFeature.State(
                existingRecord: existing,
                healthKitWorkout: makeWorkout()
            )
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in saveCallCount += 1 }
            $0.runningRecordClient.updateRecord = { _ in updateCallCount += 1 }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(saveCallCount == 0)
        #expect(updateCallCount == 1)
    }

    @Test("저장 실패 시 isLoading=false, errorMessage 설정")
    func saveRecord_failure_setsErrorMessage() async {
        struct SaveError: Error, LocalizedError {
            var errorDescription: String? { "저장 실패" }
        }
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { _ in throw SaveError() }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.saveRecord) { $0.isLoading = true }
        await store.receive(\.recordSaveFailed) {
            $0.isLoading = false
            $0.errorMassage = "저장 실패"
        }
    }

    @Test("빈 memo는 Diary.memo = nil로 저장")
    func saveRecord_emptyMemo_savesNilMemo() async {
        var capturedRecord: Diary?
        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { capturedRecord = $0 }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.updateMemo(""))
        await store.send(.saveRecord)
        await store.skipReceivedActions()

        #expect(capturedRecord?.memo == nil)
    }
}
