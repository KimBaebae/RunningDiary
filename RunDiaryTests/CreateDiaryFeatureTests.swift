//
//  CreateDiaryFeatureTests.swift
//  RunDiaryTests
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

@MainActor
@Suite("CreateDiaryFeature step navigation")
struct CreateDiaryFeatureStepTests {

    @Test("nextStepTapped advances to the next step")
    func nextStepTapped_advancesStep() async {
        let store = makeStore()

        await store.send(.nextStepTapped) {
            $0.currentStep = .weather
        }
        await store.send(.nextStepTapped) {
            $0.currentStep = .shoes
        }
    }

    @Test("nextStepTapped at the last step keeps the step")
    func nextStepTapped_atLastStep_noChange() async {
        let store = makeStore { state in
            state.currentStep = .memo
        }

        await store.send(.nextStepTapped)
    }

    @Test("previousStepTapped at the first step keeps the step")
    func previousStepTapped_atFirstStep_noChange() async {
        let store = makeStore()

        await store.send(.previousStepTapped)
    }

    @Test("previousStepTapped goes back one step")
    func previousStepTapped_goesBack() async {
        let store = makeStore { state in
            state.currentStep = .weather
        }

        await store.send(.previousStepTapped) {
            $0.currentStep = .fitness
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature weather step edits")
struct CreateDiaryFeatureWeatherTests {

    @Test("updateSkyCondition stores the value")
    func updateSkyCondition() async {
        let store = makeStore()
        await store.send(.updateSkyCondition(.cloudy)) {
            $0.skyCondition = .cloudy
        }
    }

    @Test("updateWindLevel stores the value")
    func updateWindLevel() async {
        let store = makeStore()
        await store.send(.updateWindLevel(.strong)) {
            $0.windLevel = .strong
        }
    }

    @Test("updateFeelsLike stores the value")
    func updateFeelsLike() async {
        let store = makeStore()
        await store.send(.updateFeelsLike(.cold)) {
            $0.feelsLike = .cold
        }
    }

    @Test("updateHumidityLevel stores the value")
    func updateHumidityLevel() async {
        let store = makeStore()
        await store.send(.updateHumidityLevel(.humid)) {
            $0.humidityLevel = .humid
        }
    }

    @Test("weatherFetched copies classification fields into state")
    func weatherFetched_copiesClassification() async {
        let store = makeStore()

        let fetched = WeatherData(
            temperature: 25,
            humidity: 80,
            windSpeed: 6,
            cloudCover: 0.8,
            apparentTemperature: 28
        )

        await store.send(.weatherFetched(fetched)) {
            $0.weather = fetched
            $0.skyCondition = .cloudy
            $0.windLevel = .strong
            $0.feelsLike = .hot
            $0.humidityLevel = .humid
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature save")
struct CreateDiaryFeatureSaveTests {

    @Test("saveRecord merges user-edited classification into weather and persists")
    func saveRecord_mergesWeather() async {
        let workout = makeWorkout()

        let baseWeather = WeatherData(
            temperature: 18,
            humidity: 50,
            windSpeed: 1,
            skyCondition: .sunny,
            windLevel: .weak,
            feelsLike: .neutral,
            humidityLevel: .dry
        )

        var capturedRecord: Diary?

        let shoe = makeShoe()

        let store = TestStore(
            initialState: CreateDiaryFeature.State(healthKitWorkout: workout)
        ) {
            CreateDiaryFeature()
        } withDependencies: {
            $0.runningRecordClient.saveRecord = { record in
                capturedRecord = record
            }
            $0.runningRecordClient.fetchData = { _, _ in [:] }
            $0.runningRecordClient.updateRecord = { _ in }
            $0.weatherClient.fetchWeather = { _, _ in baseWeather }
            $0.shoeClient.fetchAllShoes = { [shoe] }
            $0.dismiss = DismissEffect { }
        }
        store.exhaustivity = .off

        await store.send(.updateSelectedShoe(shoe))
        await store.send(.updateSelectedRunningStyle(.midfoot))
        await store.send(.weatherFetched(baseWeather))
        await store.send(.updateSkyCondition(.cloudy))
        await store.send(.updateWindLevel(.strong))
        await store.send(.updateFeelsLike(.hot))
        await store.send(.updateHumidityLevel(.humid))

        await store.send(.saveRecord)
        await store.skipReceivedActions()

        let saved = try? #require(capturedRecord)
        #expect(saved?.weather?.temperature == 18)
        #expect(saved?.weather?.humidity == 50)
        #expect(saved?.weather?.windSpeed == 1)
        #expect(saved?.weather?.skyCondition == .cloudy)
        #expect(saved?.weather?.windLevel == .strong)
        #expect(saved?.weather?.feelsLike == .hot)
        #expect(saved?.weather?.humidityLevel == .humid)
    }
}

@MainActor
@Suite("CreateDiaryFeature initial state")
struct CreateDiaryFeatureInitTests {

    @Test("init with existing weather populates classification fields")
    func init_existingWeather_populatesClassification() {
        let workout = makeWorkout()
        let weather = WeatherData(
            temperature: 5,
            humidity: 80,
            windSpeed: 6,
            skyCondition: .cloudy,
            windLevel: .strong,
            feelsLike: .cold,
            humidityLevel: .humid
        )
        let existing = Diary(
            workout: workout,
            runningStyle: .midfoot,
            weather: weather
        )

        let state = CreateDiaryFeature.State(
            existingRecord: existing,
            healthKitWorkout: workout
        )

        #expect(state.skyCondition == .cloudy)
        #expect(state.windLevel == .strong)
        #expect(state.feelsLike == .cold)
        #expect(state.humidityLevel == .humid)
    }

    @Test("init without existing record leaves classification nil")
    func init_noExistingRecord_classificationIsNil() {
        let state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())

        #expect(state.skyCondition == nil)
        #expect(state.windLevel == nil)
        #expect(state.feelsLike == nil)
        #expect(state.humidityLevel == nil)
        #expect(state.currentStep == .fitness)
    }
}

// MARK: - Step Properties

@Suite("CreateDiaryFeature.Step properties")
struct CreateDiaryFeatureStepPropertyTests {

    @Test("fitness.isFirst == true, 나머지는 false")
    func isFirst_onlyFitnessIsFirst() {
        #expect(CreateDiaryFeature.Step.fitness.isFirst == true)
        for step in CreateDiaryFeature.Step.allCases.dropFirst() {
            #expect(step.isFirst == false)
        }
    }

    @Test("memo.isLast == true, 나머지는 false")
    func isLast_onlyMemoIsLast() {
        #expect(CreateDiaryFeature.Step.memo.isLast == true)
        for step in CreateDiaryFeature.Step.allCases.dropLast() {
            #expect(step.isLast == false)
        }
    }

    @Test("fitness.previous == nil")
    func previous_fitnessHasNoPrevious() {
        #expect(CreateDiaryFeature.Step.fitness.previous == nil)
    }

    @Test("memo.next == nil")
    func next_memoHasNoNext() {
        #expect(CreateDiaryFeature.Step.memo.next == nil)
    }
}

// MARK: - isFormValid

@MainActor
@Suite("CreateDiaryFeature.isFormValid")
struct CreateDiaryFeatureFormValidTests {

    @Test("shoe·style·difficulty 모두 nil → false")
    func allNil_isInvalid() {
        let state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        #expect(state.isFormValid == false)
    }

    @Test("shoe만 설정, style·difficulty nil → false")
    func onlyShoe_isInvalid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) { $0.selectedShoe = makeShoe() }
        #expect(state.isFormValid == false)
    }

    @Test("shoe·style 설정, difficulty 명시적 nil → false")
    func shoeAndStyle_isInvalid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) {
            $0.selectedShoe = makeShoe()
            $0.selectedRunningStyle = .midfoot
            $0.selectedDifficultyLevel = nil  // 기본값 .medium을 명시적으로 nil로
        }
        #expect(state.isFormValid == false)
    }

    @Test("shoe·style·difficulty 모두 설정 → true")
    func allSet_isValid() {
        var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
        state = mutated(state) {
            $0.selectedShoe = makeShoe()
            $0.selectedRunningStyle = .midfoot
            $0.selectedDifficultyLevel = .medium
        }
        #expect(state.isFormValid == true)
    }

    private func mutated(
        _ state: CreateDiaryFeature.State,
        _ mutate: (inout CreateDiaryFeature.State) -> Void
    ) -> CreateDiaryFeature.State {
        var copy = state
        mutate(&copy)
        return copy
    }
}
