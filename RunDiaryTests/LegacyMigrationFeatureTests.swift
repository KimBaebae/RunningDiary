import ComposableArchitecture
import Foundation
import LegacyMigration
import PersistencesService
import SwiftData
import Testing

@testable import RunDiary

@MainActor
@Suite("기존 기록 전송 화면")
struct LegacyMigrationFeatureTests {
    @Test("계정과 기록 수를 확인한 뒤에만 전송을 시작한다")
    func confirmation_before_upload() async {
        let preparation = MigrationPreparation(accountID: "a", accountLabel: "테스트 계정", count: 2)
        let expected = MigrationProgress(completed: 2, total: 2)
        let store = makeTestStore(preparation: preparation, result: expected)
        await store.send(.migrationTapped) {
            $0.isPreparingMigration = true
        }
        await store.receive(\.migrationPrepared) {
            $0.isPreparingMigration = false
            $0.migrationPreparation = preparation
        }
        await store.send(.migrationConfirmed) {
            $0.migrationPreparation = nil
            $0.isMigrating = true
            $0.migrationProgress = MigrationProgress(total: 2)
        }
        await store.receive(\.migrationFinished) {
            $0.isMigrating = false
            $0.migrationProgress = expected
            $0.migrationMessage = "기록 2개를 서버에서 확인했어요. 기기의 원본은 유지돼요."
        }
    }

    @Test("확인을 취소하면 전송하지 않는다")
    func dismissed_confirmation_does_not_upload() async {
        let preparation = MigrationPreparation(accountID: "a", accountLabel: "테스트", count: 1)
        let store = makeTestStore(preparation: preparation, result: MigrationProgress())
        await store.send(.migrationTapped) { $0.isPreparingMigration = true }
        await store.receive(\.migrationPrepared) {
            $0.isPreparingMigration = false
            $0.migrationPreparation = preparation
        }
        await store.send(.migrationDismissed) { $0.migrationPreparation = nil }
        await store.send(.migrationConfirmed)
    }

    @Test("SwiftData 원본의 알 수 없는 값과 부분 날씨를 가공 없이 내보낸다")
    func persisted_raw_fields_are_preserved() throws {
        let model = makeModel()
        let container = try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        container.mainContext.insert(model)
        try container.mainContext.save()
        let fetched = try #require(
            ModelContext(container).fetch(FetchDescriptor<RunningRecordPersistenceModel>()).first)
        let snapshot = LegacyMigrationSession.snapshot(fetched)
        #expect(snapshot.id == model.id)
        #expect(snapshot.painAreasRawData == model.painAreasRawData)
        #expect(snapshot.memo == model.memo)
        #expect(snapshot.shoes == model.shoes)
        #expect(snapshot.humidity == nil)
        #expect(snapshot.temperature == model.temperature)
        #expect(snapshot.skyConditionRaw == model.skyConditionRaw)
        #expect(snapshot.runningStyleRaw == model.runningStyleRaw)
        #expect(snapshot.difficultyLevelRaw == 99)
        #expect(snapshot.routeData == Data([0, 1, 255]))
        #expect(snapshot.startTime == model.startTime.timeIntervalSince1970)
        #expect(snapshot.endTime == model.endTime.timeIntervalSince1970)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<RunningRecordPersistenceModel>()) == 1)
    }

    private func makeTestStore(
        preparation: MigrationPreparation, result: MigrationProgress
    ) -> TestStore<SettingsFeature.State, SettingsFeature.Action> {
        TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.legacyMigrationClient.prepare = { preparation }
            $0.legacyMigrationClient.run = { _ in result }
        }
    }

    private func makeModel() -> RunningRecordPersistenceModel {
        let date = Date(timeIntervalSince1970: 1_700_000_000.123456)
        let model = RunningRecordPersistenceModel(
            distance: 5.32, duration: 1800.5, averagePace: "5′38″",
            averageHeartRate: 145, averageCadence: 170, runningStyleRaw: "unknown",
            memo: String(repeating: "원본 ", count: 1000), shoes: "단종 신발",
            temperature: 18, humidity: nil, windSpeed: 2,
            skyConditionRaw: "legacy", difficultyLevelRaw: 99, routeData: Data([0, 1, 255]),
            startTime: date, endTime: date.addingTimeInterval(1801)
        )
        model.painAreasRawData = "[\"알 수 없는 통증\"]"
        return model
    }
}
