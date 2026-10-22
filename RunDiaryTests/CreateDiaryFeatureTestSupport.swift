//
//  CreateDiaryFeatureTestSupport.swift
//  RunDiaryTests
//

import ComposableArchitecture
import Foundation
import Models
import Testing

@testable import RunDiary

// MARK: - Helpers

@MainActor
func makeStore(
    mutate: ((inout CreateDiaryFeature.State) -> Void)? = nil
) -> TestStore<CreateDiaryFeature.State, CreateDiaryFeature.Action> {
    var state = CreateDiaryFeature.State(healthKitWorkout: makeWorkout())
    mutate?(&state)
    return TestStore(initialState: state) {
        CreateDiaryFeature()
    } withDependencies: {
        $0.runningRecordClient.saveRecord = { _ in }
        $0.runningRecordClient.updateRecord = { _ in }
        $0.runningRecordClient.fetchData = { _, _ in [:] }
        $0.weatherClient.fetchWeather = { _, _ in
            WeatherData(temperature: 20, humidity: 50, windSpeed: 1)
        }
        $0.shoeClient.fetchAllShoes = { [] }
    }
}

func makeShoe(
    id: String = "test-shoe-id",
    brandName: String = "TestBrand",
    name: String = "Test Shoe"
) -> Shoe {
    Shoe(
        id: id,
        brandName: brandName,
        name: name,
        nameKo: name,
        category: [:],
        subcategory: [:],
        tags: [],
        imageUrl: nil,
        reviewSummary: nil,
        pros: [],
        cons: [],
        description: nil
    )
}

func makeWorkout() -> HealthKitWorkout {
    HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePaceSecondsPerKm: 360,
        averageHeartRate: 150,
        averageCadence: 170,
        activeEnergyBurned: 350,
        averageVerticalOscillation: 8,
        averageGroundContactTime: 240,
        averageStepLength: 1,
        restingHeartRate: 60,
        averagePower: 300,
        averageStrideLength: 1,
        heartRateRecoveryOneMinute: 20,
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1800)
    )
}

func makeWorkoutWithRoute(route: [RoutePoint]) -> HealthKitWorkout {
    HealthKitWorkout(
        distance: 5.0,
        duration: 1800,
        averagePaceSecondsPerKm: 360,
        averageHeartRate: 150,
        averageCadence: 170,
        activeEnergyBurned: 350,
        averageVerticalOscillation: 8,
        averageGroundContactTime: 240,
        averageStepLength: 1,
        restingHeartRate: 60,
        averagePower: 300,
        averageStrideLength: 1,
        heartRateRecoveryOneMinute: 20,
        route: route,
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1800)
    )
}
