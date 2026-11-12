import Foundation
import Security

private enum PushRelayKeychain {
    private static let service = "Han.TimeTracker.PushRelay"

    static func read(_ name: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    static func write(_ data: Data, name: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
        let update = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if update == errSecSuccess { return }
        guard update == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(update)) }
        var inserted = query
        inserted[kSecValueData as String] = data
        inserted[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let result = SecItemAdd(inserted as CFDictionary, nil)
        guard result == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
    }

    static func delete(_ name: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: name,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

actor PushRelayClient {
    static let shared = PushRelayClient()
    private let baseURL = URL(string: "https://zhibenwang.com/time-push/")!
    private var isFlushing = false
    private var lastAttempt = Date.distantPast

    private struct Enrollment: Decodable { let accountID: String; let credential: String }
    private struct PairCode: Decodable { let code: String; let expiresInSeconds: Int }
    private struct ActivityRegistration: Codable {
        let activityID: String
        let token: String
        let environment: String
    }

    func isPaired() -> Bool { PushRelayKeychain.read("credential") != nil }

    func enroll(code: String) async throws {
        guard let deviceID = TransitionOutbox.shared?.deviceID else { throw RelayError.noOutbox }
        let body = try JSONSerialization.data(withJSONObject: ["code": code, "deviceID": deviceID.uuidString])
        let data = try await send("v1/pair/redeem", method: "POST", body: body, authenticated: false)
        let enrollment = try JSONDecoder().decode(Enrollment.self, from: data)
        try PushRelayKeychain.write(Data(enrollment.credential.utf8), name: "credential")
        await flush()
        await sendPendingActivityToken()
    }

    func createPairingCode() async throws -> String {
        let data = try await send("v1/pair/create", method: "POST", body: Data("{}".utf8))
        return try JSONDecoder().decode(PairCode.self, from: data).code
    }

    func registerActivityToken(_ token: Data, activityID: String, environment: String) async {
        let registration = ActivityRegistration(activityID: activityID,
            token: token.map { String(format: "%02x", $0) }.joined(), environment: environment)
        do { try PushRelayKeychain.write(JSONEncoder().encode(registration), name: "pendingActivity") }
        catch { return }
        await sendPendingActivityToken()
    }

    func sendPendingActivityToken() async {
        guard let data = PushRelayKeychain.read("pendingActivity"), isPaired() else { return }
        do {
            _ = try await send("v1/activity-token", method: "PUT", body: data)
            if PushRelayKeychain.read("pendingActivity") == data { PushRelayKeychain.delete("pendingActivity") }
        }
        catch { return }
    }

    func flush() async {
        guard !isFlushing, isPaired(), let outbox = TransitionOutbox.shared,
              Date().timeIntervalSince(lastAttempt) >= 3 else { return }
        isFlushing = true
        lastAttempt = Date()
        defer { isFlushing = false }
        for event in outbox.pending() {
            do {
                _ = try await send("v1/transitions", method: "POST", body: JSONEncoder().encode(event))
                try outbox.acknowledge(event.id)
            } catch { return } // Preserve this event and all later ones for ordered retry.
        }
    }

    private func send(_ path: String, method: String, body: Data,
                      authenticated: Bool = true) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let credential = PushRelayKeychain.read("credential"),
                  let string = String(data: credential, encoding: .utf8) else { throw RelayError.notPaired }
            request.setValue("Bearer \(string)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RelayError.server((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    enum RelayError: LocalizedError {
        case noOutbox, notPaired, server(Int)
        var errorDescription: String? {
            switch self {
            case .noOutbox: return "本地切换事件队列不可用。"
            case .notPaired: return "请先配对设备。"
            case .server(let status): return "推送服务返回 HTTP \(status)。"
            }
        }
    }
}
