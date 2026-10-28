import Foundation

#if os(watchOS)
import WatchConnectivity

final class WatchActionStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var currentCategory: String = "无"
    @Published var quickActions: [String] = ["工作", "刚需", "生活", "监控"]
    @Published var isReachable: Bool = false
    
    private let sharedKey = "sharedCurrentState"
    
    override init() {
        super.init()
        loadFromAppGroup()
        activateSession()
    }
    
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        isReachable = session.isReachable
    }
    
    private func loadFromAppGroup() {
        guard let shared = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let data = shared.data(forKey: watchQuickActionsKey),
           let actions = try? JSONDecoder().decode([String].self, from: data),
           !actions.isEmpty {
            quickActions = actions
        }
        if let data = shared.data(forKey: sharedKey),
           let state = try? JSONDecoder().decode(CurrentState.self, from: data) {
            currentCategory = state.category
        }
    }
    
    func requestNextAction() {
        sendMessage(["action": "next"])
    }
    
    func requestSetAction(_ category: String) {
        sendMessage(["action": "set", "category": category])
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(message)
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isReachable = session.isReachable
        if let context = session.receivedApplicationContext as? [String: Any] {
            applyContext(context)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        isReachable = session.isReachable
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applyContext(applicationContext)
    }
    
    private func applyContext(_ context: [String: Any]) {
        if let actions = context["quickActions"] as? [String], !actions.isEmpty {
            DispatchQueue.main.async { self.quickActions = actions }
        }
        if let category = context["currentCategory"] as? String {
            DispatchQueue.main.async { self.currentCategory = category }
        }
    }
}
#endif
