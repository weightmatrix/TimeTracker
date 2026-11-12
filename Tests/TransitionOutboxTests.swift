import Foundation

@main struct TransitionOutboxTests {
    static func main() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("outbox.json")
        let first = try TransitionOutbox(url: url)
        let now = Date()
        let ids = (0..<100).map { _ in UUID() }
        for index in ids.indices {
            _ = try first.enqueue(previousRecordID: index == 0 ? nil : ids[index - 1],
                newRecordID: ids[index], category: index.isMultiple(of: 2) ? "工作" : "生活",
                startedAt: now.addingTimeInterval(Double(index)),
                committedAt: now.addingTimeInterval(Double(index)))
        }
        let restored = try TransitionOutbox(url: url)
        let events = restored.pending()
        precondition(events.count == 100)
        precondition(Set(events.map(\.id)).count == 100)
        precondition(events.map(\.sourceSequence) == Array(1...100).map(UInt64.init))
        precondition(Set(events.map(\.sourceDeviceID)).count == 1)
        precondition(events[1].previousRecordID == events[0].newRecordID)
        try restored.acknowledge(events[1].id)
        let remaining = try TransitionOutbox(url: url).pending()
        precondition(remaining.count == 99 && remaining[0] == events[0] && remaining[1] == events[2])
        print("PASS: 100 rapid switches persist individually; restart, identity, order, and selective ack")
    }
}
