import AppIntents
import Foundation
import WidgetKit

#if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit

private let liveActivityIntentAppGroupIdentifier = "group.Han.TimeTracker"
private let liveActivityIntentSharedStateKey = "sharedCurrentState"
private let liveActivityIntentPendingTimerActionKey = "pendingTimerAction_v1"

private struct LiveActivityIntentSharedState: Codable {
    let category: String
    let startTime: Date
}

private struct LiveActivityIntentPendingTimerAction: Codable {
    let id: UUID
    let category: String
    let startTime: Date
}

public enum ActivityCategory: String, AppEnum {
    case work = "工作", necessity = "刚需", life = "生活", monitor = "监控", gap = "空"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "分类"
    public static var caseDisplayRepresentations: [ActivityCategory: DisplayRepresentation] = [
        .work: "工作", .necessity: "刚需", .life: "生活", .monitor: "监控", .gap: "空"
    ]
}

public struct LiveActivityStartTimerIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "切换实时计时状态"
    public static var description = IntentDescription("从实时通知立即切换当前时间记录")

    @Parameter(title: "目标分类")
    var category: ActivityCategory?

    public init() {}
    public init(category: ActivityCategory) { self.category = category }

    public func perform() async throws -> some IntentResult {
        await TimerActionIntentEngine.switchTo(category: category ?? .work)
        return .result()
    }
}

public struct SwitchTimerCategoryIntent: AppIntent {
    public static var title: LocalizedStringResource = "切换当前行动"
    public static var description = IntentDescription("从快捷指令切换当前行动，并立即刷新灵动岛和实时通知")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "目标分类")
    var category: ActivityCategory?

    public init() {}
    public init(category: ActivityCategory) { self.category = category }

    public func perform() async throws -> some IntentResult {
        await TimerActionIntentEngine.switchTo(category: category ?? .work)
        return .result()
    }
}

public struct SwitchToWorkIntent: AppIntent {
    public static var title: LocalizedStringResource = "切换到工作"
    public static var description = IntentDescription("切换当前行动为工作，并立即刷新灵动岛和实时通知")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        await TimerActionIntentEngine.switchTo(category: .work)
        return .result()
    }
}

public struct SwitchToLifeIntent: AppIntent {
    public static var title: LocalizedStringResource = "切换到生活"
    public static var description = IntentDescription("切换当前行动为生活，并立即刷新灵动岛和实时通知")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        await TimerActionIntentEngine.switchTo(category: .life)
        return .result()
    }
}

public struct TimeTrackerShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SwitchToWorkIntent(),
            phrases: [
                "用 \(.applicationName) 切换到工作",
                "\(.applicationName) 工作",
                "用 \(.applicationName) 开始工作计时"
            ],
            shortTitle: "切换到工作",
            systemImageName: "briefcase.fill"
        )
        AppShortcut(
            intent: SwitchToLifeIntent(),
            phrases: [
                "用 \(.applicationName) 切换到生活",
                "\(.applicationName) 生活",
                "用 \(.applicationName) 开始生活计时"
            ],
            shortTitle: "切换到生活",
            systemImageName: "house.fill"
        )
        AppShortcut(
            intent: SwitchTimerCategoryIntent(),
            phrases: [
                "用 \(.applicationName) 切换当前行动",
                "\(.applicationName) 切换行动"
            ],
            shortTitle: "切换行动",
            systemImageName: "timer"
        )
    }
}

private enum TimerActionIntentEngine {
    static func switchTo(category: ActivityCategory, at startTime: Date = Date()) async {
        let startTime = minuteAligned(startTime)
        let catString = category.rawValue
        let sharedDefaults = writeSharedTransition(category: catString, startTime: startTime)
        let score = sharedDefaults?.double(forKey: "sharedYesterdayScore") ?? 0
        let state = TimeTrackerAttributes.ContentState(category: catString, startTime: startTime, yesterdayScore: score)
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<TimeTrackerAttributes>.activities {
            await activity.update(content)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func writeSharedTransition(category: String, startTime: Date) -> UserDefaults? {
        guard let sharedDefaults = UserDefaults(suiteName: liveActivityIntentAppGroupIdentifier) else { return nil }
        let newState = LiveActivityIntentSharedState(category: category, startTime: startTime)
        if let data = try? JSONEncoder().encode(newState) {
            sharedDefaults.set(data, forKey: liveActivityIntentSharedStateKey)
        }
        let action = LiveActivityIntentPendingTimerAction(id: UUID(), category: category, startTime: startTime)
        if let data = try? JSONEncoder().encode(action) {
            sharedDefaults.set(data, forKey: liveActivityIntentPendingTimerActionKey)
        }
        sharedDefaults.synchronize()
        return sharedDefaults
    }

    private static func minuteAligned(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return cal.date(from: comps) ?? date
    }
}
#endif
