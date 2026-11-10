import Foundation
import CryptoKit

/// Rare integrity incidents are persisted synchronously, before a bad transaction can be rejected or crash.
nonisolated final class RecordTimeDiagnostics: @unchecked Sendable {
    static let shared = RecordTimeDiagnostics()
    private let lock = NSLock()
    private let customDirectory: URL?
    init(directory: URL? = nil) { self.customDirectory = directory }
    private let session = String(UUID().uuidString.prefix(8))
    private var seen: [String: Date] = [:]
    private var writeError: String?
    var directory: URL {
        if let customDirectory { return customDirectory }
        if let path = ProcessInfo.processInfo.environment["TIME_TRACKER_DIAGNOSTICS_DIR"] { return URL(fileURLWithPath: path) }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("李知本时间管理/Diagnostics", isDirectory: true)
    }
    var logURL: URL { directory.appendingPathComponent("record-time-\(ProcessInfo.processInfo.processIdentifier)-\(session).jsonl") }
    var lastWriteError: String? { lock.lock(); defer { lock.unlock() }; return writeError }
    private struct Sample: Codable {
        let id: UUID
        let category: String
        let start: Double
        let end: Double
        let startISO: String
        let endISO: String
        let unfinished: Bool
    }
    private struct Event: Codable {
        let id: UUID
        let phase: String
        let observedAt: Date
        let observedISO: String
        let calendar: String
        let build: String
        let uptime: Double
        let timeZone: String
        let process: Int32
        let inputCount: Int
        let issues: [RecordIntegrity.Issue]
        let samples: [Sample]
        let snapshot: String?
        let note: String
        let location: String
        let stack: [String]
    }
    @discardableResult
    static func observe(_ record: TimeRecord, phase: String, file: String = #fileID, function: String = #function, line: UInt = #line) -> Bool {
        shared.capture([record], phase: phase, location: "\(file):\(line) \(function)")
    }
    @discardableResult
    func capture(_ records: [TimeRecord], phase: String, now: Date = Date(), issues supplied: [RecordIntegrity.Issue]? = nil,
                 note: String = "", location: String = "", allowNormal: Bool = false) -> Bool {
        let issues = supplied ?? RecordIntegrity.issues(records, now: now)
        if issues.isEmpty && !allowNormal { return true }
        let ids = Set(issues.flatMap(\.recordIDs))
        let selected = records.filter { ids.isEmpty || ids.contains($0.id) }.sorted { $0.id.uuidString < $1.id.uuidString }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        lock.lock(); defer { lock.unlock() }
        do {
            let payload = try encoder.encode(selected)
            let hash = SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
            let key = phase + hash + issues.map(\.signature).sorted().joined()
            if let prior = seen[key] {
                let elapsed = now.timeIntervalSince(prior)
                if elapsed >= 0 && elapsed < 60 { return true }
            }
            let fm = FileManager.default
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            var snapshot: String?
            if !issues.isEmpty {
                let folder = directory.appendingPathComponent("record-snapshots", isDirectory: true)
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                let target = folder.appendingPathComponent(hash + ".json")
                if !fm.fileExists(atPath: target.path) { try payload.write(to: target, options: .atomic) }
                snapshot = "record-snapshots/" + target.lastPathComponent
                let files = try fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey]).sorted {
                    ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
                    > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
                }
                for old in files.dropFirst(50) { try? fm.removeItem(at: old) }
            }
            let formatter = ISO8601DateFormatter()
            func iso(_ date: Date) -> String {
                date.timeIntervalSinceReferenceDate.isFinite ? formatter.string(from: date) : "non-finite"
            }
            let samples = selected.prefix(12).map {
                Sample(id: $0.id, category: $0.category, start: $0.startTime.timeIntervalSinceReferenceDate,
                    end: $0.endTime.timeIntervalSinceReferenceDate, startISO: iso($0.startTime), endISO: iso($0.endTime), unfinished: $0.isOngoing)
            }
            let event = Event(id: UUID(), phase: phase, observedAt: now, observedISO: iso(now),
                calendar: String(describing: Calendar.current.identifier), build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unbundled", uptime: ProcessInfo.processInfo.systemUptime,
                timeZone: TimeZone.current.identifier, process: ProcessInfo.processInfo.processIdentifier,
                inputCount: records.count, issues: issues, samples: Array(samples), snapshot: snapshot, note: note,
                location: location, stack: Array(Thread.callStackSymbols.prefix(18)))
            var data = try encoder.encode(event); data.append(0x0a)
            if fm.fileExists(atPath: logURL.path), (try fm.attributesOfItem(atPath: logURL.path)[.size] as? NSNumber)?.intValue ?? 0 > 2_000_000 {
                let old = logURL.deletingPathExtension().appendingPathExtension("previous.jsonl")
                try? fm.removeItem(at: old); try fm.moveItem(at: logURL, to: old)
            }
            if !fm.fileExists(atPath: logURL.path) { try Data().write(to: logURL, options: .atomic) }
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd(); try handle.write(contentsOf: data); try handle.synchronize()
            let logs = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
                .filter { $0.lastPathComponent.hasPrefix("record-time-") && $0.pathExtension == "jsonl" }
                .sorted { ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
                    > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) }
            for old in logs.dropFirst(20) where old != logURL { try? fm.removeItem(at: old) }
            seen[key] = now
            if seen.count > 2048 { seen = [key: now] }
            writeError = nil
            return true
        } catch {
            writeError = error.localizedDescription
            NSLog("[RecordTimeDiagnostics] Could not persist incident: %@", error.localizedDescription)
            return false
        }
    }
    func files() -> [URL] {
        let fm = FileManager.default
        let logs = (try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        let snapshots = (try? fm.contentsOfDirectory(at: directory.appendingPathComponent("record-snapshots"), includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return (logs.filter { $0.lastPathComponent.hasPrefix("record-time-") && $0.pathExtension == "jsonl" } + snapshots).sorted {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
            > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
    }
}
