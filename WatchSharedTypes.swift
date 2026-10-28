import Foundation

#if os(watchOS)
let appGroupIdentifier = "group.Han.TimeTracker"
let watchQuickActionsKey = "watchQuickActions_v1"

struct CurrentState: Codable, Equatable {
    let category: String
    let startTime: Date
}
#endif
