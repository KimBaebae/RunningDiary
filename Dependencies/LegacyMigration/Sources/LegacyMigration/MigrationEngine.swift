import Foundation

public struct MigrationProgress: Equatable, Sendable {
    public var completed: Int
    public var total: Int
    public var failures: Int
    public var message: String?
    public init(completed: Int = 0, total: Int = 0, failures: Int = 0, message: String? = nil) {
        self.completed = completed
        self.total = total
        self.failures = failures
        self.message = message
    }
}

/// SwiftData 밖의 원자적 파일에 최초 전송 원문과 검증 완료 상태를 보존한다.
public actor MigrationEngine {
    private struct Entry: Codable {
        var raw: String?
        var hash: String
        var verified: Bool
    }
    private struct Ledger: Codable {
        var accountID: String
        var environment: String
        var entries: [String: Entry]
    }
    private let directory: URL
    private let environment: String
    private let remote: MigrationRemote
    private var running = false

    /// 체크포인트 저장 위치와 서버 환경을 지정한다. 실행 시 인증된 계정별 파일로 분리한다.
    public init(directory: URL, environment: String, remote: MigrationRemote) {
        self.directory = directory
        self.environment = environment
        self.remote = remote
    }

    /// 준비한 스냅샷을 순차 전송하고 PUT 응답과 후속 GET 원문을 모두 검증한다.
    ///
    /// 같은 원문으로 검증 완료된 기록은 체크포인트에서 건너뛰며 로컬 원본은 수정하지 않는다.
    /// 원문 변경·409 충돌·전송 전 크기 초과는 실패 수에 포함하고 다음 기록을 처리한다.
    /// 취소, 토큰·계정 변경, 저장소 오류 및 그 밖의 전송·검증 오류는 throw하여 중단한다.
    /// 호출자는 최신 토큰을 제공해야 하며, 재시도 시 보존된 체크포인트를 사용한다.
    /// - Returns: 이미 검증된 기록을 포함한 완료 수와 처리한 기록별 실패 수.
    public func run(
        snapshots: [LegacyRecordSnapshot],
        expectedAccountID: String,
        token: String,
        currentToken: @escaping @Sendable () -> String?,
        progress: @escaping @Sendable (MigrationProgress) async -> Void
    ) async throws -> MigrationProgress {
        guard !running else { throw MigrationError.alreadyRunning }
        running = true
        defer { running = false }
        try checkSession(token, currentToken)
        let account = try await remote.account(token)
        guard account.id == expectedAccountID else { throw MigrationError.sessionChanged }
        let url = directory.appendingPathComponent(ImportReceipt.hash(environment + "|" + account.id) + ".json")
        var ledger = try load(url: url, accountID: account.id)
        var result = MigrationProgress(total: snapshots.count)
        for snapshot in snapshots {
            try checkSession(token, currentToken)
            let key = snapshot.id.uuidString
            let raw = try snapshot.json()
            if let existing = ledger.entries[key], existing.hash != ImportReceipt.hash(raw) {
                result.failures += 1
                result.message = MigrationError.conflict.localizedDescription
                await progress(result)
                continue
            }
            if ledger.entries[key]?.verified == true {
                result.completed += 1
                await progress(result)
                continue
            }
            if raw.utf8.count > 2 * 1024 * 1024 {
                result.failures += 1
                result.message = MigrationError.tooLarge.localizedDescription
                await progress(result)
                continue
            }
            ledger.entries[key] = Entry(raw: raw, hash: ImportReceipt.hash(raw), verified: false)
            try save(ledger, url: url)
            do {
                let receipt = try await remote.put(snapshot.id, raw, token)
                try checkSession(token, currentToken)
                guard receipt.verifies(id: snapshot.id, raw: raw) else { throw MigrationError.verificationFailed }
                let fetched = try await remote.get(snapshot.id, token)
                try checkSession(token, currentToken)
                guard fetched.id == receipt.id, fetched.verifies(id: snapshot.id, raw: raw) else {
                    throw MigrationError.verificationFailed
                }
                ledger.entries[key]?.verified = true
                ledger.entries[key]?.raw = nil
                try save(ledger, url: url)
                result.completed += 1
            } catch MigrationError.conflict {
                result.failures += 1
                result.message = MigrationError.conflict.localizedDescription
            }
            await progress(result)
        }
        return result
    }

    private func checkSession(_ token: String, _ currentToken: @Sendable () -> String?) throws {
        try Task.checkCancellation()
        guard !token.isEmpty, currentToken() == token else { throw MigrationError.sessionChanged }
    }

    private func load(url: URL, accountID: String) throws -> Ledger {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return Ledger(accountID: accountID, environment: environment, entries: [:])
        }
        let value = try JSONDecoder().decode(Ledger.self, from: Data(contentsOf: url))
        guard value.accountID == accountID, value.environment == environment else {
            throw MigrationError.verificationFailed
        }
        return value
    }

    private func save(_ ledger: Ledger, url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(ledger)
        #if os(iOS)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
            try data.write(to: url, options: .atomic)
        #endif
    }
}
