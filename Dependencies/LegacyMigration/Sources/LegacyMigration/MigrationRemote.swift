import CryptoKit
import Foundation

public enum MigrationError: Error, LocalizedError, Sendable {
    case signedOut, sessionChanged, alreadyRunning, unavailable, conflict, verificationFailed, invalidURL, tooLarge
    case server(Int)

    public var errorDescription: String? {
        switch self {
        case .signedOut: "로그인 후 다시 시도해 주세요."
        case .sessionChanged: "로그인 정보가 바뀌어 전송을 중단했어요. 다시 확인해 주세요."
        case .alreadyRunning: "기록을 전송하고 있어요."
        case .unavailable: "서버에서 기존 기록 가져오기를 아직 지원하지 않아요."
        case .conflict: "이미 보낸 기록과 내용이 달라요. 원본은 기기에 그대로 남아 있어요."
        case .verificationFailed: "서버에 저장된 기록을 확인하지 못했어요. 다시 시도해 주세요."
        case .invalidURL: "서버 주소를 확인할 수 없어요."
        case .tooLarge: "이 기록은 전송 가능한 크기를 초과해요. 원본은 기기에 남아 있어요."
        case .server(let code): "전송을 완료하지 못했어요. 다시 시도해 주세요. (\(code))"
        }
    }
}

public struct MigrationAccount: Codable, Equatable, Sendable {
    public let id: String
    public let email: String?
    public init(id: String, email: String? = nil) {
        self.id = id
        self.email = email
    }
}

public struct ImportReceipt: Codable, Sendable {
    public let id: String
    public let recordId: UUID
    public let status: String
    public let snapshotJSON: String
    public let sha256: String

    public init(id: String, recordId: UUID, status: String = "ready", snapshotJSON: String) {
        self.id = id
        self.recordId = recordId
        self.status = status
        self.snapshotJSON = snapshotJSON
        self.sha256 = Self.hash(snapshotJSON)
    }

    public static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    public func verifies(id: UUID, raw: String) -> Bool {
        recordId == id && status == "ready" && snapshotJSON == raw && sha256 == Self.hash(raw)
    }
}

public struct MigrationRemote: Sendable {
    public var account: @Sendable (String) async throws -> MigrationAccount
    public var put: @Sendable (UUID, String, String) async throws -> ImportReceipt
    public var get: @Sendable (UUID, String) async throws -> ImportReceipt

    public init(
        account: @escaping @Sendable (String) async throws -> MigrationAccount,
        put: @escaping @Sendable (UUID, String, String) async throws -> ImportReceipt,
        get: @escaping @Sendable (UUID, String) async throws -> ImportReceipt
    ) {
        self.account = account
        self.put = put
        self.get = get
    }

    public static func live(baseURL: URL, session: URLSession = .shared) -> Self {
        let http = MigrationHTTP(baseURL: baseURL, session: session)
        return Self(
            account: { try await http.request(path: "api/v1/auth/me", token: $0) },
            put: { id, raw, token in
                let body = try JSONEncoder().encode(ImportBody(schemaVersion: 1, snapshotJSON: raw))
                return try await http.request(
                    path: "api/v1/running-logs/legacy-imports/\(id.uuidString)", token: token, body: body)
            },
            get: { id, token in
                try await http.request(path: "api/v1/running-logs/legacy-imports/\(id.uuidString)", token: token)
            }
        )
    }
}

private struct ImportBody: Encodable {
    let schemaVersion: Int
    let snapshotJSON: String
}

private struct MigrationHTTP: Sendable {
    let baseURL: URL
    let session: URLSession

    func request<T: Decodable & Sendable>(path: String, token: String, body: Data? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = body == nil ? "GET" : "PUT"
        request.httpBody = body
        request.timeoutInterval = 60
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw MigrationError.verificationFailed }
        switch response.statusCode {
        case 200..<300: return try JSONDecoder().decode(T.self, from: data)
        case 401, 403: throw MigrationError.signedOut
        case 404: throw MigrationError.unavailable
        case 409: throw MigrationError.conflict
        case 413: throw MigrationError.tooLarge
        default: throw MigrationError.server(response.statusCode)
        }
    }
}
