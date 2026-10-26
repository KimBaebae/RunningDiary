//
//  PersistencesClient.swift
//  RunDiary
//
//  Created by Claude on 10/19/25.
//

import Dependencies
import DependenciesMacros
import Foundation
import Models
import PersistencesService
import SwiftData

@DependencyClient
struct PersistencesClient {
    var fetch: @MainActor @Sendable (Date) async throws -> Diary?
    var fetchRecords: @MainActor @Sendable (Date, Date) async throws -> [Diary]
    var save: @MainActor @Sendable (Diary) async throws -> Void
    var update: @MainActor @Sendable (_ recordId: UUID, _ patch: DiaryPatch) async throws -> Void
    var delete: @MainActor @Sendable (Diary) async throws -> Void
}

extension PersistencesClient {
    /// 변경할 필드만 담은 patch로 기록을 갱신한다.
    func updateRecord(recordId: UUID, patch: DiaryPatch) async throws {
        try await self.update(recordId, patch)
    }
}

extension PersistencesClient {
    static func live(modelContext: ModelContext) -> PersistencesClient {
        let repository = LivePersistencesRepository(modelContext: modelContext)

        return PersistencesClient(
            fetch: { date in
                let shoeResolver = await ShoeCache.shared.makeShoeResolver()
                return try await repository.fetchRunningRecord(for: date, shoeResolver: shoeResolver)
            },
            fetchRecords: { startDate, endDate in
                let shoeResolver = await ShoeCache.shared.makeShoeResolver()
                return try await repository.fetchRunningRecords(
                    from: startDate,
                    to: endDate,
                    shoeResolver: shoeResolver
                )
            },
            save: { record in
                try await repository.saveRunningRecord(record)
            },
            update: { recordId, patch in
                try await repository.updateRunningRecord(recordId: recordId, patch: patch)
            },
            delete: { record in
                try await repository.deleteRunningRecord(record)
            }
        )
    }
}

extension PersistencesClient: DependencyKey {
    static let liveValue: PersistencesClient = PersistencesClient(
        fetch: { _ in
            fatalError("RepositoryClient.fetch must be overridden with live implementation")
        },
        fetchRecords: { _, _ in
            fatalError("RepositoryClient.fetchRecords must be overridden with live implementation")
        },
        save: { _ in
            fatalError("RepositoryClient.save must be overridden with live implementation")
        },
        update: { _, _ in
            fatalError("RepositoryClient.update must be overridden with live implementation")
        },
        delete: { _ in
            fatalError("RepositoryClient.delete must be overridden with live implementation")
        }
    )

    static let testValue = PersistencesClient(
        fetch: unimplemented("\(Self.self).fetch"),
        fetchRecords: unimplemented("\(Self.self).fetchRecords"),
        save: unimplemented("\(Self.self).save"),
        update: unimplemented("\(Self.self).update"),
        delete: unimplemented("\(Self.self).delete")
    )

    static let previewValue = PersistencesClient(
        fetch: { date in
            // RunningRecordModel.previewRecords에서 날짜가 일치하는 레코드 찾기
            let calendar = Calendar.current
            let shoeResolver = await ShoeCache.shared.makeShoeResolver()
            return RunningRecordPersistenceModel.previewRecords
                .first { calendar.isDate($0.date, inSameDayAs: date) }?
                .toDomain(shoeResolver: shoeResolver)
        },
        fetchRecords: { startDate, endDate in
            // 날짜 범위에 맞는 레코드들 반환
            let shoeResolver = await ShoeCache.shared.makeShoeResolver()
            return RunningRecordPersistenceModel.previewRecords
                .filter { $0.date >= startDate && $0.date <= endDate }
                .map { $0.toDomain(shoeResolver: shoeResolver) }
        },
        save: { _ in },
        update: { _, _ in },
        delete: { _ in }
    )
}

extension DependencyValues {
    var persistencesClient: PersistencesClient {
        get { self[PersistencesClient.self] }
        set { self[PersistencesClient.self] = newValue }
    }
}
