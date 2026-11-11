import Foundation
import CryptoKit

nonisolated enum RecordMutationEngine {
    enum MutationError: LocalizedError {
        case invalidTime, staleClick, missingRecord, unfinishedSplit, invalidBoundary, notAdjacent, invalidChain
        var errorDescription: String? {
            switch self {
            case .invalidTime: return "记录时间异常，本次修改未保存。"
            case .staleClick: return "记录已被更新，点击时间早于当前记录，请重试。"
            case .missingRecord: return "记录已变化，请重新打开后修改。"
            case .unfinishedSplit: return "进行中的记录不能当作已结束记录切割。"
            case .invalidBoundary: return "无法安全切割这段时间，本次修改未保存。"
            case .notAdjacent: return "这两条记录之间有空白时间，未自动填补或合并。"
            case .invalidChain: return "记录边界未能连续，本次修改未保存。"
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
        let junction = calendar.dateInterval(of: .minute, for: click)?.start ?? click
        guard !category.isEmpty, category != "空", junction.timeIntervalSinceReferenceDate.isFinite,
              click <= now, junction <= now else { throw MutationError.invalidTime }
        let clean = RecordIntegrity.sanitize(records, now: now)
        let current = clean.valid.last(where: \.isOngoing)
        if let current, current.category == category {
            return SwitchResult(records: clean.valid, rejected: clean.rejected, ended: nil, started: nil)
        }
        guard current != nil || clean.valid.isEmpty else { throw MutationError.missingRecord }
        guard current.map({ $0.startTime <= junction }) ?? true else { throw MutationError.staleClick }
        var history = clean.valid.filter { !$0.isOngoing }
        var ended: TimeRecord?
        if var closed = current {
            closed.endTime = junction
            ended = closed
            history = try insert(records: history, draft: closed, now: now, calendar: calendar)
        }
        let started = TimeRecord(category: category, startTime: junction, endTime: .distantFuture)
        history = try insert(records: history, draft: started, now: now, calendar: calendar)
        return SwitchResult(records: history, rejected: clean.rejected, ended: ended, started: started)
    }
    static func replace(records: [TimeRecord], id: UUID, with draft: TimeRecord, now: Date,
                        calendar: Calendar = .current) throws -> [TimeRecord] {
        guard records.contains(where: { $0.id == id }) else { throw MutationError.missingRecord }
        let newRecord = TimeRecord(category: draft.category, subCategory: draft.subCategory,
            startTime: draft.startTime, endTime: draft.endTime)
        return try insert(records: records, draft: newRecord, now: now, calendar: calendar)
    }
    static func add(records: [TimeRecord], draft: TimeRecord, now: Date, calendar: Calendar = .current) throws -> [TimeRecord] {
        guard !draft.isOngoing else { throw MutationError.invalidTime }
        return try insert(records: records, draft: draft, now: now, calendar: calendar)
    }

    /// V173: insert a new record over the existing continuous chain. The old edited record
    /// stays in the chain and participates in the same containment and boundary rules.
    static func insert(records: [TimeRecord], draft: TimeRecord, now: Date,
                       calendar: Calendar = .current) throws -> [TimeRecord] {
        guard !draft.category.isEmpty, !draft.isGap,
              RecordIntegrity.timeIssues(draft, now: now).isEmpty else { throw MutationError.invalidTime }
        guard RecordIntegrity.issues(records, now: now).isEmpty else { throw MutationError.invalidChain }
        var a = draft
        var chain = records.sorted { $0.startTime < $1.startTime }
        let existingGaps = Set(zip(chain, chain.dropFirst()).compactMap { pair -> String? in
            pair.0.endTime < pair.1.startTime ? gapKey(pair.0, pair.1) : nil
        })
        let existingOverlappingBoundaries = Set(zip(chain, chain.dropFirst()).compactMap { pair -> String? in
            pair.0.endTime > pair.1.startTime ? boundaryKey(pair.0, pair.1) : nil
        })
        let existingOverlaps = Set(RecordIntegrity.issues(records, now: now, checkOverlaps: true)
            .filter { $0.code == "overlap" }.map(\.signature))
        let endOfA = a.isOngoing ? Date.distantFuture : a.endTime

        // 2: remove records fully covered by A.
        chain.removeAll { a.startTime <= $0.startTime && endOfA >= $0.endTime }

        // 3: left overlap. At most one record can cross this boundary in a valid chain.
        if let index = chain.firstIndex(where: { $0.startTime < a.startTime && $0.endTime > a.startTime }) {
            var c = chain[index]
            let hasPrevious = index > 0
            if endOfA >= c.endTime {
                if c.category == a.category {
                    if hasPrevious { chain[index - 1].endTime = a.startTime }
                    else { a.startTime = c.startTime }
                    chain.remove(at: index)
                } else {
                    c.endTime = a.startTime
                    if c.duration <= 60 {
                        if hasPrevious { chain[index - 1].endTime = a.startTime }
                        else { a.startTime = c.startTime }
                        chain.remove(at: index)
                    } else { chain[index] = c }
                }
            } else if c.category == a.category {
                if hasPrevious { chain[index - 1].endTime = a.startTime }
                else { a.startTime = c.startTime }
                a.endTime = c.endTime
                chain.remove(at: index)
            } else {
                let prefix = TimeRecord(id: segmentID(parent: c.id, start: c.startTime, salt: "left"),
                    category: c.category, subCategory: c.subCategory, startTime: c.startTime, endTime: a.startTime)
                c.startTime = a.startTime
                chain[index] = c
                if prefix.duration <= 60 {
                    if hasPrevious { chain[index - 1].endTime = a.startTime }
                    else { a.startTime = prefix.startTime }
                } else { chain.insert(prefix, at: index) }
            }
        }

        // 4: absorb a same-category record touching A on the left.
        while let index = chain.firstIndex(where: { $0.endTime == a.startTime && $0.category == a.category }) {
            a.startTime = chain.remove(at: index).startTime
        }

        // 5: right overlap. Ongoing A has no actual right boundary.
        if !a.isOngoing, let index = chain.firstIndex(where: {
            $0.startTime < a.endTime && $0.endTime > a.endTime
        }) {
            var c = chain[index]
            guard a.startTime <= c.startTime else { throw MutationError.invalidChain }
            if c.category == a.category {
                if index + 1 < chain.count { chain[index + 1].startTime = a.endTime }
                else { a.endTime = c.endTime }
                chain.remove(at: index)
            } else {
                c.startTime = a.endTime
                if !c.isOngoing && c.duration <= 60 && index + 1 < chain.count {
                    chain[index + 1].startTime = a.endTime
                    chain.remove(at: index)
                } else { chain[index] = c }
            }
        }

        // 6: absorb touching records on the right by Category only.
        while !a.isOngoing, let index = chain.firstIndex(where: { $0.startTime == a.endTime && $0.category == a.category }) {
            a.endTime = chain.remove(at: index).endTime
        }
        chain.append(a)
        chain.sort { $0.startTime < $1.startTime }

        // 7: split at calendar midnights; never treat the Ongoing sentinel as a date.
        var result: [TimeRecord] = []
        for record in chain {
            if record.isOngoing {
                var cursor = record.startTime
                while let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor)), midnight <= now {
                    result.append(TimeRecord(id: cursor == record.startTime ? record.id : segmentID(parent: record.id, start: cursor),
                        category: record.category, subCategory: record.subCategory, startTime: cursor, endTime: midnight))
                    cursor = midnight
                }
                result.append(TimeRecord(id: cursor == record.startTime ? record.id : segmentID(parent: record.id, start: cursor),
                    category: record.category, subCategory: record.subCategory, startTime: cursor, endTime: .distantFuture))
            } else { result += try splitClosed(record, now: now, calendar: calendar) }
        }
        result.sort { $0.startTime < $1.startTime }
        if let ongoingIndex = result.firstIndex(where: \.isOngoing) {
            let ongoing = result.remove(at: ongoingIndex)
            result.append(ongoing)
        }
        let resultIssues = RecordIntegrity.issues(result, now: now, checkOverlaps: true)
        guard resultIssues.allSatisfy({ $0.code == "overlap" && existingOverlaps.contains($0.signature) }) else {
            throw MutationError.invalidChain
        }
        for pair in zip(result, result.dropFirst()) {
            if pair.0.endTime == pair.1.startTime { continue }
            if pair.0.endTime < pair.1.startTime, existingGaps.contains(gapKey(pair.0, pair.1)) { continue }
            guard pair.0.endTime > pair.1.startTime,
                  existingOverlappingBoundaries.contains(boundaryKey(pair.0, pair.1)) else { throw MutationError.invalidChain }
        }
        return result
    }
    private static func boundaryKey(_ left: TimeRecord, _ right: TimeRecord) -> String {
        "\(left.id)|\(left.endTime.timeIntervalSinceReferenceDate)|\(right.id)|\(right.startTime.timeIntervalSinceReferenceDate)"
    }
    private static func gapKey(_ left: TimeRecord, _ right: TimeRecord) -> String {
        "\(left.endTime.timeIntervalSinceReferenceDate)|\(right.startTime.timeIntervalSinceReferenceDate)"
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
    private static func segmentID(parent: UUID, start: Date, salt: String = "") -> UUID {
        let source = "\(parent.uuidString)|\(start.timeIntervalSinceReferenceDate)" + (salt.isEmpty ? "" : "|\(salt)")
        let hash = SHA256.hash(data: Data(source.utf8)).map { String(format: "%02x", $0) }.joined()
        let chars = Array(hash.prefix(32))
        return UUID(uuidString: String(chars[0..<8])+"-"+String(chars[8..<12])+"-"+String(chars[12..<16])+"-"+String(chars[16..<20])+"-"+String(chars[20..<32]))!
    }
}
