//
//  PersistencesClientTestSupport.swift
//  RunDiaryTests
//

import Foundation
import Models
import PersistencesService
import Testing

@testable import RunDiary

// MARK: - Test Helpers

func makeTestYearMonthDay(year: Int = 2025, month: Int = 11, day: Int = 27) -> YearMonthDay {
    YearMonthDay(year: year, month: month, day: day)
}

func makeTestDate(year: Int = 2025, month: Int = 11, day: Int = 27, hour: Int = 9, minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)!
}

func makePersistencesTestClient(
    fetch: @escaping @MainActor @Sendable (Date) async throws -> Diary? = { _ in nil },
    fetchRecords: @escaping @MainActor @Sendable (Date, Date) async throws -> [Diary] = { _, _ in [] },
    save: @escaping @MainActor @Sendable (Diary) async throws -> Void = { _ in },
    update: @escaping @MainActor @Sendable (UUID, DiaryPatch) async throws -> Void = { _, _ in },
    delete: @escaping @MainActor @Sendable (Diary) async throws -> Void = { _ in }
) -> PersistencesClient {
    PersistencesClient(
        fetch: fetch,
        fetchRecords: fetchRecords,
        save: save,
        update: update,
        delete: delete
    )
}

// MARK: - 단일 동작만 스텁하는 헬퍼
//
// makePersistencesTestClient는 뒤에 기본값 파라미터가 남아
// trailing closure로 넘기면 마지막 인자(delete)에 잘못 매칭된다.
// 동작 하나만 검증하는 대다수 테스트는 아래 헬퍼로 trailing closure를 쓴다.

func makeFetchClient(
    _ fetch: @escaping @MainActor @Sendable (Date) async throws -> Diary?
) -> PersistencesClient {
    makePersistencesTestClient(fetch: fetch)
}

func makeFetchRecordsClient(
    _ fetchRecords: @escaping @MainActor @Sendable (Date, Date) async throws -> [Diary]
) -> PersistencesClient {
    makePersistencesTestClient(fetchRecords: fetchRecords)
}

func makeSaveClient(
    _ save: @escaping @MainActor @Sendable (Diary) async throws -> Void
) -> PersistencesClient {
    makePersistencesTestClient(save: save)
}

func makeUpdateClient(
    _ update: @escaping @MainActor @Sendable (UUID, DiaryPatch) async throws -> Void
) -> PersistencesClient {
    makePersistencesTestClient(update: update)
}

func makeDeleteClient(
    _ delete: @escaping @MainActor @Sendable (Diary) async throws -> Void
) -> PersistencesClient {
    makePersistencesTestClient(delete: delete)
}
