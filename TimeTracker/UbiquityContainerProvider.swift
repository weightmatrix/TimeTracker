import Foundation
import Security

// MARK: - Ubiquity Container Provider

protocol UbiquityContainerProviding {
    func resolveContainerURL() async -> URL?
    func currentCachedURL() -> URL?
    func clearCache(reason: String)
}

protocol UbiquityIdentityProviding {
    var identityToken: (NSCoding & NSCopying & NSObjectProtocol)? { get }
}

protocol UbiquityFileManaging {
    func url(forUbiquityContainerIdentifier containerIdentifier: String?) -> URL?
}

protocol KeychainStoring {
    func setString(_ value: String, forKey key: String)
    func getString(forKey key: String) -> String?
    func removeValue(forKey key: String)
}

final class DefaultUbiquityContainerProvider: UbiquityContainerProviding {
    static let shared = DefaultUbiquityContainerProvider(
        fileManager: FileManager.default,
        identityProvider: FileManager.default,
        keychain: KeychainStore(service: "TimeTracker.UbiquityContainer"),
        notificationCenter: .default,
        containerIdentifier: nil
    )

    private let fileManager: UbiquityFileManaging
    private let identityProvider: UbiquityIdentityProviding
    private let keychain: KeychainStoring
    private let notificationCenter: NotificationCenter
    private let containerIdentifier: String?

    private let cacheTTL: TimeInterval = 600
    private let negativeCacheTTL: TimeInterval = 20
    private let maxAttempts: Int = 5
    private let backoffBase: TimeInterval = 0.2

    private var cachedURL: URL?
    private var cachedAt: Date?
    private var negativeCachedAt: Date?
    private var lastIdentityFingerprint: String?

    private let now: () -> Date
    private let sleep: (TimeInterval) async -> Void

    init(
        fileManager: UbiquityFileManaging,
        identityProvider: UbiquityIdentityProviding,
        keychain: KeychainStoring,
        notificationCenter: NotificationCenter,
        containerIdentifier: String?,
        now: @escaping () -> Date = { Date() },
        sleep: @escaping (TimeInterval) async -> Void = { try? await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) }
    ) {
        self.fileManager = fileManager
        self.identityProvider = identityProvider
        self.keychain = keychain
        self.notificationCenter = notificationCenter
        self.containerIdentifier = containerIdentifier
        self.now = now
        self.sleep = sleep

        notificationCenter.addObserver(
            self,
            selector: #selector(handleIdentityChanged),
            name: NSNotification.Name.NSUbiquityIdentityDidChange,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func currentCachedURL() -> URL? {
        if let url = cachedURL, let cachedAt, now().timeIntervalSince(cachedAt) <= cacheTTL {
            return url
        }
        return nil
    }

    func clearCache(reason: String) {
        cachedURL = nil
        cachedAt = nil
        negativeCachedAt = nil
        lastIdentityFingerprint = nil
        keychain.removeValue(forKey: KeychainKeys.lastGoodContainerID)
        keychain.removeValue(forKey: KeychainKeys.lastIdentityFingerprint)
        DebugLogCenter.appendCloud("UbiquityContainerProvider 缓存已清理。原因: \(reason)")
        Telemetry.log(TelemetryEvents.icloudIdentityChanged(reason: reason))
    }

    @objc private func handleIdentityChanged() {
        clearCache(reason: "NSUbiquityIdentityDidChange")
    }

    func resolveContainerURL() async -> URL? {
        if let cached = currentCachedURL() { return cached }
        if let negativeCachedAt, now().timeIntervalSince(negativeCachedAt) <= negativeCacheTTL { return nil }

        let identityFingerprint = makeIdentityFingerprint(identityProvider.identityToken)
        lastIdentityFingerprint = identityFingerprint

        var attempt = 0
        var delay: TimeInterval = backoffBase
        while attempt < maxAttempts {
            if let url = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier)?.appendingPathComponent("Documents") {
                cachedURL = url
                cachedAt = now()
                negativeCachedAt = nil
                persistLastGoodContainer(identityFingerprint: identityFingerprint)
                Telemetry.log(TelemetryEvents.icloudContainerResolve(attempt: attempt + 1, success: true, containerId: containerIdentifier ?? "_default"))
                return url
            }
            Telemetry.log(TelemetryEvents.icloudContainerResolve(attempt: attempt + 1, success: false, containerId: containerIdentifier ?? "_default"))
            attempt += 1
            await sleep(delay)
            delay *= 2
        }

        // Fallback using last-good container id if identity is unchanged
        if let fallback = fallbackContainerURL(expectedIdentityFingerprint: identityFingerprint) {
            cachedURL = fallback
            cachedAt = now()
            negativeCachedAt = nil
            return fallback
        }

        negativeCachedAt = now()
        return nil
    }

    private func fallbackContainerURL(expectedIdentityFingerprint: String?) -> URL? {
        guard let expectedIdentityFingerprint else { return nil }
        guard let storedFingerprint = keychain.getString(forKey: KeychainKeys.lastIdentityFingerprint) else { return nil }
        guard storedFingerprint == expectedIdentityFingerprint else { return nil }

        guard let storedID = keychain.getString(forKey: KeychainKeys.lastGoodContainerID) else { return nil }
        let containerID = storedID == KeychainKeys.defaultContainerID ? nil : storedID
        return fileManager.url(forUbiquityContainerIdentifier: containerID)?.appendingPathComponent("Documents")
    }

    private func persistLastGoodContainer(identityFingerprint: String?) {
        let storedID = containerIdentifier ?? KeychainKeys.defaultContainerID
        keychain.setString(storedID, forKey: KeychainKeys.lastGoodContainerID)
        if let identityFingerprint {
            keychain.setString(identityFingerprint, forKey: KeychainKeys.lastIdentityFingerprint)
        }
    }

    private func makeIdentityFingerprint(_ token: (NSCoding & NSCopying & NSObjectProtocol)?) -> String? {
        guard let token else { return nil }
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) {
            return data.base64EncodedString()
        }
        return String(describing: token)
    }

    private enum KeychainKeys {
        static let lastGoodContainerID = "lastGoodContainerID"
        static let lastIdentityFingerprint = "lastIdentityFingerprint"
        static let defaultContainerID = "_default"
    }
}

extension FileManager: UbiquityIdentityProviding {
    var identityToken: (NSCoding & NSCopying & NSObjectProtocol)? { ubiquityIdentityToken }
}

extension FileManager: UbiquityFileManaging { }

// MARK: - Keychain

final class KeychainStore: KeychainStoring {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func setString(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        let insert: [String: Any] = query.merging([kSecValueData as String: data]) { $1 }
        SecItemAdd(insert as CFDictionary, nil)
    }

    func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func removeValue(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
