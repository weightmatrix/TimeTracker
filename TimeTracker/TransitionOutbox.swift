import Foundation

/// A switch is an event, not just a replacement for the most recent category.
struct TimerTransitionEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let sourceDeviceID: UUID
    let sourceSequence: UInt64
    let previousRecordID: UUID?
    let newRecordID: UUID
    let category: String
    let startedAt: Double
    let committedAt: Double
}

final class TransitionOutbox {
    enum OutboxError: Error { case invalidTransition }
    private struct State: Codable {
        var deviceID: UUID
        var nextSequence: UInt64
        var pending: [TimerTransitionEvent]
    }

    private let url: URL
    private let lock = NSLock()
    private var state: State

    init(url: URL) throws {
        self.url = url
        if FileManager.default.fileExists(atPath: url.path) {
            state = try JSONDecoder().decode(State.self, from: Data(contentsOf: url))
        } else {
            state = State(deviceID: UUID(), nextSequence: 1, pending: [])
            try persist(state)
        }
    }

    @discardableResult
    func enqueue(previousRecordID: UUID?, newRecordID: UUID, category: String,
                 startedAt: Date, committedAt: Date) throws -> TimerTransitionEvent {
        lock.lock(); defer { lock.unlock() }
        guard !category.isEmpty, startedAt <= committedAt,
              state.nextSequence < UInt64.max else { throw OutboxError.invalidTransition }
        let event = TimerTransitionEvent(id: UUID(), sourceDeviceID: state.deviceID,
            sourceSequence: state.nextSequence, previousRecordID: previousRecordID,
            newRecordID: newRecordID, category: category,
            startedAt: startedAt.timeIntervalSince1970,
            committedAt: committedAt.timeIntervalSince1970)
        var next = state
        next.nextSequence += 1
        next.pending.append(event)
        try persist(next)
        state = next
        return event
    }

    func pending() -> [TimerTransitionEvent] {
        lock.lock(); defer { lock.unlock() }
        return state.pending
    }

    func acknowledge(_ id: UUID) throws {
        lock.lock(); defer { lock.unlock() }
        guard state.pending.contains(where: { $0.id == id }) else { return }
        var next = state
        next.pending.removeAll { $0.id == id }
        try persist(next)
        state = next
    }

    private func persist(_ value: State) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
    }
}
