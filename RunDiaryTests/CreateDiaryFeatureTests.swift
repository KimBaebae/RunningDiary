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
            $0.currentStep = .shoes
        }
        await store.send(.nextStepTapped) {
            $0.currentStep = .runningStyle
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
            state.currentStep = .shoes
        }

        await store.send(.previousStepTapped) {
            $0.currentStep = .fitness
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature weather fetch")
struct CreateDiaryFeatureWeatherTests {

    @Test("weatherFetched stores the raw weather values into state")
    func weatherFetched_storesWeather() async {
        let store = makeStore()

        let fetched = WeatherData(
            temperature: 25,
            humidity: 80,
            windSpeed: 6,
            apparentTemperature: 28,
            cloudCover: 0.8,
            precipitationAmount: 1.2
        )

        await store.send(.weatherFetched(fetched)) {
            $0.weather = fetched
        }
    }
}

@MainActor
@Suite("CreateDiaryFeature save")
struct CreateDiaryFeatureSaveTests {

    @Test("saveRecord persists the fetched weather as-is")
    func saveRecord_persistsFetchedWeather() async {
        let workout = makeWorkout()

        let baseWeather = WeatherData(
            temperature: 18,
            humidity: 50,
            windSpeed: 1,
            apparentTemperature: 17,
            cloudCover: 0.3,
            precipitationAmount: 0
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

        await store.send(.saveRecord)
        await store.skipReceivedActions()

        let saved = try? #require(capturedRecord)
        #expect(saved?.weather == baseWeather)
    }
}

@MainActor
@Suite("CreateDiaryFeature initial state")
struct CreateDiaryFeatureInitTests {

    @Test("init with existing weather copies it into state as-is")
    func init_existingWeather_copiesWeather() {
        let workout = makeWorkout()
        let weather = WeatherData(
            temperature: 5,
            humidity: 80,
            windSpeed: 6,
            apparentTemperature: 2,
            cloudCover: 0.9,
            precipitationAmount: 3
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

        #expect(state.weather == weather)
    }

    @Test("init without existing record leaves weather nil")
    func init_noExistingRecord_weatherIsNil() {
        let state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())

        #expect(state.weather == nil)
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
