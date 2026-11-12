import Foundation

@main struct V173MutationTests {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let parse = ISO8601DateFormatter()
        func at(_ value: String) -> Date { parse.date(from: value)! }
        let now = at("2026-11-11T12:00:00+08:00")
        let ten = at("2026-11-11T10:00:00+08:00")
        let half = at("2026-11-11T10:30:00+08:00")
        let eleven = at("2026-11-11T11:00:00+08:00")
        let current = TimeRecord(category: "工作", startTime: ten, endTime: .distantFuture)

        let same = try RecordMutationEngine.add(records: [current],
            draft: TimeRecord(category: "工作", startTime: half, endTime: eleven), now: now, calendar: calendar)
        precondition(same.count == 1 && same[0].startTime == ten && same[0].isOngoing)

        let different = try RecordMutationEngine.add(records: [current],
            draft: TimeRecord(category: "生活", startTime: half, endTime: eleven), now: now, calendar: calendar)
        precondition(different.count == 3)
        precondition(different.map(\.category) == ["工作", "生活", "工作"])
        precondition(different[0].endTime == half && different[1].startTime == half)
        precondition(different[1].endTime == eleven && different[2].startTime == eleven && different[2].isOngoing)
        precondition(Set(different.map(\.id)).count == 3)

        let preceding = TimeRecord(category: "生活", startTime: at("2026-11-11T09:00:00+08:00"), endTime: ten)
        let sameInside = try RecordMutationEngine.add(records: [preceding, current],
            draft: TimeRecord(category: "工作", startTime: half, endTime: eleven), now: now, calendar: calendar)
        precondition(sameInside.count == 2 && sameInside[0].endTime == half)
        precondition(sameInside[1].startTime == half && sameInside[1].isOngoing)

        let moved = try RecordMutationEngine.replace(records: [current], id: current.id,
            with: TimeRecord(id: current.id, category: "生活", startTime: half, endTime: eleven), now: now, calendar: calendar)
        precondition(moved.map(\.category) == ["工作", "生活", "工作"])
        precondition(moved[1].id != current.id)

        let switched = try RecordMutationEngine.switchAction(records: [current], category: "生活",
            subCategory: "ignored", at: at("2026-11-11T11:30:47+08:00"), now: now, calendar: calendar)
        let junction = at("2026-11-11T11:30:00+08:00")
        precondition(switched.ended?.endTime == junction && switched.started?.startTime == junction)
        precondition(switched.records.count == 2 && switched.records[0].endTime == junction)
        precondition(switched.records[1].startTime == junction && switched.records[1].isOngoing)
        let noop = try RecordMutationEngine.switchAction(records: [current], category: "工作",
            subCategory: "different", at: eleven, now: now, calendar: calendar)
        precondition(noop.started == nil && noop.records == [current])

        let rapidFirst = try RecordMutationEngine.switchAction(records: [current], category: "生活",
            subCategory: nil, at: at("2026-11-11T11:30:05+08:00"), now: now, calendar: calendar)
        let rapidSecond = try RecordMutationEngine.switchAction(records: rapidFirst.records, category: "刚需",
            subCategory: nil, at: at("2026-11-11T11:30:55+08:00"), now: now, calendar: calendar)
        precondition(rapidFirst.started?.id != rapidSecond.started?.id)
        precondition(rapidSecond.records.last?.category == "刚需" && rapidSecond.records.last?.isOngoing == true)

        let yesterday = at("2026-11-10T23:30:00+08:00")
        let crossing = TimeRecord(category: "工作", startTime: yesterday, endTime: .distantFuture)
        let crossResult = try RecordMutationEngine.insert(records: [], draft: crossing, now: now, calendar: calendar)
        let midnight = at("2026-11-11T00:00:00+08:00")
        precondition(crossResult.count == 2 && crossResult[0].endTime == midnight)
        precondition(crossResult[1].startTime == midnight && crossResult[1].isOngoing)

        let future = TimeRecord(category: "生活", startTime: now.addingTimeInterval(60), endTime: .distantFuture)
        expectFailure { _ = try RecordMutationEngine.insert(records: [current], draft: future, now: now, calendar: calendar) }
        expectFailure { _ = try RecordMutationEngine.add(records: [current],
            draft: TimeRecord(category: "生活", startTime: half, endTime: now.addingTimeInterval(60)), now: now, calendar: calendar) }

        // Historical defects outside the edited interval must not block an unrelated edit.
        let old1 = TimeRecord(category: "工作", startTime: at("2026-11-09T08:00:00+08:00"), endTime: at("2026-11-09T09:30:00+08:00"))
        let old2 = TimeRecord(category: "生活", startTime: at("2026-11-09T09:00:00+08:00"), endTime: at("2026-11-09T10:00:00+08:00"))
        let unrelated = try RecordMutationEngine.add(records: [old1, old2, current],
            draft: TimeRecord(category: "生活", startTime: half, endTime: eleven), now: now, calendar: calendar)
        precondition(unrelated.contains(old1) && unrelated.contains(old2))

        let base = now.addingTimeInterval(-300 * 60)
        let categories = ["工作", "生活", "刚需"]
        let initial = (0..<5).map { index in
            TimeRecord(category: categories[index % categories.count],
                startTime: base.addingTimeInterval(Double(index * 60 * 60)),
                endTime: index == 4 ? .distantFuture : base.addingTimeInterval(Double((index + 1) * 60 * 60)))
        }
        var seed: UInt64 = 173
        func next(_ limit: Int) -> Int {
            seed = seed &* 6364136223846793005 &+ 1
            return Int((seed >> 32) % UInt64(limit))
        }
        for _ in 0..<300 {
            let startMinute = next(299)
            let endMinute = startMinute + 1 + next(300 - startMinute)
            let draft = TimeRecord(category: categories[next(categories.count)],
                startTime: base.addingTimeInterval(Double(startMinute * 60)),
                endTime: base.addingTimeInterval(Double(endMinute * 60)))
            let result = try RecordMutationEngine.add(records: initial, draft: draft, now: now, calendar: calendar)
            precondition(result.first?.startTime == base && result.last?.isOngoing == true)
            precondition(Set(result.map(\.id)).count == result.count)
            precondition(zip(result, result.dropFirst()).allSatisfy { $0.endTime == $1.startTime })
        }
        var sequential = initial
        for _ in 0..<100 {
            let startMinute = next(299)
            let endMinute = startMinute + 1 + next(300 - startMinute)
            let draft = TimeRecord(category: categories[next(categories.count)],
                startTime: base.addingTimeInterval(Double(startMinute * 60)),
                endTime: base.addingTimeInterval(Double(endMinute * 60)))
            sequential = try RecordMutationEngine.add(records: sequential, draft: draft, now: now, calendar: calendar)
            precondition(sequential.first?.startTime == base && sequential.last?.isOngoing == true)
            precondition(Set(sequential.map(\.id)).count == sequential.count)
            precondition(zip(sequential, sequential.dropFirst()).allSatisfy { $0.endTime == $1.startTime })
        }
        print("PASS: V173 containment, split, new edit ID, minute junction, Category no-op, Ongoing midnight, future rejection")
    }

    static func expectFailure(_ work: () throws -> Void) {
        do { try work(); fatalError("Expected rejection") } catch { }
    }
}
