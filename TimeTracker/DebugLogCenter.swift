import Foundation

enum DebugLogCenter {
    private static let cloudLogKey = "debug_cloud_silent_log_v1"
    private static let maxEntries = 300

    static func appendCloud(_ message: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())

        var lines = (UserDefaults.standard.string(forKey: cloudLogKey) ?? "")
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        lines.append("[\(timestamp)] \(message)")
        if lines.count > maxEntries {
            lines.removeFirst(lines.count - maxEntries)
        }
        UserDefaults.standard.set(lines.joined(separator: "\n"), forKey: cloudLogKey)
    }
}
