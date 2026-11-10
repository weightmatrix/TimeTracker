import Foundation

@main
struct MonthlyRecordArchiveTests {
    static func main() throws {
        precondition(ProcessInfo.processInfo.environment["TIME_TRACKER_DIAGNOSTICS_DIR"] != nil, "Tests must use a temporary diagnostics directory")
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("monthly-record-tests-\(UUID())")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let recordsRoot = root.appendingPathComponent("cloud"), backup = root.appendingPathComponent("backup")
        try fm.createDirectory(at: recordsRoot, withIntermediateDirectories: true)
        let now = Date()
        let parse: (String) -> Date = { ISO8601DateFormatter().date(from: $0)! }
        let across = TimeRecord(category: "生活", startTime: parse("2026-10-31T23:30:00+08:00"), endTime: parse("2026-11-01T00:30:00+08:00"))
        let earlier = TimeRecord(category: "工作", startTime: parse("2026-08-01T10:00:00+08:00"), endTime: parse("2026-08-01T11:00:00+08:00"))
        var editedEarlier = earlier; editedEarlier.category = "刚需"
        let merged = MonthlyRecordArchive.mergingHistory([earlier], with: [editedEarlier])
        precondition(merged.first?.category == "刚需", "Historical load discarded a newer local edit with the same ID")
        let current = TimeRecord(category: "工作", startTime: now.addingTimeInterval(-60), endTime: .distantFuture)
        let duplicate = TimeRecord(category: "生活", startTime: now.addingTimeInterval(-3600), endTime: .distantFuture)
        let bad = TimeRecord(category: "工作", startTime: parse("2028-11-11T15:34:42+08:00"), endTime: .distantFuture)
        let future = TimeRecord(category: "生活", startTime: now.addingTimeInterval(86400), endTime: now.addingTimeInterval(172800))
        let source = try JSONEncoder().encode([across, earlier, current, duplicate, bad, future])
        let legacy = recordsRoot.appendingPathComponent("timeRecords_v20.json")
        try source.write(to: legacy)
        let originalEdit = now.addingTimeInterval(-600)
        try fm.setAttributes([.modificationDate: originalEdit], ofItemAtPath: legacy.path)
        let store = MonthlyRecordArchive(root: recordsRoot, backupRoot: backup)
        let home = try store.load(months: ["2026-10", "2026-11"])
        precondition(abs(home.editedAt.timeIntervalSince(originalEdit)) < 0.001, "Migration promoted old data to a new edit")
        precondition(home.records.filter(\.isOngoing).count == 1)
        precondition(home.records.last?.id == current.id)
        precondition(home.records.allSatisfy { $0.startTime <= now })
        precondition(!home.records.contains { $0.id == earlier.id }, "Cold load read archived months")
        precondition(!fm.fileExists(atPath: legacy.path), "Legacy live name not retired")
        let originalBackup = backup.appendingPathComponent("RecordMigration/original-\(CloudFileManagerHash(source)).json")
        precondition(tryData(originalBackup) == source, "Migration did not preserve exact original")
        let all = try store.load(months: nil)
        precondition(all.records.contains { $0.id == earlier.id })
        let split = all.records.filter { !$0.isOngoing && $0.category == "生活" }
        precondition(split.count == 2 && split.reduce(0) { $0 + $1.duration } == across.duration)
        precondition(Set(split.map(\.id)).count == 2)
        let backedUp = try MonthlyRecordArchive.readBackup(root: recordsRoot)
        precondition(Set(backedUp.map(\.id)) == Set(all.records.map(\.id)), "New-format backup missed historical months")
        let oldHead = try JSONDecoder().decode(MonthlyRecordArchive.Head.self, from: all.headData)
        var changed = home.records
        changed[changed.count - 1].category = "生活"
        let accepted = try store.save(changed, loadedMonths: home.months, editedAt: now.addingTimeInterval(10))
        precondition(accepted)
        let after = try store.load(months: nil)
        precondition(after.records.last?.category == "生活")
        precondition(after.records.contains { $0.id == earlier.id }, "Saving active months erased archives")
        let newHead = try JSONDecoder().decode(MonthlyRecordArchive.Head.self, from: after.headData)
        precondition(newHead.months == oldHead.months, "Current-only edit rewrote month data")
        let stale = try store.save(home.records, loadedMonths: home.months, editedAt: now)
        precondition(stale == false, "Stale retry rolled back current")
        // A new pointer arriving before a referenced payload must not produce a partial snapshot.
        var missing = newHead; missing.months["2026-11"] = String(repeating: "f", count: 64)
        try JSONEncoder().encode(missing).write(to: store.headURL, options: .atomic)
        do { _ = try store.load(months: ["2026-11"]); fatalError("Missing month payload was accepted") } catch { }
        try after.headData.write(to: store.headURL, options: .atomic)
        let annualRoot = root.appendingPathComponent("targets")
        try fm.createDirectory(at: annualRoot, withIntermediateDirectories: true)
        let targets = Data(#"{"2025-W52":{"hours":8,"efficiency":6},"2026-W1":{"hours":7,"efficiency":5}}"#.utf8)
        try targets.write(to: annualRoot.appendingPathComponent("weekly_targets_v20.json"))
        let annual = YearlyTargetArchive(root: annualRoot, backupRoot: backup)
        let loaded = try annual.load()!
        let loadedObject = try JSONSerialization.jsonObject(with: loaded) as! NSDictionary
        let expectedObject = try JSONSerialization.jsonObject(with: targets) as! NSDictionary
        precondition(loadedObject == expectedObject)
        precondition(fm.fileExists(atPath: annualRoot.appendingPathComponent("weekly_targets/2025.json").path))
        precondition(fm.fileExists(atPath: annualRoot.appendingPathComponent("weekly_targets/2026.json").path))
        // An old client may still finish a write while another device upgrades.
        var resumed = current; resumed.category = "刚需"
        try JSONEncoder().encode([across, earlier, resumed]).write(to: legacy, options: .atomic)
        try fm.setAttributes([.modificationDate: now.addingTimeInterval(15)], ofItemAtPath: legacy.path)
        let resumedLoad = try store.load(months: home.months)
        precondition(resumedLoad.records.last?.category == "刚需", "Newer legacy write was ignored during cutover")
        try JSONEncoder().encode([across, earlier, bad]).write(to: legacy, options: .atomic)
        try fm.setAttributes([.modificationDate: now.addingTimeInterval(16)], ofItemAtPath: legacy.path)
        let intermediate = try store.load(months: home.months)
        precondition(intermediate.records.last?.category == "刚需", "Legacy intermediate future-only task replaced valid current state")
        resumed.category = "生活"
        try JSONEncoder().encode([across, earlier, resumed]).write(to: legacy, options: .atomic)
        try fm.setAttributes([.modificationDate: now.addingTimeInterval(17)], ofItemAtPath: legacy.path)
        let finalLegacy = try store.load(months: home.months)
        precondition(finalLegacy.records.last?.category == "生活")
        precondition(!fm.fileExists(atPath: legacy.path))
        let cleared = try store.save([], loadedMonths: home.months, editedAt: now.addingTimeInterval(20), replaceAll: true)
        precondition(cleared && (try! store.load(months: nil)).records.isEmpty)
        let remainingMonths = try fm.contentsOfDirectory(at: recordsRoot.appendingPathComponent("records"), includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        precondition(remainingMonths.isEmpty, "Full replacement left active old monthly files")
        let queuedRoot = root.appendingPathComponent("queued-targets")
        let queuedBackup = root.appendingPathComponent("queued-backup")
        try fm.createDirectory(at: queuedRoot, withIntermediateDirectories: true)
        let blocked = queuedRoot.appendingPathComponent("weekly_targets")
        try Data("not a directory".utf8).write(to: blocked)
        let queued = YearlyTargetArchive(root: queuedRoot, backupRoot: queuedBackup)
        do { try queued.queueAndSave(targets, editedAt: now); fatalError("Blocked save succeeded") } catch { }
        precondition(fm.fileExists(atPath: queued.pendingURL.path), "Failed weekly save lost its pending data")
        try fm.removeItem(at: blocked)
        let recoveredTargets = try queued.load()!
        let recoveredObject = try JSONSerialization.jsonObject(with: recoveredTargets) as! NSDictionary
        precondition(recoveredObject == expectedObject)
        precondition(!fm.fileExists(atPath: queued.pendingURL.path))
        print("PASS: backed-up migration, future quarantine, one ongoing, month split/duration/IDs, lazy load, archived-month preservation, current-only write, stale retry rejection, partial delivery rejection, yearly targets")
    }
    static func tryData(_ url: URL) -> Data { try! Data(contentsOf: url) }
}
