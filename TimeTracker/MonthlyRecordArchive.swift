import Foundation

/// current.json is the only commit point. Immutable month payloads make partially
/// delivered iCloud transactions unreadable rather than mixing two generations.
nonisolated final class MonthlyRecordArchive {
    struct Head: Codable, Sendable {
        var schema = 1
        var savedAt: Date
        var current: TimeRecord?
        var months: [String: String]
    }
    struct Loaded: Sendable {
        let records: [TimeRecord]
        let months: Set<String>
        let headData: Data
        let editedAt: Date
    }
    let root: URL
    let backupRoot: URL
    private var cache: [String: [TimeRecord]] = [:]
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]; return e
    }()
    init(root: URL, backupRoot: URL) { self.root = root; self.backupRoot = backupRoot }
    var headURL: URL { root.appendingPathComponent("current.json") }
    private var revisions: URL { root.appendingPathComponent("records/revisions", isDirectory: true) }
    static func month(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year!, c.month!)
    }
    static func homeMonths(now: Date = Date()) -> Set<String> {
        [month(now), month(Calendar.current.date(byAdding: .month, value: -1, to: now)!)]
    }
    static func normalize(_ records: [TimeRecord], now: Date) -> (valid: [TimeRecord], rejected: [TimeRecord]) {
        RecordTimeDiagnostics.shared.capture(records, phase: "archive.normalize", now: now)
        return RecordIntegrity.sanitize(records, now: now)
    }
    static func mergingHistory(_ archived: [TimeRecord], with local: [TimeRecord], now: Date = Date()) -> [TimeRecord] {
        var byID: [UUID: TimeRecord] = [:]
        for record in archived { byID[record.id] = record }
        for record in local { byID[record.id] = record }
        return normalize(Array(byID.values), now: now).valid
    }
    private func preserve(_ data: Data, name: String) throws {
        let dir = backupRoot.appendingPathComponent("RecordMigration", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: url.path) { try data.write(to: url, options: .atomic) }
    }
    func migrateIfNeeded(now: Date = Date()) throws {
        let candidates = ["timeRecords.json", "timeRecords_v20.json"].map { root.appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        let existing = FileManager.default.fileExists(atPath: headURL.path) ? try LatestCloudFile.read(headURL) : nil
        if candidates.isEmpty {
            if existing != nil { return }
            throw NSError(domain: "MonthlyRecords", code: 1, userInfo: [NSLocalizedDescriptionKey: "尚未取得记录文件，不能创建空白替代文件"])
        }
        var sources: [(URL, LatestCloudFile.Snapshot)] = []
        for url in candidates { sources.append((url, try LatestCloudFile.read(url))) }
        let selected = sources.max { LatestCloudFile.prefers($1.1, over: $0.1) }!
        let original = try JSONDecoder().decode([TimeRecord].self, from: selected.1.data)
        let cleaned = Self.normalize(original, now: now)
        let previous = try existing.map { try JSONDecoder().decode(Head.self, from: $0.data) }
        for (_, source) in sources { try preserve(source.data, name: "original-\(CloudFileManagerHash(source.data)).json") }
        if !cleaned.rejected.isEmpty { try preserve(try encoder.encode(cleaned.rejected), name: "quarantined-\(CloudFileManagerHash(selected.1.data)).json") }
        if previous == nil || selected.1.modifiedAt > previous!.savedAt {
            let ongoing = original.filter(\.isOngoing)
            // An old client can briefly publish only the invalid future task between
            // finishing the old action and starting the new one. Never import that frame.
            if previous != nil && !ongoing.isEmpty && ongoing.allSatisfy({ $0.startTime > now }) { return }
            _ = try save(cleaned.valid, loadedMonths: [], editedAt: selected.1.modifiedAt, replaceAll: true)
        }
        let committed = try JSONDecoder().decode(Head.self, from: LatestCloudFile.read(headURL).data)
        for hash in committed.months.values { _ = try payload(hash) }
        for (url, snapshot) in sources where snapshot.modifiedAt <= committed.savedAt {
            // Retire only the exact input read above. A concurrent old-client edit
            // stays in place and is reconciled on the next automatic check.
            var coordinationError: NSError?, deletionError: Error?
            NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { coordinated in
                do {
                    guard FileManager.default.fileExists(atPath: coordinated.path) else { return }
                    guard (NSFileVersion.unresolvedConflictVersionsOfItem(at: coordinated) ?? []).isEmpty else { return }
                    guard CloudFileManagerHash(try Data(contentsOf: coordinated)) == CloudFileManagerHash(snapshot.data) else { return }
                    try FileManager.default.removeItem(at: coordinated)
                } catch { deletionError = error }
            }
            if let error = coordinationError { throw error }
            if let error = deletionError { throw error }
        }
    }
    func load(months requested: Set<String>?, now: Date = Date()) throws -> Loaded {
        try migrateIfNeeded(now: now)
        let snapshot = try LatestCloudFile.read(headURL)
        let head = try JSONDecoder().decode(Head.self, from: snapshot.data)
        let liveHashes = Set(head.months.values)
        cache = cache.filter { liveHashes.contains($0.key) }
        let selected = requested ?? Set(head.months.keys)
        var records: [TimeRecord] = []
        for month in selected.sorted() {
            guard let digest = head.months[month] else { continue }
            records += try payload(digest)
        }
        if let current = head.current { records.append(current) }
        let clean = Self.normalize(records, now: now)
        if !clean.rejected.isEmpty {
            try preserve(try encoder.encode(clean.rejected), name: "quarantined-\(CloudFileManagerHash(snapshot.data)).json")
        }
        return Loaded(records: clean.valid, months: selected, headData: snapshot.data, editedAt: head.savedAt)
    }
    private func payload(_ digest: String) throws -> [TimeRecord] {
        guard digest.count == 64, digest.allSatisfy({ $0.isHexDigit }) else { throw CocoaError(.fileReadCorruptFile) }
        if let cached = cache[digest] { return cached }
        let url = revisions.appendingPathComponent(digest + ".json")
        if !FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.startDownloadingUbiquitousItem(at: url) }
        let data = try LatestCloudFile.read(url).data
        guard CloudFileManagerHash(data) == digest else { throw CocoaError(.fileReadCorruptFile) }
        let records = try JSONDecoder().decode([TimeRecord].self, from: data)
        cache[digest] = records
        return records
    }
    @discardableResult
    func save(_ records: [TimeRecord], loadedMonths: Set<String>, editedAt: Date, replaceAll: Bool = false, now: Date = Date()) throws -> Bool {
        let oldSnapshot = FileManager.default.fileExists(atPath: headURL.path) ? try LatestCloudFile.read(headURL) : nil
        let old = try oldSnapshot.map { try JSONDecoder().decode(Head.self, from: $0.data) }
        if let old, old.savedAt > editedAt { return false }
        let cleaned = Self.normalize(records, now: now)
        if !cleaned.rejected.isEmpty {
            try preserve(try encoder.encode(cleaned.rejected), name: "quarantined-\(UUID()).json")
            RecordTimeDiagnostics.shared.capture(records, phase: "archive.save.rejected", now: now)
            throw NSError(domain: "RecordIntegrity", code: 1, userInfo: [NSLocalizedDescriptionKey: "异常记录未写入，已保留诊断现场"])
        }
        var groups: [String: [TimeRecord]] = [:]
        for record in cleaned.valid where !record.isOngoing {
            for part in Self.splitMonths(record) { groups[Self.month(part.startTime), default: []].append(part) }
        }
        var months = replaceAll ? [:] : (old?.months ?? [:])
        let keys = loadedMonths.union(groups.keys).union(replaceAll ? Set(old?.months.keys.map { $0 } ?? []) : [])
        try FileManager.default.createDirectory(at: revisions, withIntermediateDirectories: true)
        for key in keys.sorted() {
            var items = groups[key] ?? []
            if !replaceAll && !loadedMonths.contains(key), let digest = old?.months[key] {
                var merged = Dictionary(uniqueKeysWithValues: try payload(digest).map { ($0.id, $0) })
                for item in items { merged[item.id] = item }
                items = Array(merged.values)
            }
            items.sort { $0.startTime == $1.startTime ? $0.id.uuidString < $1.id.uuidString : $0.startTime < $1.startTime }
            if items.isEmpty { months.removeValue(forKey: key); continue }
            let data = try encoder.encode(items), hash = CloudFileManagerHash(data)
            if months[key] != hash {
                let destination = revisions.appendingPathComponent(hash + ".json")
                if !FileManager.default.fileExists(atPath: destination.path) { try data.write(to: destination, options: .atomic) }
                months[key] = hash; cache[hash] = items
            }
        }
        let head = Head(savedAt: editedAt, current: cleaned.valid.last(where: \.isOngoing), months: months)
        let data = try encoder.encode(head)
        let winner = try LatestCloudFile.write(data, to: headURL, editedAt: editedAt)
        let accepted = winner.data == data
        if accepted {
            let liveHashes = Set(months.values)
            cache = cache.filter { liveHashes.contains($0.key) }
            // Readable monthly files are projections. The head + immutable payloads remain authoritative.
            for key in keys where months[key] != old?.months[key] {
                let destination = root.appendingPathComponent("records/\(key).json")
                if let hash = months[key] { _ = try LatestCloudFile.write(try encoder.encode(payload(hash)), to: destination, editedAt: editedAt) }
                else { try? FileManager.default.removeItem(at: destination) }
            }
        }
        return accepted
    }
    /// Reads a backup without migrating, retiring, or modifying any file inside it.
    static func readBackup(root: URL) throws -> [TimeRecord] {
        let headURL = root.appendingPathComponent("current.json")
        if FileManager.default.fileExists(atPath: headURL.path) {
            let head = try JSONDecoder().decode(Head.self, from: Data(contentsOf: headURL))
            var records: [TimeRecord] = []
            for hash in head.months.values {
                guard hash.count == 64, hash.allSatisfy({ $0.isHexDigit }) else { throw CocoaError(.fileReadCorruptFile) }
                let data = try Data(contentsOf: root.appendingPathComponent("records/revisions/\(hash).json"))
                guard CloudFileManagerHash(data) == hash else { throw CocoaError(.fileReadCorruptFile) }
                records += try JSONDecoder().decode([TimeRecord].self, from: data)
            }
            if let current = head.current { records.append(current) }
            return records
        }
        for name in ["timeRecords.json", "timeRecords_v20.json"] {
            let source = root.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: source.path) {
                return try JSONDecoder().decode([TimeRecord].self, from: Data(contentsOf: source))
            }
        }
        throw CocoaError(.fileReadNoSuchFile)
    }

    static func splitMonths(_ record: TimeRecord) -> [TimeRecord] {
        guard !record.isOngoing, record.endTime > record.startTime else { return record.isOngoing ? [] : [record] }
        let cal = Calendar.current
        var cursor = record.startTime, parts: [TimeRecord] = []
        while cursor < record.endTime {
            let next = cal.date(byAdding: .month, value: 1, to: cal.dateInterval(of: .month, for: cursor)!.start)!
            let end = min(next, record.endTime)
            var part = record; part.startTime = cursor; part.endTime = end
            if cursor != record.startTime {
                let hash = CloudFileManagerHash(Data("\(record.id.uuidString)|\(cursor.timeIntervalSinceReferenceDate)".utf8))
                let chars = Array(hash.prefix(32)); let text = String(chars[0..<8])+"-"+String(chars[8..<12])+"-"+String(chars[12..<16])+"-"+String(chars[16..<20])+"-"+String(chars[20..<32])
                part = TimeRecord(id: UUID(uuidString: text)!, category: part.category, subCategory: part.subCategory, startTime: cursor, endTime: end)
            }
            parts.append(part); cursor = end
        }
        return parts
    }
}

// Kept independent of the app singleton so migration and transaction tests use real code.
import CryptoKit
nonisolated func CloudFileManagerHash(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
