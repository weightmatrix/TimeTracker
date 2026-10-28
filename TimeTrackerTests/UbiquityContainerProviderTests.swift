import Foundation
import Testing
@testable import TimeTracker

final class InMemoryKeychain: KeychainStoring {
    private var storage: [String: String] = [:]

    func setString(_ value: String, forKey key: String) {
        storage[key] = value
    }

    func getString(forKey key: String) -> String? {
        storage[key]
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}

final class MockFileManager: UbiquityFileManaging {
    private(set) var callCount = 0
    var results: [URL?]

    init(results: [URL?]) {
        self.results = results
    }

    func url(forUbiquityContainerIdentifier containerIdentifier: String?) -> URL? {
        callCount += 1
        if results.isEmpty { return nil }
        return results.removeFirst()
    }
}

final class MockIdentityProvider: UbiquityIdentityProviding {
    var identityToken: (NSCoding & NSCopying & NSObjectProtocol)?
    init(token: (NSCoding & NSCopying & NSObjectProtocol)?) { self.identityToken = token }
}

final class FakeToken: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    let value: String

    init(value: String) { self.value = value }

    func encode(with coder: NSCoder) { coder.encode(value, forKey: "value") }
    required init?(coder: NSCoder) { value = coder.decodeObject(forKey: "value") as? String ?? "" }
}

struct UbiquityContainerProviderTests {
    @Test func resolvesAndCaches() async {
        let fm = MockFileManager(results: [URL(fileURLWithPath: "/tmp/icloud")])
        let keychain = InMemoryKeychain()
        let identity = MockIdentityProvider(token: FakeToken(value: "A"))
        let nc = NotificationCenter()
        var now = Date()

        let provider = DefaultUbiquityContainerProvider(
            fileManager: fm,
            identityProvider: identity,
            keychain: keychain,
            notificationCenter: nc,
            containerIdentifier: nil,
            now: { now },
            sleep: { _ in }
        )

        let first = await provider.resolveContainerURL()
        let second = await provider.resolveContainerURL()

        #expect(first?.path == "/tmp/icloud/Documents")
        #expect(second?.path == "/tmp/icloud/Documents")
        #expect(fm.callCount == 1)
        #expect(keychain.getString(forKey: "lastGoodContainerID") != nil)
    }

    @Test func retrySuccessAfterFailures() async {
        let fm = MockFileManager(results: [nil, nil, URL(fileURLWithPath: "/tmp/icloud")])
        let keychain = InMemoryKeychain()
        let identity = MockIdentityProvider(token: FakeToken(value: "B"))
        let nc = NotificationCenter()
        var sleepCalls = 0

        let provider = DefaultUbiquityContainerProvider(
            fileManager: fm,
            identityProvider: identity,
            keychain: keychain,
            notificationCenter: nc,
            containerIdentifier: nil,
            now: { Date() },
            sleep: { _ in sleepCalls += 1 }
        )

        let url = await provider.resolveContainerURL()
        #expect(url?.path == "/tmp/icloud/Documents")
        #expect(fm.callCount == 3)
        #expect(sleepCalls >= 2)
    }

    @Test func negativeCachePreventsHotLoop() async {
        let fm = MockFileManager(results: [nil, nil, nil])
        let keychain = InMemoryKeychain()
        let identity = MockIdentityProvider(token: FakeToken(value: "C"))
        let nc = NotificationCenter()
        var now = Date()

        let provider = DefaultUbiquityContainerProvider(
            fileManager: fm,
            identityProvider: identity,
            keychain: keychain,
            notificationCenter: nc,
            containerIdentifier: nil,
            now: { now },
            sleep: { _ in }
        )

        let first = await provider.resolveContainerURL()
        let second = await provider.resolveContainerURL()

        #expect(first == nil)
        #expect(second == nil)
        #expect(fm.callCount == 1)
    }

    @Test func identityChangeClearsCache() async {
        let fm = MockFileManager(results: [URL(fileURLWithPath: "/tmp/icloud")])
        let keychain = InMemoryKeychain()
        let identity = MockIdentityProvider(token: FakeToken(value: "D"))
        let nc = NotificationCenter()

        let provider = DefaultUbiquityContainerProvider(
            fileManager: fm,
            identityProvider: identity,
            keychain: keychain,
            notificationCenter: nc,
            containerIdentifier: nil,
            now: { Date() },
            sleep: { _ in }
        )

        _ = await provider.resolveContainerURL()
        #expect(keychain.getString(forKey: "lastGoodContainerID") != nil)

        nc.post(name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
        #expect(keychain.getString(forKey: "lastGoodContainerID") == nil)
    }
}
