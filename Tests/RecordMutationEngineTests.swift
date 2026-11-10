import Foundation

@main
struct RecordMutationEngineTests {
    static func main() throws {
        guard ProcessInfo.processInfo.environment["TIME_TRACKER_DIAGNOSTICS_DIR"] != nil else { fatalError("Use a temporary diagnostic directory") }
        let now = Date(), click = Date().addingTimeInterval(-10)
        let previous = TimeRecord(category: "生活", startTime: click.addingTimeInterval(-7200), endTime: click.addingTimeInterval(-3600))
        let current = TimeRecord(category: "工作", subCategory: "物理", startTime: click.addingTimeInterval(-3600), endTime: .distantFuture)
        let switched = try RecordMutationEngine.switchAction(records: [previous, current], category: "刚需", subCategory: nil, at: click, now: now)
        precondition(switched.records.contains(previous), "Switch changed unrelated completed history")
        precondition(switched.ended?.endTime == click && switched.started?.startTime == click)
        precondition(switched.ended?.startTime == current.startTime && switched.ended?.subCategory == "物理")
        precondition(switched.records.filter(\.isOngoing).count == 1)
        let noOp = try RecordMutationEngine.switchAction(records: [previous, current], category: "工作", subCategory: "物理", at: click, now: now)
        precondition(noOp.records == [previous, current])
        let future = TimeRecord(category: "工作", startTime: now.addingTimeInterval(86400 * 730), endTime: .distantFuture)
        let repaired = try RecordMutationEngine.switchAction(records: [previous, future], category: "工作", subCategory: nil, at: click, now: now)
        precondition(repaired.rejected.contains(future) && repaired.ended == nil)
        precondition(repaired.records.count == 2 && repaired.started?.startTime == click)
        let duplicate = TimeRecord(category: "生活", startTime: current.startTime.addingTimeInterval(60), endTime: .distantFuture)
        let cleaned = try RecordMutationEngine.switchAction(records: [previous, current, duplicate], category: "刚需", subCategory: nil, at: click, now: now)
        precondition(cleaned.rejected.contains(current) && cleaned.ended?.id == duplicate.id)
        expectFailure { _ = try RecordMutationEngine.switchAction(records: [current], category: "生活", subCategory: nil, at: current.startTime.addingTimeInterval(-1), now: now) }
        expectFailure { _ = try RecordMutationEngine.switchAction(records: [current], category: "生活", subCategory: nil, at: now.addingTimeInterval(1), now: now) }
        let futureDraft = TimeRecord(id: current.id, category: "工作", startTime: future.startTime, endTime: .distantFuture)
        expectFailure { _ = try RecordMutationEngine.replace(records: [previous, current], id: current.id, with: futureDraft, now: now) }
        precondition(previous.endTime == current.startTime)
        let invalidEnd = TimeRecord(category: "生活", startTime: click, endTime: now.addingTimeInterval(60))
        expectFailure { _ = try RecordMutationEngine.add(records: [], draft: invalidEnd, now: now) }
        var mutated = previous
        mutated.endTime = now.addingTimeInterval(60)
        mutated.startTime = now.addingTimeInterval(120)
        precondition(!RecordIntegrity.timeIssues(mutated, now: now).isEmpty)
        precondition(RecordIntegrity.timeIssues(current, now: now).isEmpty, "Unfinished sentinel reported as future actual end")
        let bogusSentinel = TimeRecord(category: "工作", startTime: click, endTime: Date.distantFuture.addingTimeInterval(86400))
        precondition(!bogusSentinel.isOngoing && RecordIntegrity.timeIssues(bogusSentinel, now: now).contains { $0.code == "end_in_future" })
        let parse: (String) -> Date = { ISO8601DateFormatter().date(from: $0)! }
        var shanghai = Calendar(identifier: .gregorian); shanghai.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let crossYear = TimeRecord(category: "工作", startTime: parse("2025-12-31T23:50:00+08:00"), endTime: parse("2026-01-01T00:10:00+08:00"))
        let pieces = try RecordMutationEngine.splitClosed(crossYear, now: now, calendar: shanghai)
        precondition(pieces.count == 2 && pieces.reduce(0) { $0 + $1.duration } == 1200)
        precondition(pieces.first?.startTime == crossYear.startTime && pieces.last?.endTime == crossYear.endTime)
        let repeated = try RecordMutationEngine.splitClosed(crossYear, now: now, calendar: shanghai)
        precondition(pieces.map(\.id) == repeated.map(\.id) && Set(pieces.map(\.id)).count == 2)
        var losAngeles = Calendar(identifier: .gregorian); losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let dst = TimeRecord(category: "生活", startTime: parse("2026-03-07T23:00:00-08:00"), endTime: parse("2026-03-09T01:00:00-07:00"))
        let dstPieces = try RecordMutationEngine.splitClosed(dst, now: now, calendar: losAngeles)
        precondition(dstPieces.count == 3 && dstPieces.reduce(0) { $0 + $1.duration } == 25 * 3600)
        expectFailure { _ = try RecordMutationEngine.splitClosed(current, now: now) }
        let inverted = TimeRecord(category: "工作", startTime: future.startTime, endTime: click)
        expectFailure { _ = try RecordMutationEngine.splitClosed(inverted, now: now) }
        let overlap = TimeRecord(category: "刚需", startTime: previous.startTime.addingTimeInterval(60), endTime: previous.endTime)
        precondition(RecordIntegrity.regressions(before: [previous], after: [previous, overlap], now: now).isEmpty,
            "Intentional overlap must not reject a record edit")
        precondition(RecordIntegrity.issues([previous, overlap], now: now, checkOverlaps: true).contains { $0.code == "overlap" },
            "Overlap remains available for diagnostics")
        precondition(!RecordIntegrity.regressions(before: [previous], after: [previous, invalidEnd], now: now).isEmpty,
            "Future end time must still reject a record edit")
        precondition(RecordIntegrity.regressions(before: [previous, overlap], after: [previous, overlap, current], now: now).isEmpty)
        let overlappingCurrent = TimeRecord(category: "工作", startTime: previous.startTime, endTime: .distantFuture)
        let isolated = try RecordMutationEngine.switchAction(records: [previous, overlappingCurrent], category: "生活", subCategory: nil, at: click, now: now)
        precondition(isolated.records.contains(previous) && isolated.isolatedCurrent?.id == overlappingCurrent.id && isolated.ended == nil)
        let stopped = try RecordMutationEngine.switchAction(records: [previous, current], category: "空", subCategory: nil, at: click, now: now)
        precondition(stopped.started == nil && !stopped.records.contains(where: \.isOngoing))
        let third = TimeRecord(category: "生活", startTime: parse("2026-01-01T12:00:00+08:00"), endTime: parse("2026-01-01T13:00:00+08:00"))
        let left = TimeRecord(category: "生活", startTime: third.endTime, endTime: parse("2026-01-01T14:00:00+08:00"))
        let right = TimeRecord(category: "工作", startTime: left.endTime, endTime: parse("2026-01-01T15:00:00+08:00"))
        let manual = try RecordMutationEngine.merge(records: [third, left, right], targetID: left.id, neighbourID: right.id, category: "生活", now: now, calendar: shanghai)
        precondition(manual.contains(third) && manual.count == 2, "Explicit merge absorbed an unselected same-category neighbour")
        precondition(manual.first(where: { $0.id == left.id })?.endTime == right.endTime)
        let separated = TimeRecord(category: "工作", startTime: right.endTime, endTime: right.endTime.addingTimeInterval(3600))
        expectFailure { _ = try RecordMutationEngine.merge(records: [left, separated], targetID: left.id, neighbourID: separated.id, category: "生活", now: now) }
        let mergedCurrent = try RecordMutationEngine.merge(records: [previous, current], targetID: current.id, neighbourID: previous.id, category: "工作", now: now)
        precondition(mergedCurrent.count == 1 && mergedCurrent[0].id == current.id && mergedCurrent[0].startTime == previous.startTime)
        let logger = RecordTimeDiagnostics.shared
        let persisted = logger.capture([future], phase: "test.persist", now: now)
        precondition(persisted)
        let beforeRepeat = try Data(contentsOf: logger.logURL)
        precondition(logger.capture([future], phase: "test.persist", now: now))
        precondition(tryData(logger.logURL) == beforeRepeat, "Repeated same incident flooded the log")
        let lines = String(data: beforeRepeat, encoding: .utf8)!.split(separator: "\n")
        let objects = try lines.map { try JSONSerialization.jsonObject(with: Data($0.utf8)) as! [String: Any] }
        precondition(objects.contains { $0["phase"] as? String == "creation" })
        precondition(objects.contains { $0["phase"] as? String == "mutation.end" })
        let event = objects.last!
        precondition(event["observedISO"] != nil && event["stack"] != nil && event["snapshot"] != nil)
        precondition(event["samples"] != nil && event["timeZone"] != nil)
        precondition(logger.capture([future], phase: "test.persist", now: now.addingTimeInterval(-3600)))
        precondition(tryData(logger.logURL) != beforeRepeat, "Clock rollback was incorrectly deduplicated")
        let frozen = tryData(logger.logURL)
        RecordTimeDiagnostics.observe(current, phase: "test.normal")
        precondition(tryData(logger.logURL) == frozen)
        print("PASS: deterministic switch; intentional edit overlaps allowed; invalid times rejected; midnight/month/year/DST durations; diagnostic creation/mutation/durable snapshots/dedup; real unfinished sentinel exempt")
    }
    static func tryData(_ url: URL) -> Data { try! Data(contentsOf: url) }
    static func expectFailure(_ action: () throws -> Void) {
        do { try action(); fatalError("Invalid operation accepted") } catch { }
    }
}
