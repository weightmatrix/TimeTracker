import Foundation

nonisolated enum RecordIntegrity {
    struct Issue: Codable, Equatable, Sendable {
        let code: String
        let recordIDs: [UUID]
        var from: Double? = nil
        var to: Double? = nil
        var signature: String {
            code + recordIDs.map(\.uuidString).sorted().joined() + String(describing: from) + String(describing: to)
        }
    }
    static func timeIssues(_ record: TimeRecord, now: Date) -> [Issue] {
        var result: [Issue] = []
        func add(_ code: String) { result.append(Issue(code: code, recordIDs: [record.id])) }
        if !record.startTime.timeIntervalSinceReferenceDate.isFinite { add("invalid_start") }
        else if record.startTime > now { add("start_in_future") }
        if !record.endTime.timeIntervalSinceReferenceDate.isFinite { add("invalid_end") }
        else if !record.isOngoing {
            if record.endTime > now { add("end_in_future") }
            if record.endTime < record.startTime { add("end_before_start") }
        }
        return result
    }
    static func issues(_ records: [TimeRecord], now: Date, checkOverlaps: Bool = false) -> [Issue] {
        var result = records.flatMap { timeIssues($0, now: now) }
        for (id, matches) in Dictionary(grouping: records, by: \.id) where matches.count > 1 {
            result.append(Issue(code: "duplicate_id", recordIDs: [id]))
        }
        let ongoing = records.filter { $0.isOngoing && !$0.isGap }
        if ongoing.count > 1 { result.append(Issue(code: "multiple_ongoing", recordIDs: ongoing.map(\.id))) }
        if checkOverlaps {
            let ordered = records.filter { timeIssues($0, now: now).isEmpty && !$0.isGap }
                .sorted { $0.startTime == $1.startTime ? $0.id.uuidString < $1.id.uuidString : $0.startTime < $1.startTime }
            var active: [TimeRecord] = []
            for record in ordered {
                let end = record.isOngoing ? now : record.endTime
                active.removeAll { ($0.isOngoing ? now : $0.endTime) <= record.startTime }
                if end > record.startTime {
                    for previous in active {
                        let overlapEnd = min(end, previous.isOngoing ? now : previous.endTime)
                        if overlapEnd > record.startTime {
                            result.append(Issue(code: "overlap", recordIDs: [previous.id, record.id],
                                from: record.startTime.timeIntervalSinceReferenceDate, to: overlapEnd.timeIntervalSinceReferenceDate))
                        }
                    }
                    active.append(record)
                }
            }
        }
        return result
    }
    /// Record editing may intentionally overlap other intervals. Only structural and time errors block a transaction.
    static func regressions(before: [TimeRecord], after: [TimeRecord], now: Date) -> [Issue] {
        issues(after, now: now)
    }
    static func sanitize(_ records: [TimeRecord], now: Date) -> (valid: [TimeRecord], rejected: [TimeRecord]) {
        var valid: [UUID: TimeRecord] = [:], rejected: [TimeRecord] = []
        for record in records {
            guard timeIssues(record, now: now).isEmpty, !record.isGap else { rejected.append(record); continue }
            if let previous = valid[record.id] {
                if record.startTime > previous.startTime { rejected.append(previous); valid[record.id] = record }
                else { rejected.append(record) }
            } else { valid[record.id] = record }
        }
        let ongoing = valid.values.filter(\.isOngoing).sorted {
            $0.startTime == $1.startTime ? $0.id.uuidString < $1.id.uuidString : $0.startTime < $1.startTime
        }
        for record in ongoing.dropLast() { rejected.append(record); valid.removeValue(forKey: record.id) }
        var result = valid.values.filter { !$0.isOngoing }.sorted { $0.startTime < $1.startTime }
        if let current = ongoing.last { result.append(current) }
        return (result, rejected)
    }
}
