import Foundation

/// Immutable command files keep rapid extension taps from overwriting one another.
struct TimerActionCommand: Codable {
    let id: UUID
    let category: String
    let startTime: Date
}

enum TimerActionMailbox {
    @MainActor static var consumer: (() async -> Bool)?
    @MainActor static func processInApp() async -> Bool {
        // LiveActivityIntent runs in the app process; allow cold launch to register its store.
        for _ in 0..<30 {
            if let consumer { return await consumer() }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return false
    }
    static let changed = Notification.Name("TimerActionMailboxChanged")
    static let legacyKey = "pendingTimerAction_v1"
    static var directory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Han.TimeTracker")?
            .appendingPathComponent("TimerActions", isDirectory: true)
    }
    static func enqueue(category: String, at date: Date) throws {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let command = TimerActionCommand(id: UUID(), category: category, startTime: date)
        try JSONEncoder().encode(command).write(to: directory.appendingPathComponent(command.id.uuidString + ".json"), options: .atomic)
        NotificationCenter.default.post(name: changed, object: nil)
    }
    static func pending() -> [(URL, TimerActionCommand)] {
        guard let directory, let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        return files.filter { $0.pathExtension == "json" }.compactMap { url in
            guard let data = try? Data(contentsOf: url), let command = try? JSONDecoder().decode(TimerActionCommand.self, from: data) else { return nil }
            return (url, command)
        }.sorted { $0.1.startTime == $1.1.startTime ? $0.1.id.uuidString < $1.1.id.uuidString : $0.1.startTime < $1.1.startTime }
    }
}
