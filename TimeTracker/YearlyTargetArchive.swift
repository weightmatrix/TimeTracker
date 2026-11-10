import Foundation

nonisolated final class YearlyTargetArchive {
    let root: URL
    let backupRoot: URL
    init(root: URL, backupRoot: URL) { self.root = root; self.backupRoot = backupRoot }
    private struct Pending: Codable { let data: Data; let editedAt: Date }
    var pendingURL: URL { backupRoot.appendingPathComponent("PendingWeeklyTargets.json") }
    private var directory: URL { root.appendingPathComponent("weekly_targets", isDirectory: true) }
    private func files() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" && $0.deletingPathExtension().lastPathComponent.count == 4 }
    }
    private func migrate() throws {
        if !(try files()).isEmpty { return }
        for name in ["weekly_targets.json", "weekly_targets_v20.json"] {
            let legacy = root.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: legacy.path) else { continue }
            let old = try LatestCloudFile.read(legacy)
            let folder = backupRoot.appendingPathComponent("RecordMigration", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let backup = folder.appendingPathComponent("weekly-targets-\(CloudFileManagerHash(old.data)).json")
            if !FileManager.default.fileExists(atPath: backup.path) { try old.data.write(to: backup, options: .atomic) }
            try save(old.data, editedAt: old.modifiedAt)
            try FileManager.default.removeItem(at: legacy)
            return
        }
    }
    func load() throws -> Data? {
        try migrate()
        try retryPending()
        let sources = try files()
        guard !sources.isEmpty else { return nil }
        var result: [String: Any] = [:]
        for file in sources {
            let data = try LatestCloudFile.read(file).data
            guard let values = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
            result.merge(values) { _, latest in latest }
        }
        return try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
    }
    static func persistPending(_ data: Data, editedAt: Date, backupRoot: URL) throws {
        try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        let url = backupRoot.appendingPathComponent("PendingWeeklyTargets.json")
        if let previous = try? JSONDecoder().decode(Pending.self, from: Data(contentsOf: url)), previous.editedAt > editedAt { return }
        try JSONEncoder().encode(Pending(data: data, editedAt: editedAt)).write(to: url, options: .atomic)
    }
    func queueAndSave(_ data: Data, editedAt: Date) throws {
        try Self.persistPending(data, editedAt: editedAt, backupRoot: backupRoot)
        try migrate()
        try retryPending()
    }
    private func retryPending() throws {
        guard FileManager.default.fileExists(atPath: pendingURL.path) else { return }
        let pending = try JSONDecoder().decode(Pending.self, from: Data(contentsOf: pendingURL))
        try save(pending.data, editedAt: pending.editedAt)
        try FileManager.default.removeItem(at: pendingURL)
    }
    func save(_ data: Data, editedAt: Date) throws {
        guard let values = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw CocoaError(.fileReadCorruptFile) }
        var groups: [String: [String: Any]] = [:]
        for (key, value) in values {
            let year = String(key.prefix(4))
            guard year.count == 4, year.allSatisfy(\.isNumber), key.dropFirst(4).hasPrefix("-W") else { throw CocoaError(.fileReadCorruptFile) }
            groups[year, default: [:]][key] = value
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let years = Set(try files().map { $0.deletingPathExtension().lastPathComponent }).union(groups.keys)
        for year in years {
            let next = try JSONSerialization.data(withJSONObject: groups[year] ?? [:], options: [.sortedKeys])
            let url = directory.appendingPathComponent(year + ".json")
            if FileManager.default.fileExists(atPath: url.path), try LatestCloudFile.read(url).data == next { continue }
            _ = try LatestCloudFile.write(next, to: url, editedAt: editedAt)
        }
    }
}
