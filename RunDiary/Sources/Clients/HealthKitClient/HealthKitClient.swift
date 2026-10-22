//
//  HealthKitClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import ComposableArchitecture
import Foundation
import HealthKitService
import Models

@DependencyClient
struct HealthKitClient {
    var fetchRunningDataBetweenDates: @MainActor @Sendable (Date, Date) async throws -> [HealthKitWorkout]
}

extension HealthKitClient: DependencyKey {
    static let liveValue: HealthKitClient = .live()

    static func live(
        manager: HealthKitManagerProtocol = HealthKitManager()
    ) -> HealthKitClient {
        HealthKitClient { startDate, endDate in
            try await manager.fetchWeeklyRunningData(from: startDate, to: endDate)
        }
    }

    static let testValue = HealthKitClient(
        fetchRunningDataBetweenDates: unimplemented("\(Self.self).fetchRunningDataBetweenDates")
    )

    static let previewValue = HealthKitClient { _, _ in
        // Mock 주간 데이터 반환 (7일)
        (0..<7).map { index in
            // 일부 날짜는 데이터가 없도록 nil 반환
            let duration = Double.random(in: 1800...5400)
            let distance = Double.random(in: 3.0...10.0)
            let activeEnergyBurned = Double.random(in: 300...600)
            return index % 3 == 0 ? nil : HealthKitWorkout(
                distance: distance,
                duration: duration,
                averagePaceSecondsPerKm: PaceMapper.secondsPerKm(
                    fromDurationSec: duration,
                    distanceKm: distance
                ),
                averageHeartRate: Int.random(in: 140...170),
                averageCadence: Int.random(in: 170...185),
                activeEnergyBurned: activeEnergyBurned,
                totalEnergyBurned: activeEnergyBurned + Double.random(in: 60...120),
                elevationAscended: Double.random(in: 10...80),
                averageVerticalOscillation: Double.random(in: 7.0...9.0),
                averageGroundContactTime: Double.random(in: 230...260),
                averageStepLength: Double.random(in: 0.9...1.2),
                restingHeartRate: Double.random(in: 50...80),
                averagePower: Double.random(in: 200...400),
                averageStrideLength: Double.random(in: 0.9...1.2),
                heartRateRecoveryOneMinute: Double.random(in: 15...30),
                startDate: Calendar.current.date(byAdding: .second, value: Int(-duration), to: .now)!,
                endDate: .now
            )
        }.compactMap { $0 }
    }
}

extension DependencyValues {
    var healthKitClient: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}
