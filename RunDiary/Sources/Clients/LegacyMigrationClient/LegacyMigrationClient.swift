import ComposableArchitecture
import Foundation
import LegacyMigration
import PersistencesService
import SwiftData

struct MigrationPreparation: Equatable, Sendable {
    var accountID: String
    var accountLabel: String
    var count: Int
}

@DependencyClient
struct LegacyMigrationClient {
    var prepare: @MainActor @Sendable () async throws -> MigrationPreparation
    var run:
        @MainActor @Sendable (@escaping @Sendable (MigrationProgress) async -> Void) async throws -> MigrationProgress
}

extension LegacyMigrationClient: DependencyKey {
    static let liveValue = LegacyMigrationClient()
    static let testValue = LegacyMigrationClient()
    static let previewValue = LegacyMigrationClient(
        prepare: { MigrationPreparation(accountID: "preview", accountLabel: "미리보기 계정", count: 3) },
        run: { _ in MigrationProgress(completed: 3, total: 3) }
    )

    @MainActor
    static func live(modelContext: ModelContext, tokenClient: TokenClient) -> Self {
        let session = LegacyMigrationSession(modelContext: modelContext, tokenClient: tokenClient)
        return Self(prepare: { try await session.prepare() }, run: { try await session.run(progress: $0) })
    }
}

extension DependencyValues {
    var legacyMigrationClient: LegacyMigrationClient {
        get { self[LegacyMigrationClient.self] }
        set { self[LegacyMigrationClient.self] = newValue }
    }
}

@MainActor
final class LegacyMigrationSession {
    let modelContext: ModelContext
    let tokenClient: TokenClient
    var prepared: (snapshots: [LegacyRecordSnapshot], account: MigrationAccount, token: String)?
    var engine: MigrationEngine?

    init(modelContext: ModelContext, tokenClient: TokenClient) {
        self.modelContext = modelContext
        self.tokenClient = tokenClient
    }

    func prepare() async throws -> MigrationPreparation {
        prepared = nil
        guard let token = tokenClient.accessToken(), !token.isEmpty else { throw MigrationError.signedOut }
        guard let url = URL(string: AppConfig.baseURL),
            url.scheme == "https", url.host != nil,
            url.query == nil, url.fragment == nil,
            url.path.isEmpty || url.path == "/"
        else { throw MigrationError.invalidURL }
        let remote = MigrationRemote.live(baseURL: url)
        let account = try await remote.account(token)
        try Task.checkCancellation()
        guard tokenClient.accessToken() == token else { throw MigrationError.sessionChanged }
        let snapshots = try modelContext.fetch(
            FetchDescriptor<RunningRecordPersistenceModel>(sortBy: [SortDescriptor(\.date)])
        ).map(Self.snapshot)
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        ).appendingPathComponent("LegacyMigration", isDirectory: true)
        if engine == nil {
            engine = MigrationEngine(directory: directory, environment: url.absoluteString, remote: remote)
        }
        prepared = (snapshots, account, token)
        return MigrationPreparation(
            accountID: account.id, accountLabel: account.email ?? account.id, count: snapshots.count)
    }

    func run(progress: @escaping @Sendable (MigrationProgress) async -> Void) async throws -> MigrationProgress {
        guard let prepared, let engine else { throw MigrationError.sessionChanged }
        let result = try await engine.run(
            snapshots: prepared.snapshots, expectedAccountID: prepared.account.id,
            token: prepared.token, currentToken: tokenClient.accessToken, progress: progress
        )
        self.prepared = nil
        return result
    }

    static func snapshot(_ model: RunningRecordPersistenceModel) -> LegacyRecordSnapshot {
        LegacyRecordSnapshot(
            id: model.id,
            date: model.date.timeIntervalSince1970,
            distance: model.distance,
            duration: model.duration,
            averagePace: model.averagePace,
            averageHeartRate: model.averageHeartRate,
            averageCadence: model.averageCadence,
            painAreasRawData: model.painAreasRawData,
            runningStyleRaw: model.runningStyleRaw,
            memo: model.memo,
            shoes: model.shoes,
            temperature: model.temperature,
            humidity: model.humidity,
            windSpeed: model.windSpeed,
            skyConditionRaw: model.skyConditionRaw,
            windLevelRaw: model.windLevelRaw,
            feelsLikeRaw: model.feelsLikeRaw,
            humidityLevelRaw: model.humidityLevelRaw,
            difficultyLevelRaw: model.difficultyLevelRaw,
            routeData: model.routeData,
            activeEnergyBurned: model.activeEnergyBurned,
            runningVerticalOscillation: model.runningVerticalOscillation,
            runningGroundContactTime: model.runningGroundContactTime,
            walkingStepLength: model.walkingStepLength,
            restingHeartRate: model.restingHeartRate,
            runningPower: model.runningPower,
            runningStrideLength: model.runningStrideLength,
            heartRateRecoveryOneMinute: model.heartRateRecoveryOneMinute,
            startTime: model.startTime.timeIntervalSince1970,
            endTime: model.endTime.timeIntervalSince1970
        )
    }
}
