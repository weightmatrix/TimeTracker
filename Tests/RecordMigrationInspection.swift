import Foundation

@main
struct RecordMigrationInspection {
    static func main() throws {
        precondition(ProcessInfo.processInfo.environment["TIME_TRACKER_DIAGNOSTICS_DIR"] != nil, "Tests must use a temporary diagnostics directory")
        guard CommandLine.arguments.count == 2 else { fatalError("Pass a read-only legacy JSON source") }
        let raw = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let original = try JSONDecoder().decode([TimeRecord].self, from: raw)
        let fm = FileManager.default
        let sandbox = fm.temporaryDirectory.appendingPathComponent("real-record-migration-\(UUID())")
        try fm.createDirectory(at: sandbox, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: sandbox) }
        let cloud = sandbox.appendingPathComponent("cloud"), backups = sandbox.appendingPathComponent("backups")
        try fm.createDirectory(at: cloud, withIntermediateDirectories: true)
        try raw.write(to: cloud.appendingPathComponent("timeRecords_v20.json"))
        let store = MonthlyRecordArchive(root: cloud, backupRoot: backups)
        let home = try store.load(months: MonthlyRecordArchive.homeMonths())
        let all = try store.load(months: nil)
        let normalized = MonthlyRecordArchive.normalize(original, now: Date())
        precondition(all.records.filter(\.isOngoing).count == 1)
        precondition(Set(all.records.map(\.id)) == Set(normalized.valid.map(\.id)))
        precondition(all.records.allSatisfy { $0.startTime <= Date() })
        let oldDuration = normalized.valid.filter { !$0.isOngoing }.reduce(0) { $0 + $1.duration }
        let newDuration = all.records.filter { !$0.isOngoing }.reduce(0) { $0 + $1.duration }
        precondition(abs(oldDuration - newDuration) < 0.001)
        let backup = backups.appendingPathComponent("RecordMigration/original-\(CloudFileManagerHash(raw)).json")
        precondition(tryData(backup) == raw)
        let months = try fm.contentsOfDirectory(at: cloud.appendingPathComponent("records"), includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        print("originalBytes=\(raw.count) originalRecords=\(original.count) retainedRecords=\(all.records.count) quarantinedRecords=\(normalized.rejected.count) homeRecords=\(home.records.count) monthFiles=\(months.count) currentBytes=\(home.headData.count)")
        for url in months.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            print(url.lastPathComponent, try Data(contentsOf: url).count, "bytes")
        }
        print("PASS: actual source copied read-only; exact original backup; valid record IDs and total duration preserved; future data isolated; one current task")
    }
    static func tryData(_ url: URL) -> Data { try! Data(contentsOf: url) }
}
