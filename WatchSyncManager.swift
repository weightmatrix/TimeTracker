import Foundation
import Combine

#if os(iOS)
import WatchConnectivity

final class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncManager()
    
    private weak var timeStore: TimeStore?
    private weak var settingsStore: GlobalSettingsStore?
    private var isConfigured = false
    
    private override init() {
        super.init()
    }
    
    func configure(timeStore: TimeStore, settingsStore: GlobalSettingsStore) {
        guard !isConfigured else { return }
        self.timeStore = timeStore
        self.settingsStore = settingsStore
        isConfigured = true
        
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        pushCurrentStateToWatch()
    }
    
    func notifyStateChanged() {
        pushCurrentStateToWatch()
    }
    
    private func pushCurrentStateToWatch() {
        guard WCSession.default.activationState == .activated else { return }
        let current = timeStore?.currentRecord
        let quickActions = normalizedQuickActions()
        var payload: [String: Any] = ["quickActions": quickActions]
        if let current {
            payload["currentCategory"] = current.category
            payload["currentStartTime"] = current.startTime.timeIntervalSince1970
        }
        try? WCSession.default.updateApplicationContext(payload)
    }
    
    private func normalizedQuickActions() -> [String] {
        let fallback = ["工作", "刚需", "生活", "监控"]
        var actions = settingsStore?.config.watchQuickActions ?? fallback
        if actions.isEmpty { actions = fallback }
        var seen = Set<String>()
        actions = actions.filter { seen.insert($0).inserted }
        if actions.count < 4 {
            for item in fallback where actions.count < 4 && !actions.contains(item) {
                actions.append(item)
            }
        }
        if actions.count > 4 { actions = Array(actions.prefix(4)) }
        return actions
    }
    
    private func handleSetAction(_ category: String) {
        timeStore?.start(category: category)
        pushCurrentStateToWatch()
    }
    
    private func handleNextAction() {
        let actions = normalizedQuickActions()
        guard !actions.isEmpty else { return }
        let current = timeStore?.currentRecord?.category
        let next: String
        if let current, let idx = actions.firstIndex(of: current) {
            next = actions[(idx + 1) % actions.count]
        } else {
            next = actions[0]
        }
        handleSetAction(next)
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            pushCurrentStateToWatch()
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let action = message["action"] as? String {
            if action == "next" { DispatchQueue.main.async { self.handleNextAction() } }
            if action == "set", let category = message["category"] as? String {
                DispatchQueue.main.async { self.handleSetAction(category) }
            }
        }
    }
}
#endif
