import Foundation
import CryptoKit

nonisolated enum RecordMutationEngine {
    enum MutationError: LocalizedError {
        case invalidTime, staleClick, missingRecord, unfinishedSplit, invalidBoundary, notAdjacent
        var errorDescription: String? {
            switch self {
            case .invalidTime: return "记录时间异常，本次修改未保存。"
            case .staleClick: return "记录已被更新，点击时间早于当前记录，请重试。"
            case .missingRecord: return "记录已变化，请重新打开后修改。"
            case .unfinishedSplit: return "进行中的记录不能当作已结束记录切割。"
            case .invalidBoundary: return "无法安全切割这段时间，本次修改未保存。"
            case .notAdjacent: return "这两条记录之间有空白时间，未自动填补或合并。"
            }
        }
    }
    struct SwitchResult {
        let records: [TimeRecord]
        let rejected: [TimeRecord]
        let ended: TimeRecord?
        let started: TimeRecord?
        var isolatedCurrent: TimeRecord? = nil
    }
    static func switchAction(records: [TimeRecord], category: String, subCategory: String?, at click: Date,
                             now: Date, calendar: Calendar = .current) throws -> SwitchResult {
        guard click.timeIntervalSinceReferenceDate.isFinite, click <= now else { throw MutationError.invalidTime }
        let clean = RecordIntegrity.sanitize(records, now: now)
        let current = clean.valid.last(where: \.isOngoing)
        if let current, current.category == category && current.subCategory == subCategory {
            return SwitchResult(records: clean.valid, rejected: clean.rejected, ended: nil, started: nil)
        }
        var history = clean.valid.filter { !$0.isOngoing }
        guard !history.contains(where: { $0.endTime > click }), current.map({ $0.startTime <= click }) ?? true else {
            throw MutationError.staleClick
        }
        var rejected = clean.rejected
        var ended: TimeRecord?
        var isolatedCurrent: TimeRecord?
        if var closed = current {
            closed.endTime = click
            // If the old task already overlaps completed history, retain the history,
            // isolate the ambiguous task, and let the new action start normally.
            let overlaps = history.contains { $0.startTime < click && $0.endTime > closed.startTime && $0.endTime > $0.startTime }
            if overlaps { rejected.append(current!); isolatedCurrent = current }
            else {
                ended = closed
                history += try splitClosed(closed, now: now, calendar: calendar)
            }
        }
        let started = category == "空" ? nil : TimeRecord(category: category, subCategory: subCategory, startTime: click, endTime: .distantFuture)
        history.sort { $0.startTime == $1.startTime ? $0.id.uuidString < $1.id.uuidString : $0.startTime < $1.startTime }
        if let started { history.append(started) }
        return SwitchResult(records: history, rejected: rejected, ended: ended, started: started, isolatedCurrent: isolatedCurrent)
    }
    static func replace(records: [TimeRecord], id: UUID, with draft: TimeRecord, now: Date,
                        calendar: Calendar = .current) throws -> [TimeRecord] {
        guard records.contains(where: { $0.id == id }) else { throw MutationError.missingRecord }
        guard !draft.isGap, RecordIntegrity.timeIssues(draft, now: now).isEmpty else { throw MutationError.invalidTime }
        let pieces = draft.isOngoing ? [draft] : try splitClosed(draft, now: now, calendar: calendar)
        return records.filter { $0.id != id } + pieces
    }
    static func add(records: [TimeRecord], draft: TimeRecord, now: Date, calendar: Calendar = .current) throws -> [TimeRecord] {
        guard !draft.isGap, !draft.isOngoing, RecordIntegrity.timeIssues(draft, now: now).isEmpty else { throw MutationError.invalidTime }
        return records + (try splitClosed(draft, now: now, calendar: calendar))
    }
    /// Manual merge affects exactly the two records selected by the user, never a third neighbour or a gap.
    static func merge(records: [TimeRecord], targetID: UUID, neighbourID: UUID, category: String, now: Date,
                      calendar: Calendar = .current) throws -> [TimeRecord] {
        guard targetID != neighbourID,
              let target = records.first(where: { $0.id == targetID }),
              let neighbour = records.first(where: { $0.id == neighbourID }) else { throw MutationError.missingRecord }
        guard !category.isEmpty, category != "空", !(target.isOngoing && neighbour.isOngoing),
              RecordIntegrity.timeIssues(target, now: now).isEmpty, RecordIntegrity.timeIssues(neighbour, now: now).isEmpty else { throw MutationError.invalidTime }
        let left = target.startTime <= neighbour.startTime ? target : neighbour
        let right = target.startTime <= neighbour.startTime ? neighbour : target
        guard left.isOngoing || left.endTime >= right.startTime else { throw MutationError.notAdjacent }
        let ongoing = target.isOngoing ? target : neighbour.isOngoing ? neighbour : nil
        let merged = TimeRecord(id: ongoing?.id ?? target.id, category: category,
            subCategory: target.category == category ? target.subCategory : neighbour.subCategory,
            startTime: min(target.startTime, neighbour.startTime), endTime: ongoing == nil ? max(target.endTime, neighbour.endTime) : .distantFuture)
        let pieces = merged.isOngoing ? [merged] : try splitClosed(merged, now: now, calendar: calendar)
        return records.filter { $0.id != targetID && $0.id != neighbourID } + pieces
    }

    static func splitClosed(_ record: TimeRecord, now: Date, calendar: Calendar = .current) throws -> [TimeRecord] {
        guard !record.isOngoing else { throw MutationError.unfinishedSplit }
        guard RecordIntegrity.timeIssues(record, now: now).isEmpty else { throw MutationError.invalidTime }
        if record.startTime == record.endTime { return [record] }
        var parts: [TimeRecord] = [], cursor = record.startTime
        while cursor < record.endTime {
            guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor)), midnight > cursor else {
                throw MutationError.invalidBoundary
            }
            let end = min(midnight, record.endTime)
            parts.append(TimeRecord(id: parts.isEmpty ? record.id : segmentID(parent: record.id, start: cursor),
                category: record.category, subCategory: record.subCategory, startTime: cursor, endTime: end))
            cursor = end
        }
        guard parts.first?.startTime == record.startTime, parts.last?.endTime == record.endTime,
              abs(parts.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } - record.duration) < 0.001 else {
            throw MutationError.invalidBoundary
        }
        return parts
    }
    private static func segmentID(parent: UUID, start: Date) -> UUID {
        let hash = SHA256.hash(data: Data("\(parent.uuidString)|\(start.timeIntervalSinceReferenceDate)".utf8)).map { String(format: "%02x", $0) }.joined()
        let chars = Array(hash.prefix(32))
        return UUID(uuidString: String(chars[0..<8])+"-"+String(chars[8..<12])+"-"+String(chars[12..<16])+"-"+String(chars[16..<20])+"-"+String(chars[20..<32]))!
    }
}
