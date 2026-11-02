import Foundation
import SwiftData
import Testing

@testable import PersistencesService

/// 기존 테스트의 독립된 구형 @Model을 사용한다. 현재 모델로 만든 스토어를 재사용하지 않는다.
/// V2 필드 출처: 7ca9c792d989463cf9fd9d006ef2ed242fc807e8.
/// V3 필드 출처: e7e7289237d7b1d3ac964c643a9b54c60fa208d5.
/// 두 역사적 모델은 SwiftData 관계가 없으며 shoes와 routeData는 각각 문자열/바이트 속성이다.
@MainActor
struct LegacyDiskStoreCompatibilityTests {
    @Test("구형 V2·V3 디스크 저장소를 앱의 현재 마이그레이션 계획으로 열면 모든 기록과 필드가 보존된다", arguments: [2, 3])
    func legacy_store_reopen_preserves_all_fields(version: Int) throws {
        // Given — 구형 모델만 사용하는 별도 컨테이너를 해제한 다음 현재 모델로 연다.
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.store")
        let expectedCount = 2
        let expectedFieldCount = 30
        let expectedRelationshipCount = 0
        try writeLegacyStore(version: version, url: url)
        #expect(FileManager.default.fileExists(atPath: url.path))

        // When — 실제 DataModel과 동일한 모델/마이그레이션 계획, 경로만 테스트 전용.
        try autoreleasepool {
            let container = try makeCurrentContainer(url: url)
            let records = try container.mainContext.fetch(FetchDescriptor<RunningRecordPersistenceModel>())

            // Then — 완전한 값과 선택 값 nil을 가진 두 레코드의 30개 필드를 각각 확인한다.
            #expect(records.count == expectedCount)
            let full = try #require(records.first { $0.id == fullID })
            let sparse = try #require(records.first { $0.id == sparseID })
            expectFullRecord(full, hasWeather: version == 2)
            expectSparseRecord(sparse)
            let entity = try #require(container.schema.entities.first)
            #expect(entity.attributes.count == expectedFieldCount)
            #expect(entity.relationships.count == expectedRelationshipCount)
            try container.mainContext.save()
        }

        // 재오픈 후에도 중복 생성이나 기록 누락이 없어야 한다.
        try autoreleasepool {
            let reopened = try makeCurrentContainer(url: url)
            let records = try reopened.mainContext.fetch(FetchDescriptor<RunningRecordPersistenceModel>())
            #expect(records.count == expectedCount)
            expectFullRecord(try #require(records.first { $0.id == fullID }), hasWeather: version == 2)
            expectSparseRecord(try #require(records.first { $0.id == sparseID }))
        }
    }
}

private extension LegacyDiskStoreCompatibilityTests {
    var fullID: UUID { UUID(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")! }
    var sparseID: UUID { UUID(uuidString: "FEDCBA98-7654-3210-FEDC-BA9876543210")! }

    func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-disk-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func makeCurrentContainer(url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: RunningRecordPersistenceModel.self,
            migrationPlan: RunningRecordMigrationPlan.self,
            configurations: ModelConfiguration(url: url)
        )
    }

    func writeLegacyStore(version: Int, url: URL) throws {
        try autoreleasepool {
            if version == 2 {
                let container = try ModelContainer(
                    for: LegacySchemaV2.RunningRecordPersistenceModel.self,
                    configurations: ModelConfiguration(url: url)
                )
                container.mainContext.insert(makeV2Record())
                let sparse = LegacySchemaV2.RunningRecordPersistenceModel()
                sparse.id = sparseID
                sparse.date = Date(timeIntervalSince1970: 0)
                sparse.startTime = Date(timeIntervalSince1970: 1)
                sparse.endTime = Date(timeIntervalSince1970: 2)
                container.mainContext.insert(sparse)
                try container.mainContext.save()
            } else {
                let container = try ModelContainer(
                    for: LegacySchemaV3.RunningRecordPersistenceModel.self,
                    configurations: ModelConfiguration(url: url)
                )
                container.mainContext.insert(makeV3Record())
                let sparse = LegacySchemaV3.RunningRecordPersistenceModel()
                sparse.id = sparseID
                sparse.date = Date(timeIntervalSince1970: 0)
                sparse.startTime = Date(timeIntervalSince1970: 1)
                sparse.endTime = Date(timeIntervalSince1970: 2)
                container.mainContext.insert(sparse)
                try container.mainContext.save()
            }
        }
    }

    func makeV2Record() -> LegacySchemaV2.RunningRecordPersistenceModel {
        let record = LegacySchemaV2.RunningRecordPersistenceModel()
        record.id = UUID(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!
        record.date = Date(timeIntervalSince1970: 1_730_000_000.25)
        record.distance = 12.345
        record.duration = 4321.5
        record.averagePace = "5′ 49″"
        record.averageHeartRate = 151
        record.averageCadence = 173
        record.painAreasRawData = "[ \"left_knee\", \"unknown_future_area\" ]"
        record.runningStyleRaw = "unknown-future-style"
        record.memo = " 첫 줄 🏃\n두 번째 줄 café "
        record.shoes = "단종된 신발 원문  "
        record.temperature = -3.25
        record.humidity = 87
        record.windSpeed = 4.75
        record.skyConditionRaw = "legacy-sky"
        record.windLevelRaw = "legacy-wind"
        record.feelsLikeRaw = "legacy-feel"
        record.humidityLevelRaw = "legacy-humidity"
        record.difficultyLevelRaw = 4
        record.routeData = Data([0, 255, 128, 10, 13, 42])
        record.activeEnergyBurned = 612.75
        record.runningVerticalOscillation = 8.25
        record.runningGroundContactTime = 245.5
        record.walkingStepLength = 0.95
        record.restingHeartRate = 52.5
        record.runningPower = 287.25
        record.runningStrideLength = 1.15
        record.heartRateRecoveryOneMinute = 31.5
        record.startTime = Date(timeIntervalSince1970: 1_730_000_001.25)
        record.endTime = Date(timeIntervalSince1970: 1_730_004_322.75)
        return record
    }

    func makeV3Record() -> LegacySchemaV3.RunningRecordPersistenceModel {
        let record = LegacySchemaV3.RunningRecordPersistenceModel()
        record.id = UUID(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!
        record.date = Date(timeIntervalSince1970: 1_730_000_000.25)
        record.distance = 12.345
        record.duration = 4321.5
        record.averagePace = "5′ 49″"
        record.averageHeartRate = 151
        record.averageCadence = 173
        record.painAreasRawData = "[ \"left_knee\", \"unknown_future_area\" ]"
        record.runningStyleRaw = "unknown-future-style"
        record.memo = " 첫 줄 🏃\n두 번째 줄 café "
        record.shoes = "단종된 신발 원문  "
        record.temperature = -3.25
        record.humidity = 87
        record.windSpeed = 4.75
        record.difficultyLevelRaw = 4
        record.routeData = Data([0, 255, 128, 10, 13, 42])
        record.activeEnergyBurned = 612.75
        record.runningVerticalOscillation = 8.25
        record.runningGroundContactTime = 245.5
        record.walkingStepLength = 0.95
        record.restingHeartRate = 52.5
        record.runningPower = 287.25
        record.runningStrideLength = 1.15
        record.heartRateRecoveryOneMinute = 31.5
        record.startTime = Date(timeIntervalSince1970: 1_730_000_001.25)
        record.endTime = Date(timeIntervalSince1970: 1_730_004_322.75)
        return record
    }

    func expectFullRecord(_ record: RunningRecordPersistenceModel, hasWeather: Bool) {
        let expectedId = UUID(uuidString: "01234567-89AB-CDEF-0123-456789ABCDEF")!
        #expect(record.id == expectedId)
        let expectedDate = Date(timeIntervalSince1970: 1_730_000_000.25)
        #expect(record.date == expectedDate)
        let expectedDistance = 12.345
        #expect(record.distance == expectedDistance)
        let expectedDuration = 4321.5
        #expect(record.duration == expectedDuration)
        let expectedAveragePace = "5′ 49″"
        #expect(record.averagePace == expectedAveragePace)
        let expectedAverageHeartRate = 151
        #expect(record.averageHeartRate == expectedAverageHeartRate)
        let expectedAverageCadence = 173
        #expect(record.averageCadence == expectedAverageCadence)
        let expectedPainAreasRawData = "[ \"left_knee\", \"unknown_future_area\" ]"
        #expect(record.painAreasRawData == expectedPainAreasRawData)
        let expectedRunningStyleRaw = "unknown-future-style"
        #expect(record.runningStyleRaw == expectedRunningStyleRaw)
        let expectedMemo = " 첫 줄 🏃\n두 번째 줄 café "
        #expect(record.memo == expectedMemo)
        let expectedShoes = "단종된 신발 원문  "
        #expect(record.shoes == expectedShoes)
        let expectedTemperature = -3.25
        #expect(record.temperature == expectedTemperature)
        let expectedHumidity = 87
        #expect(record.humidity == expectedHumidity)
        let expectedWindSpeed = 4.75
        #expect(record.windSpeed == expectedWindSpeed)
        let expectedSkyConditionRaw: String? = hasWeather ? "legacy-sky" : nil
        #expect(record.skyConditionRaw == expectedSkyConditionRaw)
        let expectedWindLevelRaw: String? = hasWeather ? "legacy-wind" : nil
        #expect(record.windLevelRaw == expectedWindLevelRaw)
        let expectedFeelsLikeRaw: String? = hasWeather ? "legacy-feel" : nil
        #expect(record.feelsLikeRaw == expectedFeelsLikeRaw)
        let expectedHumidityLevelRaw: String? = hasWeather ? "legacy-humidity" : nil
        #expect(record.humidityLevelRaw == expectedHumidityLevelRaw)
        let expectedDifficultyLevelRaw = 4
        #expect(record.difficultyLevelRaw == expectedDifficultyLevelRaw)
        let expectedRouteData = Data([0, 255, 128, 10, 13, 42])
        #expect(record.routeData == expectedRouteData)
        let expectedActiveEnergyBurned = 612.75
        #expect(record.activeEnergyBurned == expectedActiveEnergyBurned)
        let expectedRunningVerticalOscillation = 8.25
        #expect(record.runningVerticalOscillation == expectedRunningVerticalOscillation)
        let expectedRunningGroundContactTime = 245.5
        #expect(record.runningGroundContactTime == expectedRunningGroundContactTime)
        let expectedWalkingStepLength = 0.95
        #expect(record.walkingStepLength == expectedWalkingStepLength)
        let expectedRestingHeartRate = 52.5
        #expect(record.restingHeartRate == expectedRestingHeartRate)
        let expectedRunningPower = 287.25
        #expect(record.runningPower == expectedRunningPower)
        let expectedRunningStrideLength = 1.15
        #expect(record.runningStrideLength == expectedRunningStrideLength)
        let expectedHeartRateRecoveryOneMinute = 31.5
        #expect(record.heartRateRecoveryOneMinute == expectedHeartRateRecoveryOneMinute)
        let expectedStartTime = Date(timeIntervalSince1970: 1_730_000_001.25)
        #expect(record.startTime == expectedStartTime)
        let expectedEndTime = Date(timeIntervalSince1970: 1_730_004_322.75)
        #expect(record.endTime == expectedEndTime)
    }

    func expectSparseRecord(_ record: RunningRecordPersistenceModel) {
        let expectedId = sparseID
        #expect(record.id == expectedId)
        let expectedDate = Date(timeIntervalSince1970: 0)
        #expect(record.date == expectedDate)
        let expectedDistance = 0.0
        #expect(record.distance == expectedDistance)
        let expectedDuration = 0.0
        #expect(record.duration == expectedDuration)
        let expectedAveragePace = ""
        #expect(record.averagePace == expectedAveragePace)
        let expectedAverageHeartRate = 0
        #expect(record.averageHeartRate == expectedAverageHeartRate)
        let expectedAverageCadence = 0
        #expect(record.averageCadence == expectedAverageCadence)
        #expect(record.painAreasRawData == nil)
        #expect(record.runningStyleRaw == nil)
        #expect(record.memo == nil)
        #expect(record.shoes == nil)
        #expect(record.temperature == nil)
        #expect(record.humidity == nil)
        #expect(record.windSpeed == nil)
        #expect(record.skyConditionRaw == nil)
        #expect(record.windLevelRaw == nil)
        #expect(record.feelsLikeRaw == nil)
        #expect(record.humidityLevelRaw == nil)
        #expect(record.difficultyLevelRaw == nil)
        #expect(record.routeData == nil)
        #expect(record.activeEnergyBurned == nil)
        #expect(record.runningVerticalOscillation == nil)
        #expect(record.runningGroundContactTime == nil)
        #expect(record.walkingStepLength == nil)
        #expect(record.restingHeartRate == nil)
        #expect(record.runningPower == nil)
        #expect(record.runningStrideLength == nil)
        #expect(record.heartRateRecoveryOneMinute == nil)
        let expectedStartTime = Date(timeIntervalSince1970: 1)
        #expect(record.startTime == expectedStartTime)
        let expectedEndTime = Date(timeIntervalSince1970: 2)
        #expect(record.endTime == expectedEndTime)
    }
}
