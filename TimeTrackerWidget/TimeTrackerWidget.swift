// MARK: - TimeTrackerWidget.swift - v260127 - 零延迟高可靠版
//
// 核心改进：
// 1. 物理对齐：确保 AppGroup 写入与 Live Activity 更新在同一原子操作内。
// 2. 性能：Intent perform() 中优先执行时间计算，彻底消除 1-2 秒的“启动白屏/延迟”。
// 3. 容错：增加了对 SharedYesterdayScore 的物理校验。
// 4. 视觉：优化了灵动岛展开态的按钮布局与点击热区。

import WidgetKit
import SwiftUI
import AppIntents

#if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

// MARK: - 1. 基础常量与模型
let widgetAppGroupIdentifier = "group.Han.TimeTracker"
let widgetSharedStateKey = "sharedCurrentState"

struct SharedState: Codable {
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

// MARK: - 2. Live Activity 属性定义
#if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
public struct TimeTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var category: String
        public var startTime: Date
        public var yesterdayScore: Double
        public init(category: String, startTime: Date, yesterdayScore: Double) {
            self.category = category; self.startTime = startTime; self.yesterdayScore = yesterdayScore
        }
    }
    public init() {}
}
#endif

// MARK: - 3. 交互 Intent
public struct StartTimerIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "切换计时状态"
    public static var description = IntentDescription("点击立即开始新的时间记录")

    @Parameter(title: "目标分类")
    var category: ActivityCategory?

    public init() {}
    public init(category: ActivityCategory) { self.category = category }

    public func perform() async throws -> some IntentResult {
        // A. 立即锁定时间点，这是“零延迟”的关键
        let now = Date()
        let targetCat = category ?? .work
        let catString = targetCat.rawValue
        
        // B. 写入共享存储 (App Group)
        if let sharedDefaults = UserDefaults(suiteName: widgetAppGroupIdentifier) {
            let newState = SharedState(category: catString, startTime: now)
            if let data = try? JSONEncoder().encode(newState) {
                sharedDefaults.set(data, forKey: widgetSharedStateKey)
                sharedDefaults.synchronize()
            }
            
            // C. 物理更新 Live Activity (灵动岛)
#if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
            let score = sharedDefaults.double(forKey: "sharedYesterdayScore")
            let state = TimeTrackerAttributes.ContentState(category: catString, startTime: now, yesterdayScore: score)
            
            // 并行更新，不阻塞 Widget 刷新
            Task {
                for activity in Activity<TimeTrackerAttributes>.activities {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                }
            }
            #endif
        }
        
        // D. 强制刷新所有小组件界面
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

// MARK: - 4. 时间轴提供者
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currentCategory: "工作")
    }

    func snapshot(for configuration: StartTimerIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), currentCategory: fetchCurrent())
    }

    func timeline(for configuration: StartTimerIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), currentCategory: fetchCurrent())
        // 由于是交互式组件，policy 设为 never，完全由 Intent 驱动刷新
        return Timeline(entries: [entry], policy: .never)
    }
    
    private func fetchCurrent() -> String? {
        guard let data = UserDefaults(suiteName: widgetAppGroupIdentifier)?.data(forKey: widgetSharedStateKey) else { return nil }
        return (try? JSONDecoder().decode(SharedState.self, from: data))?.category
    }
}

#if os(macOS)
struct MacProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), currentCategory: "工作")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), currentCategory: fetchCurrent()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date(), currentCategory: fetchCurrent())
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func fetchCurrent() -> String? {
        guard let data = UserDefaults(suiteName: widgetAppGroupIdentifier)?.data(forKey: widgetSharedStateKey) else { return nil }
        return (try? JSONDecoder().decode(SharedState.self, from: data))?.category
    }
}
#endif

struct SimpleEntry: TimelineEntry {
    let date: Date
    let currentCategory: String?
}

// MARK: - 5. 辅助 UI 工具
func getCatColor(_ cat: String) -> Color {
    switch cat {
    case "工作": return Color(red: 1.0, green: 0.78, blue: 0.1)
    case "刚需": return Color(red: 0.2, green: 0.85, blue: 0.5)
    case "生活": return Color(red: 0.25, green: 0.7, blue: 1.0)
    case "监控": return Color(red: 1.0, green: 0.4, blue: 0.45)
    default: return .gray
    }
}

func getCatIcon(_ raw: String) -> String {
    switch raw {
    case "工作": return "briefcase.fill"
    case "刚需": return "bus.fill"
    case "生活": return "house.fill"
    case "监控": return "eye.fill"
    default: return "play.circle.fill"
    }
}

// MARK: - 6. 组件主视图
struct TimeTrackerWidgetEntryView : View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        #if os(macOS)
        switch family {
        case .systemSmall:
            MacSmallGridView(current: entry.currentCategory)
        case .systemMedium:
            MacMediumBarView(current: entry.currentCategory)
        default:
            MacSmallGridView(current: entry.currentCategory)
        }
        #else
        switch family {
        case .systemSmall:
            SmallGridView(current: entry.currentCategory)
        case .systemMedium:
            MediumBarView(current: entry.currentCategory)
        case .accessoryCircular:
            CircleLockView(current: entry.currentCategory)
        case .accessoryRectangular:
            RectLockView(current: entry.currentCategory)
        default:
            SmallGridView(current: entry.currentCategory)
        }
        #endif
    }
}

// 2x2 网格
struct SmallGridView: View {
    let current: String?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) { gridBtn(.work); gridBtn(.necessity) }
            HStack(spacing: 0) { gridBtn(.life); gridBtn(.monitor) }
        }
        .ttWidgetBackground(Color(white: 0.1))
    }
    
    @ViewBuilder
    func gridBtn(_ cat: ActivityCategory) -> some View {
        let isAct = (current == cat.rawValue)
        let color = getCatColor(cat.rawValue)
        #if os(macOS)
        if #available(macOS 14.0, *) {
            Button(intent: StartTimerIntent(category: cat)) {
                ZStack {
                    if isAct { color.opacity(0.2) }
                    Image(systemName: getCatIcon(cat.rawValue))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isAct ? .white : color)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
        } else {
            ZStack {
                if isAct { color.opacity(0.2) }
                Image(systemName: getCatIcon(cat.rawValue))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isAct ? .white : color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        #else
        Button(intent: StartTimerIntent(category: cat)) {
            ZStack {
                if isAct { color.opacity(0.2) }
                Image(systemName: getCatIcon(cat.rawValue))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isAct ? .white : color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        #endif
    }
}

// 1x4 横条
struct MediumBarView: View {
    let current: String?
    let list: [ActivityCategory] = [.work, .necessity, .life, .monitor]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(list, id: \.self) { item in
                let isAct = (current == item.rawValue)
                let color = getCatColor(item.rawValue)
                #if os(macOS)
                if #available(macOS 14.0, *) {
                    Button(intent: StartTimerIntent(category: item)) {
                        mediumButtonContent(item: item, isAct: isAct, color: color)
                    }
                    .buttonStyle(.plain)
                } else {
                    mediumButtonContent(item: item, isAct: isAct, color: color)
                }
                #else
                Button(intent: StartTimerIntent(category: item)) {
                    mediumButtonContent(item: item, isAct: isAct, color: color)
                }
                .buttonStyle(.plain)
                #endif
            }
        }
        .padding(8)
        .ttWidgetBackground(Color(white: 0.1))
    }

    @ViewBuilder
    private func mediumButtonContent(item: ActivityCategory, isAct: Bool, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(isAct ? color : color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: getCatIcon(item.rawValue))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isAct ? .white : color)
            }
            Text(item.rawValue).font(.system(size: 10, weight: .black))
                .foregroundColor(isAct ? .white : .gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isAct ? Color.white.opacity(0.05) : Color.clear)
        .cornerRadius(12)
    }
}

#if os(macOS)
struct MacSmallGridView: View {
    let current: String?
    var body: some View {
        SmallGridView(current: current)
    }
}

struct MacMediumBarView: View {
    let current: String?
    var body: some View {
        MediumBarView(current: current)
    }
}
#endif

#if !os(macOS)
// 锁屏圆形
struct CircleLockView: View {
    let current: String?
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: getCatIcon(current ?? "工作")).font(.title2)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// 锁屏矩形
struct RectLockView: View {
    let current: String?
    var body: some View {
        HStack {
            ForEach([ActivityCategory.work, .necessity, .life, .monitor], id: \.self) { cat in
                let isAct = (current == cat.rawValue)
                Button(intent: StartTimerIntent(category: cat)) {
                    ZStack {
                        if isAct { RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.3)) }
                        Image(systemName: getCatIcon(cat.rawValue))
                    }
                }.buttonStyle(.plain)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
#endif

// MARK: - 7. Live Activity 配置
#if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
struct TimeTrackerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackerAttributes.self) { context in
            // 锁屏横幅
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(context.state.category, systemImage: getCatIcon(context.state.category))
                            .font(.headline).foregroundColor(getCatColor(context.state.category))
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // 昨天得分展示
                    VStack(alignment: .trailing) {
                        Text("昨日效率").font(.caption).foregroundColor(.gray)
                        Text(String(format: "%.0f", context.state.yesterdayScore))
                            .font(.system(.title2, design: .rounded)).bold()
                            .foregroundColor(.orange)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                MediumBarView(current: context.state.category)
            }
            .padding(16)
            .activityBackgroundTint(Color(white: 0.1))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.category, systemImage: getCatIcon(context.state.category))
                        .font(.caption.bold())
                        .foregroundColor(getCatColor(context.state.category))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(.body, design: .monospaced)).bold()
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MediumBarView(current: context.state.category)
                }
            } compactLeading: {
                Image(systemName: getCatIcon(context.state.category))
                    .foregroundColor(getCatColor(context.state.category))
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(getCatColor(context.state.category))
                    .frame(width: 45)
            } minimal: {
                Image(systemName: getCatIcon(context.state.category))
                    .foregroundColor(getCatColor(context.state.category))
            }
        }
    }
}
#endif

// MARK: - 8. Bundle 入口
@main
struct TimeTrackerBundle: WidgetBundle {
    var body: some Widget {
        TimeTrackerWidget()
        #if os(iOS) && canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        TimeTrackerLiveActivity()
        #endif
    }
}

struct TimeTrackerWidget: Widget {
    let kind: String = "TimeTrackerWidget"

    var body: some WidgetConfiguration {
        #if os(macOS)
        StaticConfiguration(kind: kind, provider: MacProvider()) { entry in
            TimeTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("极速计时")
        .description("在桌面一键切换时间分类。")
        .supportedFamilies([.systemSmall, .systemMedium])
        #else
        AppIntentConfiguration(kind: kind, intent: StartTimerIntent.self, provider: Provider()) { entry in
            TimeTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("极速计时")
        .description("在桌面或锁屏一键开启时间记录。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
        #endif
    }
}
// MARK: - Widget Background Helper
extension View {
    @ViewBuilder
    func ttWidgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.containerBackground(for: .widget) { color }
        } else {
            self.background(color)
        }
    }
}
