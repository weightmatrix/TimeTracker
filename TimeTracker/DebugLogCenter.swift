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

/// Writes startup timing on a background queue so a blocked main thread cannot hide the last event.
final class StartupDiagnostics: @unchecked Sendable {
    static let shared = StartupDiagnostics()

    private let startedAt = ProcessInfo.processInfo.systemUptime
    private let queue = DispatchQueue(label: "Han.TimeTracker.startup-diagnostics", qos: .utility)
    private var logHandle: FileHandle?
    private var heartbeat: DispatchSourceTimer?
    private var lastMainResponse = ProcessInfo.processInfo.systemUptime
    private var reportedMainStall = false

    private init() {}

    @discardableResult
    func begin(_ event: String) -> TimeInterval {
        let now = ProcessInfo.processInfo.systemUptime
        mark("BEGIN \(event)", at: now)
        return now
    }

    func end(_ event: String, since start: TimeInterval) {
        let now = ProcessInfo.processInfo.systemUptime
        mark(String(format: "END %@ duration=%.3fs", event, now - start), at: now)
    }

    func mark(_ event: String) {
        mark(event, at: ProcessInfo.processInfo.systemUptime)
    }

    private func mark(_ event: String, at now: TimeInterval) {
        guard now - startedAt < 600 else { return }
        queue.async { [self] in
            if logHandle == nil { openLog() }
            let line = String(format: "+%.3fs %@\n", now - startedAt, event)
            logHandle?.write(Data(line.utf8))
        }
    }

    func watchMainThread() {
        queue.async { [self] in
            guard heartbeat == nil else { return }
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 1, repeating: 1)
            timer.setEventHandler { [self] in
                let now = ProcessInfo.processInfo.systemUptime
                if now - lastMainResponse > 5, !reportedMainStall {
                    reportedMainStall = true
                    mark(String(format: "MAIN_THREAD_STALL over %.1fs", now - lastMainResponse), at: now)
                }
                DispatchQueue.main.async { [self] in
                    let recoveredAt = ProcessInfo.processInfo.systemUptime
                    queue.async { [self] in
                        if reportedMainStall { mark("MAIN_THREAD_RECOVERED", at: recoveredAt) }
                        lastMainResponse = recoveredAt
                        reportedMainStall = false
                    }
                }
                if now - startedAt >= 600 {
                    timer.cancel()
                    heartbeat = nil
                }
            }
            heartbeat = timer
            timer.resume()
        }
    }

    private func openLog() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = root.appendingPathComponent("李知本时间管理/Diagnostics", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("startup-\(ProcessInfo.processInfo.processIdentifier).log")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        logHandle = try? FileHandle(forWritingTo: url)
        print("[StartupDiagnostics] \(url.path)")
    }
}
