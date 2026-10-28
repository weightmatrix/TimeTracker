import Foundation

#if os(watchOS)
import WidgetKit
import SwiftUI
import AppIntents
import WatchConnectivity

struct WatchActionEntry: TimelineEntry {
    let date: Date
    let category: String
}

struct WatchActionProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchActionEntry {
        WatchActionEntry(date: Date(), category: "工作")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchActionEntry) -> Void) {
        completion(readEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchActionEntry>) -> Void) {
        let entry = readEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
    
    private func readEntry() -> WatchActionEntry {
        let shared = UserDefaults(suiteName: appGroupIdentifier)
        var category = "无"
        if let data = shared?.data(forKey: "sharedCurrentState"),
           let state = try? JSONDecoder().decode(CurrentState.self, from: data) {
            category = state.category
        }
        return WatchActionEntry(date: Date(), category: category)
    }
}

struct WatchActionComplicationView: View {
    let entry: WatchActionEntry
    
    var body: some View {
        Text(entry.category.prefix(2))
            .font(.system(size: 14, weight: .bold))
    }
}

struct NextActionIntent: AppIntent {
    static var title: LocalizedStringResource = "切换行动"
    static var description = IntentDescription("切换到下一个行动")
    
    func perform() async throws -> some IntentResult {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                session.sendMessage(["action": "next"], replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(["action": "next"])
            }
        }
        return .result()
    }
}

struct WatchActionComplication: Widget {
    let kind = "TimeTrackerWatchComplication"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: NextActionIntent.self, provider: WatchActionProvider()) { entry in
            WatchActionComplicationView(entry: entry)
        }
        .configurationDisplayName("切换行动")
        .description("一键切换当前行动")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular])
    }
}

@main
struct WatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchActionComplication()
    }
}
#endif
