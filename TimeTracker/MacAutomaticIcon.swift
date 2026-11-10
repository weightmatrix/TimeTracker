#if os(macOS)
import AppKit

/// Uses system appearance rather than the app's deliberately dark window theme.
@MainActor
final class MacAutomaticIcon {
    static let shared = MacAutomaticIcon()
    private var appearanceObserver: NSObjectProtocol?
    private var activationObserver: NSObjectProtocol?

    func start() {
        guard appearanceObserver == nil else { return }
        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    func refresh() {
        let style = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleInterfaceStyle"] as? String
        let name = style == "Dark" ? "TimeIconNight" : "TimeIconDay"
        guard let image = NSImage(named: NSImage.Name(name)) else { return }
        NSApplication.shared.applicationIconImage = image
    }
}
#endif
