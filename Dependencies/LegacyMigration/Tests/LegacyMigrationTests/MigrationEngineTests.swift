import Foundation
import Testing

@testable import LegacyMigration

@Suite("기존 기록 전송")
struct MigrationEngineTests {
    private func makeSnapshot() throws -> LegacyRecordSnapshot {
        let url = try #require(
            Bundle.module.url(forResource: "legacy-record", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(LegacyRecordSnapshot.self, from: Data(contentsOf: url))
    }

    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    private func makeEngine(_ server: TestServer, directory: URL, environment: String = "test") -> MigrationEngine {
        MigrationEngine(directory: directory, environment: environment, remote: server.remote)
    }

    @Test("원본 필드를 보존하고 GET 검증을 마친 기록만 완료한다")
    func snapshot_round_trip() async throws {
        let snapshot = try makeSnapshot()
        let raw = try snapshot.json()
        let expected = snapshot
        #expect(try JSONDecoder().decode(LegacyRecordSnapshot.self, from: Data(raw.utf8)) == expected)
        #expect(snapshot.memo!.count > 2000)
        #expect(snapshot.humidity == nil)
        #expect(snapshot.routeData == Data([1, 2, 3]))
        let server = TestServer()
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = makeEngine(server, directory: directory)
        let result = try await engine.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(result.completed == 1)
        #expect(await server.getCount == 1)
    }

    @Test("서버 저장 후 응답 확인에 실패해도 재시작하면 중복 없이 검증한다")
    func restart_after_lost_read() async throws {
        let snapshot = try makeSnapshot()
        let server = TestServer(failRead: true)
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = makeEngine(server, directory: directory)
        await #expect(throws: URLError.self) {
            try await engine.run(
                snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" },
                progress: { _ in })
        }
        let restarted = makeEngine(server, directory: directory)
        let result = try await restarted.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(result.completed == 1)
        #expect(await server.records.count == 1)
        let again = try await restarted.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(again.completed == 1)
        #expect(await server.putCount == 2)
    }

    @Test("완료 후 로컬 수정은 덮어쓰지 않고 충돌로 보고한다")
    func changed_local_record_conflicts() async throws {
        var snapshot = try makeSnapshot()
        let server = TestServer()
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = makeEngine(server, directory: directory)
        _ = try await engine.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        snapshot.memo = "다른 메모"
        let result = try await engine.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(result.failures == 1)
        #expect(result.completed == 0)
        #expect(await server.putCount == 1)
    }

    @Test("다른 계정과 환경은 완료 상태를 공유하지 않는다")
    func account_environment_isolation() async throws {
        let snapshot = try makeSnapshot()
        let server = TestServer()
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try await makeEngine(server, directory: directory).run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        await server.setAccount("b")
        _ = try await makeEngine(server, directory: directory).run(
            snapshots: [snapshot], expectedAccountID: "b", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        _ = try await makeEngine(server, directory: directory, environment: "another").run(
            snapshots: [snapshot], expectedAccountID: "b", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(await server.putCount == 3)
    }

    @Test("계정이 바뀌거나 로그아웃했으면 전송하지 않는다")
    func session_change_stops_upload() async throws {
        let snapshot = try makeSnapshot()
        let server = TestServer()
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = makeEngine(server, directory: directory)
        await #expect(throws: MigrationError.self) {
            try await engine.run(
                snapshots: [snapshot], expectedAccountID: "other", token: "token", currentToken: { "token" },
                progress: { _ in })
        }
        await #expect(throws: MigrationError.self) {
            try await engine.run(
                snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { nil }, progress: { _ in }
            )
        }
        #expect(await server.putCount == 0)
    }

    @Test("저장 직후 로그아웃하면 완료 처리하지 않고 다음 로그인에서 재검증한다")
    func logout_after_put_is_not_complete() async throws {
        let snapshot = try makeSnapshot()
        let token = TestToken()
        let server = TestServer()
        let remote = MigrationRemote(
            account: { _ in MigrationAccount(id: "a") },
            put: { id, raw, _ in
                let receipt = try await server.put(id, raw)
                token.clear()
                return receipt
            },
            get: { id, _ in try await server.get(id) }
        )
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = MigrationEngine(directory: directory, environment: "test", remote: remote)
        await #expect(throws: MigrationError.self) {
            try await engine.run(
                snapshots: [snapshot], expectedAccountID: "a", token: "token",
                currentToken: { token.read() }, progress: { _ in }
            )
        }
        #expect(await server.getCount == 0)
        let restarted = makeEngine(server, directory: directory)
        let result = try await restarted.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token",
            currentToken: { "token" }, progress: { _ in }
        )
        #expect(result.completed == 1)
        #expect(await server.records.count == 1)
    }

    @Test("서버 원문 불일치는 완료 처리하지 않는다")
    func mismatched_read_is_not_complete() async throws {
        let snapshot = try makeSnapshot()
        let server = TestServer(corruptRead: true)
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let engine = makeEngine(server, directory: directory)
        await #expect(throws: MigrationError.self) {
            try await engine.run(
                snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" },
                progress: { _ in })
        }
        await server.setCorruptRead(false)
        let result = try await engine.run(
            snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" }, progress: { _ in }
        )
        #expect(result.completed == 1)
        #expect(await server.putCount == 2)
    }

    @Test("손상된 전송 상태 파일은 초기화해서 무시하지 않는다")
    func corrupted_ledger_stops() async throws {
        let snapshot = try makeSnapshot()
        let server = TestServer()
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: directory.appendingPathComponent(ImportReceipt.hash("test|a") + ".json"))
        await #expect(throws: DecodingError.self) {
            try await makeEngine(server, directory: directory).run(
                snapshots: [snapshot], expectedAccountID: "a", token: "token", currentToken: { "token" },
                progress: { _ in })
        }
        #expect(await server.putCount == 0)
    }

    @Test(
        "Swift HTTP 클라이언트에서 실제 로컬 API까지 왕복한다",
        .enabled(if: ProcessInfo.processInfo.environment["RD_MIGRATION_INTEGRATION_URL"] != nil))
    func live_local_round_trip() async throws {
        let url = try #require(URL(string: ProcessInfo.processInfo.environment["RD_MIGRATION_INTEGRATION_URL"] ?? ""))
        let remote = MigrationRemote.live(baseURL: url)
        let account = try await remote.account("local-test-token")
        let snapshot = try makeSnapshot()
        let raw = try snapshot.json()
        let receipt = try await remote.put(snapshot.id, raw, "local-test-token")
        let read = try await remote.get(snapshot.id, "local-test-token")
        #expect(account.id == "integration-test")
        #expect(read.id == receipt.id)
        #expect(read.verifies(id: snapshot.id, raw: raw))
        let retry = try await remote.put(snapshot.id, raw, "local-test-token")
        #expect(retry.id == receipt.id)
    }
}

private final class TestToken: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String? = "token"
    func read() -> String? { lock.withLock { value } }
    func clear() { lock.withLock { value = nil } }
}

private actor TestServer {
    var accountID = "a"
    var records: [UUID: ImportReceipt] = [:]
    var putCount = 0
    var getCount = 0
    var failRead: Bool
    var corruptRead: Bool

    init(failRead: Bool = false, corruptRead: Bool = false) {
        self.failRead = failRead
        self.corruptRead = corruptRead
    }

    nonisolated var remote: MigrationRemote {
        MigrationRemote(
            account: { _ in await self.account() },
            put: { id, raw, _ in try await self.put(id, raw) },
            get: { id, _ in try await self.get(id) }
        )
    }
    func account() -> MigrationAccount { MigrationAccount(id: accountID) }
    func setAccount(_ id: String) { accountID = id }
    func setCorruptRead(_ value: Bool) { corruptRead = value }
    func put(_ id: UUID, _ raw: String) throws -> ImportReceipt {
        putCount += 1
        if let existing = records[id] {
            guard existing.snapshotJSON == raw else { throw MigrationError.conflict }
            return existing
        }
        let receipt = ImportReceipt(id: UUID().uuidString, recordId: id, snapshotJSON: raw)
        records[id] = receipt
        return receipt
    }
    func get(_ id: UUID) throws -> ImportReceipt {
        getCount += 1
        if failRead {
            failRead = false
            throw URLError(.networkConnectionLost)
        }
        if corruptRead { return ImportReceipt(id: records[id]!.id, recordId: id, snapshotJSON: "wrong") }
        return records[id]!
    }
}
