//
//  RunDiaryApp.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import LegacyMigration
import Models
import PersistencesService
import SwiftData
import SwiftUI
#if DEBUG
import SecureStorage
#endif

@main
struct RunDiaryApp: App {
    let modelContainer: ModelContainer
    let store: StoreOf<AppFeature>

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--ui-testing")
        #else
        let isUITesting = false
        #endif
        let container: ModelContainer
        if isUITesting {
            container = try! ModelContainer(
                for: RunningRecordPersistenceModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } else {
            container = DataModel.shared.container
        }
        self.modelContainer = container
        self.store = Store(initialState: AppFeature.State()) {
            AppFeature()
                ._printChanges()
        } withDependencies: {
            $0.persistencesClient = .live(modelContext: container.mainContext)
            // Do not construct live services only to discard them for UI fixtures.
            // Replacing the actor-isolated migration session during dependency
            // setup crashes in the deinit back-deployment runtime on iOS 26.2.
            if !isUITesting {
                $0.healthKitClient = .liveValue
                $0.authClient = .liveValue
                $0.tokenClient = .liveValue
                $0.legacyMigrationClient = .live(
                    modelContext: container.mainContext,
                    tokenClient: .liveValue
                )
            }
            #if DEBUG
            if isUITesting {
                let loggedOut = arguments.contains("--ui-login")
                let workout = HealthKitWorkout(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    distance: 5, duration: 1800, averagePaceSecondsPerKm: 360,
                    averageHeartRate: 145, averageCadence: 170,
                    activeEnergyBurned: 300, averageVerticalOscillation: 8,
                    averageGroundContactTime: 240, averageStepLength: 1,
                    restingHeartRate: 60, averagePower: 240, averageStrideLength: 1.2,
                    heartRateRecoveryOneMinute: 20,
                    startDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600),
                    endDate: Calendar.current.startOfDay(for: Date()).addingTimeInterval(5400)
                )
                $0.authClient = .previewValue
                $0.weatherClient = .previewValue
                $0.shoeClient = ShoeClient { [Shoe(
                    id: "ui-test-shoe", brandName: "테스트", name: "Test Shoe", nameKo: "테스트 러닝화",
                    category: [:], subcategory: [:], tags: [], imageUrl: nil,
                    reviewSummary: nil, pros: [], cons: [], description: nil
                )] }
                let tokenStorage = InMemorySecureStorage()
                if !loggedOut { try! tokenStorage.save("ui-test-access-token", for: .accessToken) }
                $0.tokenClient = .live(storage: tokenStorage)
                $0.healthKitClient = HealthKitClient { from, to in
                    arguments.contains("--ui-record") && workout.startTime >= from && workout.startTime <= to
                        ? [workout] : []
                }
                let migration = UITestMigrationScenario(
                    failFirst: arguments.contains("--ui-migration-failure"),
                    slow: arguments.contains("--ui-migration-slow")
                )
                $0.legacyMigrationClient = LegacyMigrationClient(
                    prepare: { MigrationPreparation(accountID: "ui-test", accountLabel: "화면 테스트 계정", count: 3) },
                    run: { try await migration.run(progress: $0) }
                )
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .modelContainer(modelContainer)
        }
    }
}

#if DEBUG
/// UI navigation fixture: no remote request or disk checkpoint is made.
@MainActor
private final class UITestMigrationScenario {
    var attempt = 0
    let failFirst: Bool
    let slow: Bool

    init(failFirst: Bool, slow: Bool) {
        self.failFirst = failFirst
        self.slow = slow
    }

    func run(progress: @escaping @Sendable (MigrationProgress) async -> Void) async throws -> MigrationProgress {
        attempt += 1
        await progress(MigrationProgress(completed: 1, total: 3))
        if slow { try await Task.sleep(for: .seconds(30)) }
        if failFirst && attempt == 1 {
            throw NSError(domain: "UITestMigration", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "테스트 연결이 끊겼어요. 다시 시도해 주세요."
            ])
        }
        try Task.checkCancellation()
        return MigrationProgress(completed: 3, total: 3)
    }
}
#endif
