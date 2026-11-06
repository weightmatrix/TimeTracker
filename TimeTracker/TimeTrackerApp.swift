// MARK: - 全局完整代码 - 整合版 (UI: v251209 | Core: v20)
//
//  TimeTrackerApp.swift
//  TimeTracker
//
//  Created by Han on 2024.
//

import Combine
import UniformTypeIdentifiers
import WidgetKit
#if os(iOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
#endif
import EventKit
import UserNotifications
import SwiftUI
import WebKit
// MARK: - 声音管理器 (完整代码)
import AudioToolbox
import Foundation
import CryptoKit
import StoreKit
import CoreText

struct LPActiveEditSession {
    var nodeID: UUID?
    var draftText: String = ""
    var originalText: String = ""
    var token: Int = 0
}
// 【核心修复】
// 1. 只有在“是非 Mac Catalyst 的 iOS 环境”才允许导入 ActivityKit
// 2. 这样在 Mac 上编译时，编译器根本不知道 ActivityKit 的存在，也就不会去检查里面的 API
#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

// MARK: - 平台兼容层 (macOS)
#if os(macOS)
typealias UIColor = NSColor
typealias UIFont = NSFont
typealias UIFontDescriptor = NSFontDescriptor
typealias UIBezierPath = NSBezierPath
typealias UIImage = NSImage
typealias UIScreen = NSScreen
typealias UIEdgeInsets = NSEdgeInsets

extension NSScreen {
    var bounds: CGRect { frame }
    var scale: CGFloat { backingScaleFactor }
}

extension NSImage {
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    func pngData() -> Data? {
        guard let cgImage = cgImageForExport() else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let cgImage = cgImageForExport() else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    private func cgImageForExport() -> CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}

extension NSColor {
    static var secondarySystemBackground: NSColor { NSColor.windowBackgroundColor }
}

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        self.init(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
}

extension NSFontDescriptor.SymbolicTraits {
    static let traitBold: NSFontDescriptor.SymbolicTraits = .bold
    static let traitItalic: NSFontDescriptor.SymbolicTraits = .italic
}

extension UIFont {
    static var familyNames: [String] { NSFontManager.shared.availableFontFamilies }
    static func fontNames(forFamilyName family: String) -> [String] {
        let members = NSFontManager.shared.availableMembers(ofFontFamily: family) ?? []
        return members.compactMap { $0.first as? String }
    }
}

extension UIScreen {
    static var mainSafe: UIScreen { NSScreen.main ?? NSScreen.screens.first! }
}

extension Image {
    init(uiImage: UIImage) {
        self.init(nsImage: uiImage)
    }
}

@available(macOS 13.0, *)
extension ImageRenderer {
    var uiImage: UIImage? { nsImage }
}

struct NavigationBarItem {
    enum TitleDisplayMode {
        case automatic
        case inline
        case large
    }
}

final class UIImpactFeedbackGenerator {
    enum FeedbackStyle {
        case light
        case medium
        case heavy
    }

    init(style: FeedbackStyle) {}
    func impactOccurred() {}
}

enum EditMode {
    case inactive
    case active

    var isEditing: Bool { self == .active }
}

private struct EditModeKey: EnvironmentKey {
    static let defaultValue: Binding<EditMode>? = nil
}

extension EnvironmentValues {
    var editMode: Binding<EditMode>? {
        get { self[EditModeKey.self] }
        set { self[EditModeKey.self] = newValue }
    }
}

struct EditButton: View {
    var body: some View { EmptyView() }
}

extension ToolbarItemPlacement {
    static var navigationBar: ToolbarItemPlacement { .automatic }
    static var topBarLeading: ToolbarItemPlacement { .automatic }
    static var topBarTrailing: ToolbarItemPlacement { .automatic }
    static var tabBar: ToolbarItemPlacement { .automatic }
}

extension ToolbarPlacement {
    static var navigationBar: ToolbarPlacement { .automatic }
    static var tabBar: ToolbarPlacement { .automatic }
}

enum UIKeyboardType {
    case `default`
    case numberPad
    case numbersAndPunctuation
}

enum TextInputAutocapitalization {
    case never
    case words
    case sentences
    case characters
}

extension View {
    func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization) -> some View { self }
    func keyboardType(_ type: UIKeyboardType) -> some View { self }
}
#endif

#if os(iOS)
extension UIScreen {
    static var mainSafe: UIScreen { UIScreen.main }
}
#endif

extension View {
    @ViewBuilder
    func ttNavigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(displayMode)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ttSearchable(text: Binding<String>, prompt: String) -> some View {
        #if os(iOS)
        self.searchable(text: text, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
        #else
        self.searchable(text: text, prompt: Text(prompt))
        #endif
    }

    @ViewBuilder
    func ttListStyleInsetGrouped() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ttPageTabViewStyle() -> some View {
        #if os(iOS)
        self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }

    @ViewBuilder
    func ttToolbarBackground(_ visibility: Visibility, for placement: ToolbarPlacement) -> some View {
        #if os(iOS)
        self.toolbarBackground(visibility, for: placement)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ttToolbarColorScheme(_ scheme: ColorScheme, for placement: ToolbarPlacement) -> some View {
        #if os(iOS)
        self.toolbarColorScheme(scheme, for: placement)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ttToolbarHidden(for placement: ToolbarPlacement) -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: placement)
        #else
        self
        #endif
    }
}

// MARK: - EKCalendar 协议扩展 - v1 - 适配 SwiftUI 弹窗标识
//
// extension EKCalendar
// (逻辑：实现 Identifiable 协议，以便在任务视图中通过 .sheet(item:) 弹出编辑界面。)

#if canImport(EventKit)
import EventKit

extension EKCalendar: @retroactive Identifiable {
    public var id: String {
        return self.calendarIdentifier
    }
}
#endif


// MARK: - 国际化管理器 (I18n) - v58 - 修复语言判定与补全词条

struct I18n {
    enum Key {
        case cat_work, cat_necessity, cat_life, cat_monitor, cat_gap
        case tab_home, tab_tasks, tab_calendar, tab_goals, tab_records, tab_pomo, tab_settings
        case tab_mental_math
        case app_name, cancel, save, delete, confirm, edit, done, unknown, add
        case today, yesterday, tomorrow
        case subtitle_timer, waiting_start, tap_to_edit, ongoing, update_status
        case start_time, end_time_limit, connect_prev, connect_next, equal_start, equal_end, now
        case set_photo, save_record, edit_record_title, add_record, add_record_title
        case task_title, task_all, task_scheduled, task_add_placeholder
        case cal_settings, cal_view_day, cal_view_week, cal_view_month, cal_today
        case event_add_title, event_name, event_location, event_cat_link, event_allday, event_alarm, event_calendar, event_note, event_placeholder
        case goal_duration, goal_efficiency, goal_total_score, goal_week_overview, goal_month_review, to_be_improved
        case rec_add_new, rec_no_records, rec_swipe_hint
        case pomo_focus, pomo_paused, pomo_break, pomo_idle, pomo_cycle, pomo_preset, pomo_start_btn, pomo_stop_btn, pomo_skip_break
        case set_center, set_subtitle, set_func_config, set_func_desc, set_data_manage, set_data_desc
        case set_timer_magnet, set_style_select, set_pomo_config, set_pomo_sound, set_pomo_duration, set_pomo_split, set_pomo_short, set_pomo_long, set_pomo_interval, set_pomo_auto
        case set_general, set_cal_auto, set_show_completed
        case math_solved, math_correct, math_input, math_hint, math_reset, math_success
        
        var stringKey: String { return String(describing: self) }
    }

    static func t(_ key: Key) -> String {
        let localized = NSLocalizedString(key.stringKey, comment: "")
        if localized == key.stringKey {
            // 【165号修复】：改进语言检测逻辑，确保中文首选
            let prefLang = Locale.preferredLanguages.first ?? ""
            let isChinese = prefLang.contains("zh")
            return fallback(key, isChinese: isChinese)
        }
        return localized
    }
    
    private static func fallback(_ key: Key, isChinese: Bool) -> String {
        switch key {
        case .tab_mental_math: return isChinese ? "口算" : "Mental Math"
        case .math_solved: return isChinese ? "已练习" : "Solved"
        case .math_correct: return isChinese ? "正确数" : "Correct"
        case .math_input: return isChinese ? "输入结果" : "Result"
        case .math_hint: return isChinese ? "输入正确后将自动跳转" : "Auto-skip on success"
        case .math_reset: return isChinese ? "重置会话" : "Reset"
        case .math_success: return isChinese ? "正确!" : "Correct!"
        case .set_style_select: return isChinese ? "计时器皮肤" : "Timer Style"
        case .set_pomo_config: return isChinese ? "番茄参数" : "Pomo Settings"
        case .set_pomo_duration: return isChinese ? "专注时长" : "Focus Duration"
        case .set_pomo_split: return isChinese ? "内部切分" : "Split Interval"
        case .set_pomo_short: return isChinese ? "短休时长" : "Short Break"
        case .set_pomo_long: return isChinese ? "长休时长" : "Long Break"
        case .set_pomo_interval: return isChinese ? "长休间隔" : "Long Break Interval"
        case .set_pomo_auto: return isChinese ? "自动开始" : "Auto Start"
        case .set_pomo_sound: return isChinese ? "提示音效" : "Alert Sounds"
        case .set_cal_auto: return isChinese ? "日程自动切换" : "Auto Switch"
        case .set_show_completed: return isChinese ? "显示已完成任务" : "Show Completed"
        case .set_timer_magnet: return isChinese ? "时间轴磁吸" : "Magnet"
        case .app_name: return isChinese ? "李知本·时间" : "TimeTracker"
        case .subtitle_timer: return isChinese ? "时间记录器" : "Time Tracker"
        case .save_record: return isChinese ? "保存记录" : "Save"
        default: return key.stringKey
        }
    }
    
    static func cat(_ raw: String) -> String {
        switch raw {
        case "工作", "Work": return t(.cat_work)
        case "刚需", "Necessity": return t(.cat_necessity)
        case "生活", "Life": return t(.cat_life)
        case "监控", "Monitor": return t(.cat_monitor)
        case "空", "Gap": return t(.cat_gap)
        default: return raw
        }
    }
    static func text(_ raw: String) -> String { return NSLocalizedString(raw, comment: "") }
}

// MARK: - 付费状态与全局设置模型 - v5 - 增加时间算法调试开关

struct AppSettings: Codable, Equatable, Sendable {
    var isPro: Bool = false
    var installDate: Date? = nil
    
    // 计时器设置
    var isMagnetismEnabled: Bool = true
    var timerStyle: Int = 0
    var mergeSameCategory: Bool = true
    
    // 番茄时间设置
    var pomoFocusDuration: Int = 25
    var pomoSplitDuration: Int = 5
    var pomoShortBreak: Int = 5
    var pomoLongBreak: Int = 15
    var pomoCyclesBeforeLong: Int = 4
    var pomoAutoStart: Bool = true
    var enableFocusEndSound: Bool = true
    var focusEndSoundID: Int = 1022
    var enableBreakEndSound: Bool = true
    var breakEndSoundID: Int = 1016
    var enableSplitSound: Bool = true
    
    // 日历设置
    var calendarAutoSwitch: Bool = false
    var calDefaultTitle: String = "新日程"
    var calDefaultDuration: Int = 60
    var calDefaultAlarmOffset: Int = -15
    var calDefaultCalendarID: String = ""
    var calDefaultCategory: String = "工作"
    
    var showCompletedTasks: Bool = false
    
    // 【324号新增】：时间轴算法物理对账开关
    var isTimeAlgorithmDebugEnabled: Bool = false
}

// MARK: - 2. 付费功能行组件 (唯一定义)
struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundColor(.orange).frame(width: 35)
            VStack(alignment: .leading) {
                Text(title).font(.headline).foregroundColor(.white)
                Text(desc).font(.caption).foregroundColor(.gray)
            }
        }
    }
}

// MARK: - 4. 唯一的付费墙 (真实支付版) - v5 - 适配原生 macOS

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    // 判断是否是大屏设备
    var isLargeScreen: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    var body: some View {
        ZStack {
            // 1. 背景层 (全屏铺满)
            Color.black.ignoresSafeArea()
            LinearGradient(colors:[.purple.opacity(0.4), .blue.opacity(0.2), .black], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            // 2. 内容层 (增加最大宽度限制)
            VStack(spacing: 24) {
                // 顶部栏
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.3)) }
                    Spacer()
                    Button("恢复购买") {
                        Task { await purchaseManager.restorePurchases() }
                    }.foregroundColor(.orange).font(.subheadline)
                }.padding()

                // 图标
                Image(systemName: "crown.fill").font(.system(size: 70)).foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                
                // 标题与状态
                VStack(spacing: 8) {
                    Text("李知本·时间 Pro").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.white)
                    
                    if store.config.isPro {
                        Text("🎉 您已是尊贵的 Pro 用户").font(.caption).foregroundColor(.green)
                    } else if store.remainingTrialDays > 0 {
                        Text("全功能免费试用中，剩余 \(store.remainingTrialDays) 天").font(.caption).padding(8).background(Capsule().fill(Color.green.opacity(0.2))).foregroundColor(.green)
                    } else {
                        Text("试用已结束").font(.caption).foregroundColor(.gray)
                    }
                }
                
                // 权益列表
                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(icon: "calendar.badge.clock", title: "无限回顾", desc: "查看 30 天前的所有历史记录")
                    FeatureRow(icon: "timer", title: "精美皮肤", desc: "解锁全套动态计时器样式")
                }.padding(.horizontal, 30)
                
                Spacer()
                
                if let err = purchaseManager.errorMessage {
                    Text(err).font(.caption).foregroundColor(.red).padding(.horizontal)
                }
                
                // 购买按钮
                if store.config.isPro {
                    Button { dismiss() } label: {
                        Text("继续使用").font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Capsule().fill(Color.white))
                    }.padding(.horizontal, 30)
                } else {
                    if let product = purchaseManager.products.first {
                        Button {
                            Task { await purchaseManager.purchase(product) }
                        } label: {
                            Text("立即升级 \(product.displayPrice)")
                                .font(.headline).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding()
                                .background(Capsule().fill(Color.white))
                        }.padding(.horizontal, 30)
                        Text("一次付费，永久使用").font(.caption2).foregroundColor(.gray)
                    } else {
                        Button { } label: {
                            HStack { ProgressView().tint(.black); Text("正在获取价格...") }
                                .font(.headline).foregroundColor(.gray).frame(maxWidth: .infinity).padding().background(Capsule().fill(Color.white.opacity(0.5)))
                        }.disabled(true).padding(.horizontal, 30)
                    }
                }
            }
            .padding(.bottom, 20)
            // 【关键修改】限制最大宽度，使其在 Mac 上居中显示，像个弹窗
            .frame(maxWidth: isLargeScreen ? 500 : .infinity)
            
            // Loading 遮罩放在最上层
            if purchaseManager.isPurchasing {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack {
                        ProgressView().scaleEffect(1.5).tint(.white)
                        Text("正在处理...").foregroundColor(.white).padding(.top, 10)
                    }
                }.zIndex(100)
            }
        }
        .task { await purchaseManager.loadProducts() }
        .onChange(of: store.config.isPro) { _, isPro in
            if isPro { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() } }
        }
    }
}
// MARK: - 支付管理器 (StoreKit 2) - v3 - 增加启动同步校验
//
// PurchaseManager
// (修改：
//  1. 增加 updatePurchaseStatus 方法用于静默检查当前所有权。
//  2. 优化了 handle 处理逻辑，确保权限状态与 App Store 实时同步。)




@MainActor
class PurchaseManager: ObservableObject {
    // 请替换为你 App Store Connect 里创建的 ID
    private let productIds = ["com.han.timetracker.pro.lifetime"]
    
    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    
    private var settingsStore: GlobalSettingsStore
    
    init(settingsStore: GlobalSettingsStore) {
        self.settingsStore = settingsStore
        
        // 1. 启动监听任务 (监听 App 运行期间产生的交易更新)
        Task {
            for await result in StoreKit.Transaction.updates {
                await handle(transactionVerification: result)
            }
        }
    }
    
    // MARK: - 新增：静默校验当前所有权
    // 用于启动时调用，无需用户参与，自动同步权限
    func updatePurchaseStatus() async {
        var hasValidPro = false
        
        // 检查当前所有有效的授权
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIds.contains(transaction.productID) {
                    hasValidPro = true
                    break
                }
            }
        }
        
        // 同步状态到全局设置
        if settingsStore.config.isPro != hasValidPro {
            settingsStore.config.isPro = hasValidPro
            settingsStore.save()
            print("[Purchase] 启动权限状态已同步: \(hasValidPro)")
        }
    }
    
    // 加载商品列表
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // 发起购买
    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(transactionVerification: verification)
            case .userCancelled:
                print("User cancelled")
            case .pending:
                print("Transaction pending")
            @unknown default:
                break
            }
        } catch {
            errorMessage = "支付失败: \(error.localizedDescription)"
        }
        
        isPurchasing = false
    }
    
    // 手动恢复购买
    func restorePurchases() async {
        isPurchasing = true
        try? await AppStore.sync() // 强制同步商店历史
        await updatePurchaseStatus()
        isPurchasing = false
    }
    
    // 验证并处理单条交易
    private func handle(transactionVerification result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let transaction):
            if productIds.contains(transaction.productID) {
                settingsStore.config.isPro = true
                settingsStore.save()
                await transaction.finish()
            }
        case .unverified:
            // 签名无效，不授予权限
            break
        }
    }
}



// 系统音效定义
struct SystemSoundOption: Identifiable, Hashable {
    let id: Int
    let name: String
}

// 常用系统音效列表
let availableSounds: [SystemSoundOption] = [
    SystemSoundOption(id: 1007, name: "琶音 (Arpeggio)"),
    SystemSoundOption(id: 1013, name: "钟声 (Chime)"),
    SystemSoundOption(id: 1016, name: "推特 (Tweet)"), // 默认休息结束
    SystemSoundOption(id: 1022, name: "号角 (Fanfare)"), // 默认专注结束
    SystemSoundOption(id: 1023, name: "阶梯 (Ladder)"),
    SystemSoundOption(id: 1031, name: "低沉 (Kenney)"),
    SystemSoundOption(id: 1052, name: "即时 (Bloom)"),
    SystemSoundOption(id: 1054, name: "和弦 (Chords)"),
    SystemSoundOption(id: 1103, name: "叮 (Tink)") // 切分音
]

class SoundManager {
    // 播放指定 ID 的系统声音
    static func play(_ soundID: Int) {
        AudioServicesPlaySystemSound(SystemSoundID(soundID))
    }
    
    // 播放固定的切分音效
    static func playSplit() {
        AudioServicesPlaySystemSound(1103)
    }
}




// MARK: - 基础配置与扩展 - V2 - 增强 25 点逻辑兼容性
//
// extension Date
// (修改内容：将 is25Hour 从绝对相等判定改为阈值判定 [> 300亿]，
//  解决 iCloud JSON 解析精度丢失导致的进行中状态判定失败 Bug。)

extension Date {
    // 将时间标准化：秒数归零
    var normalized: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return cal.date(from: comps) ?? self
    }
    
    // 判断是否是 25 点 (无穷大)
    // 逻辑修正：使用时间戳阈值判定，解决 63113904000 在不同设备上的精度误差
    var is25Hour: Bool {
        return self.timeIntervalSince1970 > 30000000000
    }
}

// ⚠️ 确保与 Widget 中一致
let appGroupIdentifier = "group.Han.TimeTracker"




// MARK: - Live Activity 定义 - V1 - 灵动岛共享数据

#if os(iOS) && !targetEnvironment(macCatalyst)

// === 情况 A: iOS 手机环境 (正常继承) ===
public struct TimeTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var category: String
        public var startTime: Date
        public var yesterdayScore: Double
        
        public init(category: String, startTime: Date, yesterdayScore: Double) {
            self.category = category
            self.startTime = startTime
            self.yesterdayScore = yesterdayScore
        }
    }
    public init() {}
}

#else

// === 情况 B: Mac Catalyst 环境 (哑替身，不继承) ===
    public struct TimeTrackerAttributes {
        public struct ContentState: Codable, Hashable {
            public var category: String
            public var startTime: Date
            public var yesterdayScore: Double
            
            public init(category: String, startTime: Date, yesterdayScore: Double) {
                self.category = category
                self.startTime = startTime
                self.yesterdayScore = yesterdayScore
            }
        }
        public init() {}
    }

#endif


// MARK: - 静态格式化器 - V22 - 24点逻辑支持
//
//  Formatters
//  (增加 formatEndTime 专门用于处理结束时间的 24:00 显示，其他时间保持标准)

struct Formatters {
    static let yyyyMMdd: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }()
    static let mmDD: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MM/dd"; return f }()
    static let mmDDEEEE: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MM月dd日 EEEE"; f.locale = Locale(identifier: "zh_CN"); return f }()
    static let hhMM: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
    static let yyyyMM: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy年MM月"; return f }()
    static let weekDay: DateFormatter = { let f = DateFormatter(); f.dateFormat = "E"; f.locale = Locale(identifier: "zh_CN"); return f }()
    
    // 核心逻辑：只在结束时间调用此方法
    // 如果是 00:00 (午夜)，则显示 "24:00"
    static func formatEndTime(_ date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: date)
        if comps.hour == 0 && comps.minute == 0 {
            return "24:00"
        }
        return hhMM.string(from: date)
    }
}

// MARK: - 用户照片管理器 - V1 - 计时器背景图
struct UserPhotoManager {
    static let shared = UserPhotoManager()
    private let fileName = "user_timer_bg.jpg"
    
    private init() {}
    
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    func saveAndProcess(image: UIImage) {
        let targetSize = CGSize(width: 300, height: 300)
        
        #if os(macOS)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        let scaleFactor = max(widthRatio, heightRatio)
        
        let scaledWidth = image.size.width * scaleFactor
        let scaledHeight = image.size.height * scaleFactor
        
        let originX = (targetSize.width - scaledWidth) / 2.0
        let originY = (targetSize.height - scaledHeight) / 2.0
        
        image.draw(in: CGRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight))
        resizedImage.unlockFocus()
        #else
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            let widthRatio = targetSize.width / image.size.width
            let heightRatio = targetSize.height / image.size.height
            let scaleFactor = max(widthRatio, heightRatio)
            
            let scaledWidth = image.size.width * scaleFactor
            let scaledHeight = image.size.height * scaleFactor
            
            let originX = (targetSize.width - scaledWidth) / 2.0
            let originY = (targetSize.height - scaledHeight) / 2.0
            
            image.draw(in: CGRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight))
        }
        #endif
        
        if let data = resizedImage.jpegData(compressionQuality: 0.7) {
            try? data.write(to: fileURL)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("UserPhotoUpdated"), object: nil)
            }
        }
    }
    
    func loadPhoto() -> UIImage? {
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}

// MARK: - 全局计算逻辑 - v3 - 统一接口切片化
//
// GlobalLogic
// (修改内容：
//  1. 彻底移除对 TimeStore 的依赖，所有方法均接收经过切片后的 [TimeRecord] 数组。
//  2. 确保 calculateRawWeightedHours 与 calculateScore 逻辑闭环。)

struct GlobalLogic {
    /// 核心计算逻辑：只针对传入的一组记录计算评分
    static func calculateScore(for date: Date, records: [TimeRecord], es: EfficiencyStore) -> Double {
        let eff = es.getEfficiency(for: date)
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let t12 = cal.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? startOfDay.addingTimeInterval(12 * 3600)
        let t19 = cal.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? startOfDay.addingTimeInterval(19 * 3600)
        
        var m: Double = 0
        var a: Double = 0
        var e: Double = 0
        
        let now = Date()
        
        for r in records {
            if r.category != "工作" { continue }
            
            let recordEndRaw = r.isOngoing ? now : r.endTime
            let recordEnd = min(recordEndRaw, endOfDay)
            let recordStart = max(r.startTime, startOfDay)
            
            if recordEnd <= recordStart { continue }
            
            let mSec = max(0, min(recordEnd, t12).timeIntervalSince(max(recordStart, startOfDay)))
            let aSec = max(0, min(recordEnd, t19).timeIntervalSince(max(recordStart, t12)))
            let eSec = max(0, min(recordEnd, endOfDay).timeIntervalSince(max(recordStart, t19)))
            
            m += mSec
            a += aSec
            e += eSec
        }
        
        let totalVal = (m/3600.0 * Double(eff.morningEff)) +
                       (a/3600.0 * Double(eff.afternoonEff)) +
                       (e/3600.0 * Double(eff.eveningEff))
        
        let targets = es.getTargets(for: date)
        let targetScore = Double(targets.hours * targets.efficiency)
        
        return targetScore > 0 ? (totalVal / targetScore * 100.0) : 0.0
    }

    /// 计算加权总工时（用于旧版兼容逻辑）
    static func calculateRawWeightedHours(_ date: Date, records: [TimeRecord], es: EfficiencyStore) -> Double {
        let score = calculateScore(for: date, records: records, es: es)
        let targets = es.getTargets(for: date)
        let targetScore = Double(targets.hours * targets.efficiency)
        return (score / 100.0) * targetScore
    }
}

// MARK: - 基础数据模型 - V2 - 目标设置 (适配 Equatable)
//
// WeeklyTarget
// (修改：增加 Equatable 协议，以便 .onChange 监听 es.weeklyTargets 字典变化)

struct WeeklyTarget: Codable, Equatable {
    var hours: Int
    var efficiency: Int
}

// MARK: - 基础数据模型 - v29 - 扩展任务详情属性
//
// TaskItem
// (修改内容：
//  1. 新增 priority (优先级), notes (备注), isFlagged (旗标), url (链接) 字段。
//  2. 保持与 EventKit 的映射能力。)

struct TaskItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var listName: String
    var listColorString: String
    var dueDate: Date?
    var hasAlarms: Bool
    var indentationLevel: Int
    var ekID: String           // EventKit ID
    
    // 【新增详情属性】
    var priority: Int          // 0: None, 1: High, 5: Medium, 9: Low
    var notes: String?
    var isFlagged: Bool
    var url: URL?

    var listColor: Color {
        if listColorString.starts(with: "#") {
            return Color(hex: listColorString) ?? .blue
        }
        switch listColorString {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default: return .blue
        }
    }
}

// 辅助扩展：Color Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        let length = hexSanitized.count
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else { return nil }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - 任务存储 (EventKit 原生同步版) - v39 - 适配 macOS 震动反馈与 API 版本警告

class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var taskLists: [EKCalendar] = []
    
    private let eventStore = EKEventStore()
    private var isAccessGranted = false
    
    @AppStorage("task_indentation_cache") private var indentCacheJSON: String = "{}"
    private var indentCache: [String: Int] = [:]
    @AppStorage("task_list_sort_configs_v1") var sortConfigsJSON: String = "{}"
    @AppStorage("task_all_view_sort_order_v1") var allViewSortOrder: TaskListSortOrder = .dueDate
    @AppStorage("task_all_view_grouping_v1") var allViewGroupByList: Bool = false
    
    enum TaskListSortOrder: String, CaseIterable, Codable {
        case manual = "手动"; case dueDate = "截止日期"; case priority = "优先级"; case creationDate = "创建日期"; case title = "标题"
    }
    
    init() {
        loadIndentCache()
        requestAccess()
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged), name: .EKEventStoreChanged, object: eventStore)
    }
    
    func requestAccess() {
        if #available(iOS 17.0, macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] granted, _ in
                DispatchQueue.main.async { self?.handleAccess(granted) }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, _ in
                DispatchQueue.main.async { self?.handleAccess(granted) }
            }
        }
    }
    
    private func handleAccess(_ granted: Bool) { isAccessGranted = granted; if granted { fetchAll() } }
    @objc private func storeChanged() { DispatchQueue.main.async { self.fetchAll() } }
    
    func fetchAll() {
        guard isAccessGranted else { return }
        self.taskLists = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) {[weak self] ekReminders in
            guard let self = self, let reminders = ekReminders else { return }
            let items = reminders.map { ekRem -> TaskItem in
                var date: Date? = nil
                if let components = ekRem.dueDateComponents { date = Calendar.current.date(from: components) }
                
                var flagged = false
                if ekRem.responds(to: NSSelectorFromString("isFlagged")) {
                    flagged = (ekRem.value(forKey: "isFlagged") as? Bool) ?? false
                }
                
                return TaskItem(
                    id: UUID(),
                    title: ekRem.title,
                    isCompleted: ekRem.isCompleted,
                    createdAt: ekRem.creationDate ?? Date(),
                    listName: ekRem.calendar.title,
                    listColorString: self.mapCGColorToHexString(ekRem.calendar.cgColor),
                    dueDate: date,
                    hasAlarms: ekRem.hasAlarms,
                    indentationLevel: self.indentCache[ekRem.calendarItemIdentifier] ?? 0,
                    ekID: ekRem.calendarItemIdentifier,
                    priority: ekRem.priority,
                    notes: ekRem.notes,
                    isFlagged: flagged,
                    url: ekRem.url
                )
            }
            DispatchQueue.main.async { self.tasks = items }
        }
    }
    
    private func mapCGColorToHexString(_ cgColor: CGColor?) -> String {
        guard let components = cgColor?.components, components.count >= 3 else { return "blue" }
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(components[0]) * 255), lroundf(Float(components[1]) * 255), lroundf(Float(components[2]) * 255))
    }

    func updateTaskProperties(item: TaskItem, newTitle: String, newNotes: String?, newPriority: Int, newFlag: Bool, newDueDate: Date?, newList: EKCalendar?) {
        guard let reminder = eventStore.calendarItem(withIdentifier: item.ekID) as? EKReminder else { return }
        reminder.title = newTitle; reminder.notes = newNotes; reminder.priority = newPriority
        if reminder.responds(to: NSSelectorFromString("isFlagged")) { reminder.setValue(newFlag, forKey: "isFlagged") }
        if let list = newList { reminder.calendar = list }
        if let d = newDueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: d)
            reminder.alarms?.forEach { reminder.removeAlarm($0) }
            reminder.addAlarm(EKAlarm(absoluteDate: d))
        } else { reminder.dueDateComponents = nil; reminder.alarms?.forEach { reminder.removeAlarm($0) } }
        try? eventStore.save(reminder, commit: true); fetchAll()
        
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    func updateListProperties(calendarID: String, newTitle: String, newColor: UIColor) {
        guard let calendar = eventStore.calendar(withIdentifier: calendarID) else { return }
        calendar.title = newTitle; calendar.cgColor = newColor.cgColor
        try? eventStore.saveCalendar(calendar, commit: true); fetchAll()
    }
    func updateListSortOrder(calendarID: String, order: TaskListSortOrder) {
        var dict = getSortConfigs(); dict[calendarID] = order
        if let data = try? JSONEncoder().encode(dict), let str = String(data: data, encoding: .utf8) { sortConfigsJSON = str; objectWillChange.send() }
    }
    
    func getSortConfigs() ->[String: TaskListSortOrder] { if let data = sortConfigsJSON.data(using: .utf8), let decoded = try? JSONDecoder().decode([String: TaskListSortOrder].self, from: data) { return decoded }; return [:] }
    func toggleComplete(_ item: TaskItem) { guard let r = eventStore.calendarItem(withIdentifier: item.ekID) as? EKReminder else { return }; do { r.isCompleted.toggle(); try eventStore.save(r, commit: true); fetchAll() } catch { print(error) } }
    func delete(_ item: TaskItem) { guard let r = eventStore.calendarItem(withIdentifier: item.ekID) as? EKReminder else { return }; try? eventStore.remove(r, commit: true); fetchAll() }
    func moveToList(_ item: TaskItem, targetListID: String) { guard let r = eventStore.calendarItem(withIdentifier: item.ekID) as? EKReminder, let c = eventStore.calendar(withIdentifier: targetListID) else { return }; r.calendar = c; try? eventStore.save(r, commit: true); fetchAll() }
    func changeIndent(_ item: TaskItem, level: Int) { let nl = max(0, min(1, level)); indentCache[item.ekID] = nl; saveIndentCache(); fetchAll() }
    func addTask(title: String, listID: String? = nil) { guard !title.isEmpty, isAccessGranted else { return }; let r = EKReminder(eventStore: eventStore); r.title = title; if let id = listID, let c = eventStore.calendar(withIdentifier: id) { r.calendar = c } else { r.calendar = eventStore.defaultCalendarForNewReminders() }; try? eventStore.save(r, commit: true); fetchAll() }
    func updateTitle(_ item: TaskItem, newTitle: String) { guard !newTitle.isEmpty, let r = eventStore.calendarItem(withIdentifier: item.ekID) as? EKReminder else { return }; r.title = newTitle; try? eventStore.save(r, commit: true); fetchAll() }
    private func saveIndentCache() { if let data = try? JSONEncoder().encode(indentCache), let str = String(data: data, encoding: .utf8) { indentCacheJSON = str } }
    private func loadIndentCache() { if let data = indentCacheJSON.data(using: .utf8), let dict = try? JSONDecoder().decode([String: Int].self, from: data) { indentCache = dict } }
    func toggleTask(_ task: TaskItem) { toggleComplete(task) }
    func deleteTask(_ task: TaskItem) { delete(task) }
    func indentTask(_ task: TaskItem) { changeIndent(task, level: 1) }
    func outdentTask(_ task: TaskItem) { changeIndent(task, level: 0) }
    
    func backup() {
        if let data = try? JSONEncoder().encode(tasks) {
            BackupManager.shared.saveBackup(data: data, module: "Tasks")
        }
    }
}

// MARK: - 基础数据模型 - V2 - 日历事件封装 (增加 Category)
struct CalendarEventWrapper: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color
    let category: String // 新增：从备注解析出来的 App 行动属性
    
    init(ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        if let cgColor = ekEvent.calendar.cgColor {
            self.color = Color(cgColor: cgColor)
        } else {
            self.color = .purple
        }
        
        // 解析备注中的 category
        self.category = CalendarStore.extractCategory(from: ekEvent.notes) ?? "工作"
    }
}

// MARK: - EfficiencyStore - v31 - 完整版 (适配文件级同步与备份)
//
// class EfficiencyStore
// (修改：完整实现，包含 ignoreNextUpdate 和 backup)

class EfficiencyStore: ObservableObject {
    @Published var dailyData: [String: DailyEfficiency] = [:]
    @Published var weeklyTargets: [String: WeeklyTarget] = [:]
    @Published var targetHours: Int = 8
    @Published var targetEfficiency: Int = 6
    
    private var isFreshLaunch = false
    
    @AppStorage("cache_today_score_v1") var todayScoreCache: Double = 0.0
    @AppStorage("cache_yesterday_score_v1") var yesterdayScoreCache: Double = 0.0
    @AppStorage("cache_last_refresh_day_v1") private var lastRefreshDay: String = ""
    
    private let dataFileName = "efficiency_data_final_v20.json"
    private let weeklyFileName = "weekly_targets_v20.json"
    private let settingsFileName = "efficiency_settings_v20.json"
    
    init() {
        load()
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudFileChange), name: .CloudFileDidChange, object: nil)
    }
    
    @objc private func handleCloudFileChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else { return }
        
        let validPaths: Set<String> = [
            "记录/\(dataFileName)",
            "记录/\(weeklyFileName)",
            "记录/\(settingsFileName)"
        ]
        
        if validPaths.contains(path) {
            print("[EfficiencyStore] 检测到数据更新: \(path)")
            load()
        }
    }
    
    func refreshCache(with allRecords: [TimeRecord], forceYesterday: Bool = false) {
        let now = Date()
        let todayString = Formatters.yyyyMMdd.string(from: now)
        let shouldRecalcYesterday = forceYesterday || (lastRefreshDay != todayString) || (yesterdayScoreCache < 0.1)
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let cal = Calendar.current
            
            let sDayT = cal.startOfDay(for: now)
            let eDayT = cal.date(byAdding: .day, value: 1, to: sDayT)!
            let tRecs = allRecords.filter { r in
                let rEnd = r.isOngoing ? now : r.endTime
                return r.startTime < eDayT && rEnd > sDayT
            }
            let tScore = GlobalLogic.calculateScore(for: now, records: tRecs, es: self)
            
            var yScore = self.yesterdayScoreCache
            if shouldRecalcYesterday {
                let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
                let sDayY = cal.startOfDay(for: yesterday)
                let eDayY = cal.startOfDay(for: now)
                let yRecs = allRecords.filter { r in
                    let rEnd = r.isOngoing ? now : r.endTime
                    return r.startTime < eDayY && rEnd > sDayY
                }
                yScore = GlobalLogic.calculateScore(for: yesterday, records: yRecs, es: self)
            }
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
                if abs(self.todayScoreCache - tScore) > 0.1 { self.todayScoreCache = tScore }
                
                if shouldRecalcYesterday {
                    self.yesterdayScoreCache = yScore
                    self.lastRefreshDay = todayString
                }
                
                let shared = UserDefaults(suiteName: appGroupIdentifier)
                shared?.set(yScore, forKey: "sharedYesterdayScore")
                shared?.synchronize()
            }
        }
    }
    
    func getEfficiency(for date: Date) -> DailyEfficiency { dailyData[Formatters.yyyyMMdd.string(from: date)] ?? DailyEfficiency() }
    
    func updateEfficiency(for date: Date, m: Int, a: Int, e: Int) {
        let k = Formatters.yyyyMMdd.string(from: date)
        var d = dailyData[k] ?? DailyEfficiency()
        d.morningEff = m; d.afternoonEff = a; d.eveningEff = e
        dailyData[k] = d
        save()
    }
    
    func getTargets(for date: Date) -> (hours: Int, efficiency: Int) {
        var c = Calendar.current; c.firstWeekday = 2
        let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let wKey = "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
        if let s = weeklyTargets[wKey] { return (s.hours, s.efficiency) }
        return (targetHours, targetEfficiency)
    }
    
    func updateTargets(for date: Date, hours: Int, efficiency: Int) {
        var c = Calendar.current; c.firstWeekday = 2
        let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let wKey = "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
        weeklyTargets[wKey] = WeeklyTarget(hours: hours, efficiency: efficiency)
        self.targetHours = hours; self.targetEfficiency = efficiency
        save()
    }
    
    func isPastWeek(_ date: Date) -> Bool { var c = Calendar.current; c.firstWeekday = 2; let cc = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()); let tc = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date); if let cy = cc.yearForWeekOfYear, let cw = cc.weekOfYear, let ty = tc.yearForWeekOfYear, let tw = tc.weekOfYear { if ty < cy { return true }; if ty == cy && tw < cw { return true } }; return false }
    
    func save() {
        isFreshLaunch = false
        
        if let d = try? JSONEncoder().encode(dailyData) {
            CloudSyncManager.shared.ignoreNextUpdate(relativePath: "记录/\(dataFileName)")
            CloudFileManager.shared.saveDual(data: d, folder: .records, fileName: dataFileName)
        }
        if let wd = try? JSONEncoder().encode(weeklyTargets) {
            CloudSyncManager.shared.ignoreNextUpdate(relativePath: "记录/\(weeklyFileName)")
            CloudFileManager.shared.saveDual(data: wd, folder: .records, fileName: weeklyFileName)
        }
        
        let sd = SettingsData(targetHours: targetHours, targetEfficiency: targetEfficiency)
        if let sdd = try? JSONEncoder().encode(sd) {
            CloudSyncManager.shared.ignoreNextUpdate(relativePath: "记录/\(settingsFileName)")
            CloudFileManager.shared.saveDual(data: sdd, folder: .records, fileName: settingsFileName)
        }
    }
    
    // 手动备份接口
    func backup() {
        if let data = try? JSONEncoder().encode(dailyData) {
            BackupManager.shared.saveBackup(data: data, module: "Efficiency")
        }
    }
    
    func load() {
        // 【启动优化】：iCloud 文件读取与 NSFileCoordinator 可能阻塞数秒，
        // 必须放到后台队列执行，避免主线程在启动瞬间卡死。
        let diagnosticStart = StartupDiagnostics.shared.begin("EfficiencyStore.load")
        let dataName = dataFileName
        let weeklyName = weeklyFileName
        let settingsName = settingsFileName

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let d1 = CloudFileManager.shared.smartLoad(folder: .records, fileName: dataName)
            let d2 = CloudFileManager.shared.smartLoad(folder: .records, fileName: weeklyName)
            let d3 = CloudFileManager.shared.smartLoad(folder: .records, fileName: settingsName)

            let decodedDaily = d1.flatMap { try? JSONDecoder().decode([String: DailyEfficiency].self, from: $0) }
            let decodedWeekly = d2.flatMap { try? JSONDecoder().decode([String: WeeklyTarget].self, from: $0) }

            DispatchQueue.main.async {
                guard let self = self else { return }
                let decodedSettings = d3.flatMap { try? JSONDecoder().decode(SettingsData.self, from: $0) }

                var loadedAny = false

                if let v = decodedDaily {
                    self.dailyData = v; loadedAny = true
                }
                if let w = decodedWeekly {
                    self.weeklyTargets = w; loadedAny = true
                }
                if let s = decodedSettings {
                    self.targetHours = s.targetHours; self.targetEfficiency = s.targetEfficiency; loadedAny = true
                }

                if loadedAny {
                    self.isFreshLaunch = false
                } else {
                    if self.dailyData.isEmpty && self.weeklyTargets.isEmpty {
                        self.isFreshLaunch = true
                        print("[EfficiencyStore] 进入幽灵模式")
                    }
                }
                StartupDiagnostics.shared.end("EfficiencyStore.load", since: diagnosticStart)
            }
        }
    }
    
    func importData(data: [String: DailyEfficiency], tH: Int, tE: Int) {
        self.dailyData = data; self.targetHours = tH; self.targetEfficiency = tE
        save()
    }
    
    struct SettingsData: Codable { let targetHours: Int; let targetEfficiency: Int }
}

// MARK: - 日历存储 (EventKit) - v25 - 适配 macOS 震动反馈

class CalendarStore: ObservableObject {
    @Published var events: [CalendarEventWrapper] = []
    @Published var calendars: [EKCalendar] = []
    @Published var selectedDate: Date = Date()
    
    private let eventStore = EKEventStore()
    private var isAccessGranted = false
    
    @AppStorage("settings_calendar_auto_switch") var calendarAutoSwitch = false
    
    init() {
        requestAccess()
        requestNotificationPermission()
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged), name: .EKEventStoreChanged, object: eventStore)
    }
    
    static func extractCategory(from notes: String?) -> String? {
        guard let notes = notes else { return nil }
        let pattern = "\\[AppCat:(.*?)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: notes.utf16.count)
        if let match = regex.firstMatch(in: notes, options:[], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: notes) {
                return String(notes[swiftRange])
            }
        }
        return nil
    }
    
    func requestAccess() {
        if #available(iOS 17.0, macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async { self?.handleAccess(granted) }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async { self?.handleAccess(granted) }
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func handleAccess(_ granted: Bool) {
        isAccessGranted = granted
        if granted {
            fetchEvents()
            fetchAllCalendars()
        }
    }
    
    @objc private func storeChanged() {
        DispatchQueue.main.async {
            self.fetchEvents()
            self.fetchAllCalendars()
        }
    }
    
    func fetchAllCalendars() {
        guard isAccessGranted else { return }
        let cals = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
        DispatchQueue.main.async { self.calendars = cals }
    }
    
    func fetchEvents() {
        guard isAccessGranted else { return }
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -45, to: selectedDate)!
        let end = cal.date(byAdding: .day, value: 45, to: selectedDate)!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        DispatchQueue.main.async {
            self.events = ekEvents.map { CalendarEventWrapper(ekEvent: $0) }
        }
    }
    
    func getEvents(for date: Date) -> [CalendarEventWrapper] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { event in
            return event.startDate < dayEnd && event.endDate > dayStart
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func addEvent(title: String, start: Date, end: Date, isAllDay: Bool, location: String = "", notes: String = "", calendarID: String = "", category: String) {
        guard isAccessGranted else { return }
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.startDate = start
        newEvent.endDate = end
        newEvent.isAllDay = isAllDay
        newEvent.location = location
        
        let metaTag = "\n\n[AppCat:\(category)]"
        newEvent.notes = (notes + metaTag).trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !calendarID.isEmpty, let cal = eventStore.calendar(withIdentifier: calendarID) {
            newEvent.calendar = cal
        } else {
            newEvent.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            
            #if !os(macOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            
            if start > Date() {
                scheduleNotifications(for: newEvent, category: category)
            }
        } catch {
            print("Save Event Error: \(error)")
        }
    }
    
    private func scheduleNotifications(for event: EKEvent, category: String) {
        let center = UNUserNotificationCenter.current()
        let startContent = UNMutableNotificationContent()
        if calendarAutoSwitch {
            startContent.title = "日程开始: \(event.title ?? "未命名")"
            startContent.body = "即将自动切换至【\(category)】状态 (点击执行)"
            startContent.userInfo = ["action": "switch", "category": category]
        } else {
            startContent.title = "日程提醒"
            startContent.body = "日程“\(event.title ?? "")”已开始。是否切换为【\(category)】？"
            startContent.userInfo = ["action": "ask", "category": category]
        }
        startContent.sound = .default
        
        let startTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: event.startDate)
        let startTrigger = UNCalendarNotificationTrigger(dateMatching: startTriggerDate, repeats: false)
        let startReq = UNNotificationRequest(identifier: "start_\(event.eventIdentifier ?? UUID().uuidString)", content: startContent, trigger: startTrigger)
        center.add(startReq)
        
        let endContent = UNMutableNotificationContent()
        endContent.title = "日程结束"
        endContent.body = "“\(event.title ?? "")”已结束。如果未开始新任务，请记录空档。"
        endContent.sound = .default
        
        let endTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: event.endDate)
        let endTrigger = UNCalendarNotificationTrigger(dateMatching: endTriggerDate, repeats: false)
        let endReq = UNNotificationRequest(identifier: "end_\(event.eventIdentifier ?? UUID().uuidString)", content: endContent, trigger: endTrigger)
        center.add(endReq)
    }
    
    func selectDate(_ date: Date) {
        let cal = Calendar.current
        let oldMonth = cal.component(.month, from: selectedDate)
        let newMonth = cal.component(.month, from: date)
        selectedDate = date
        if oldMonth != newMonth { fetchEvents() }
    }
    
    func applyClassSchedule(sourceDate: Date, targetWeekdays: Set<Int>, endDate: Date) {
        guard isAccessGranted else { return }
        
        let dayStart = Calendar.current.startOfDay(for: sourceDate)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        
        let predicate = eventStore.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)
        let events = eventStore.events(matching: predicate).filter { !$0.isAllDay }
        
        let ekDays: [EKRecurrenceDayOfWeek] = targetWeekdays.compactMap { dayInt in
            switch dayInt {
            case 1: return EKRecurrenceDayOfWeek(.sunday)
            case 2: return EKRecurrenceDayOfWeek(.monday)
            case 3: return EKRecurrenceDayOfWeek(.tuesday)
            case 4: return EKRecurrenceDayOfWeek(.wednesday)
            case 5: return EKRecurrenceDayOfWeek(.thursday)
            case 6: return EKRecurrenceDayOfWeek(.friday)
            case 7: return EKRecurrenceDayOfWeek(.saturday)
            default: return nil
            }
        }
        
        guard !ekDays.isEmpty else { return }
        
        for event in events {
            let recurrence = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                daysOfTheWeek: ekDays,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: EKRecurrenceEnd(end: endDate)
            )
            
            event.recurrenceRules = [recurrence]
            
            do {
                try eventStore.save(event, span: .futureEvents)
            } catch {
                print("排课失败: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.fetchEvents()
            #if !os(macOS)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            #endif
        }
    }
}

// MARK: - 时间记录模型 - v3 - 增加子分类支持
//
// TimeRecord
// (修改：新增 subCategory 字段，用于支持“详细统计”功能，记录具体的项目名称。)

struct TimeRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var category: String
    var subCategory: String? // 【核心新增】记录具体项，如“数学”
    var startTime: Date
    var endTime: Date
    
    var isGap: Bool { category == "空" }
    var isOngoing: Bool { endTime.is25Hour }
    
    var duration: TimeInterval {
        let realEnd = isOngoing ? Date() : endTime
        return realEnd.timeIntervalSince(startTime)
    }
    
    init(id: UUID = UUID(), category: String, subCategory: String? = nil, startTime: Date, endTime: Date) {
        self.id = id
        self.category = category
        self.subCategory = subCategory // 初始化赋值
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - 详细统计子项模型 - v1 - 定义具体行动项
//
// SubCategoryItem
// (逻辑：每一个 Item 属于一个父分类(工作/生活等)，拥有自己的标题和颜色，用于生成快捷按钮)

struct SubCategoryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String            // 具体项名称，如“数学”
    var parentCategory: String  // 所属四大象限，如“工作”
    var color: String?          // 可选自定义颜色，如果不设则跟随父类
    var icon: String?           // 可选图标
    var isQuickShortcut: Bool = true // 是否在统计页显示为快捷按钮
}

// MARK: - 详细统计配置仓库 - v2 - 适配文件级同步与备份
//
// class DetailedCategoryStore
// (修改：
//  1. 纳入 CloudFileDidChange 文件级同步体系。
//  2. 保存时增加 ignoreNextUpdate 回声抑制。
//  3. 增加 backup() 接口用于手动备份。)


class DetailedCategoryStore: ObservableObject {
    @Published var items: [SubCategoryItem] = []
    
    private let fileName = "sub_categories_config.json"
    private let relativePath: String
    
    init() {
        self.relativePath = "设置/\(fileName)"
        load()
        // 监听文件变更通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudFileChange), name: .CloudFileDidChange, object: nil)
    }
    
    @objc private func handleCloudFileChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else { return }
        
        // 仅当路径匹配时才重载
        if path == relativePath {
            print("[DetailedCategoryStore] 检测到配置更新，正在重载")
            load()
        }
    }
    
    func getItems(for category: String) -> [SubCategoryItem] {
        return items.filter { $0.parentCategory == category }
    }
    
    func addItem(name: String, parent: String) {
        guard !name.isEmpty else { return }
        if !items.contains(where: { $0.name == name && $0.parentCategory == parent }) {
            items.append(SubCategoryItem(name: name, parentCategory: parent))
            save()
        }
    }
    
    func deleteItem(_ item: SubCategoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(items) {
            // 注册忽略规则，防止回声
            CloudSyncManager.shared.ignoreNextUpdate(relativePath: relativePath)
            CloudFileManager.shared.saveDual(data: data, folder: .settings, fileName: fileName)
        }
    }
    
    // 手动备份接口
    func backup() {
        if let data = try? JSONEncoder().encode(items) {
            BackupManager.shared.saveBackup(data: data, module: "Settings", subID: "SubCategories")
        }
    }
    
    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let data = CloudFileManager.shared.smartLoad(folder: .settings, fileName: self.fileName),
               let loaded = try? JSONDecoder().decode([SubCategoryItem].self, from: data) {
                DispatchQueue.main.async {
                    self.items = loaded
                }
            }
        }
    }
}


// MARK: - 全局备份管理器 - v23 - 修复重复定义
//
//  BackupManager & BackupFile
//  (请替换掉原有的 "struct BackupFile" 和 " BackupManager" 整体代码，
//   确保 BackupFile 只被定义一次)

struct BackupFile: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let module: String
    let subID: String
    var fileName: String { url.lastPathComponent }
}

// MARK: - 全局备份管理器 - v33 - 增加物理目录全量拷贝快照能力

class BackupManager {
    static let shared = BackupManager()
    private init() {}
    
    private let maxSystemSnapshots = 30
    private let maxFileHistory = 50
    private let highDensityZone = 20
    
    private let fm = FileManager.default
    private var backupsRoot: URL { CloudFileManager.shared.getBackupsDir() }
    
    // 获取物理快照存放目录
    private func getPhysicalSnapshotsDir() -> URL {
        let dir = backupsRoot.appendingPathComponent("PhysicalSnapshots")
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private func getSnapshotsDir() -> URL {
        let dir = backupsRoot.appendingPathComponent("SystemSnapshots")
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // 获取物理快照列表
    func getPhysicalSnapshots() -> [BackupFile] {
        return listFiles(in: getPhysicalSnapshotsDir(), module: "System", subID: "Physical")
    }

    // MARK: - 现有 JSON 备份逻辑 (不精简)
    
    func saveSystemSnapshot(_ jsonData: Data) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "AutoSnapshot_\(timestamp).json"
        let url = getSnapshotsDir().appendingPathComponent(fileName)
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                try jsonData.write(to: url, options: .atomic)
                print("[BackupManager] 自动快照已保存: \(fileName)")
                self.performSmartRotation(in: self.getSnapshotsDir())
            } catch {
                print("[BackupManager] 快照写入失败: \(error)")
            }
        }
    }
    
    func getSystemSnapshots() -> [BackupFile] {
        return listFiles(in: getSnapshotsDir(), module: "System", subID: "Snapshot")
    }
    
    func deleteSnapshot(_ file: BackupFile) {
        try? fm.removeItem(at: file.url)
    }
    
    private func getDirectory(for module: String, subID: String) -> URL {
        let dir = backupsRoot.appendingPathComponent(module).appendingPathComponent(subID)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    func saveBackup(data: Data, module: String, subID: String = "Global") {
        let dir = getDirectory(for: module, subID: subID)
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let url = dir.appendingPathComponent("\(timestamp)_\(UUID().uuidString.prefix(4)).json")
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                try data.write(to: url, options: .atomic)
                self.rotateBackupsSimple(dir: dir, limit: self.maxFileHistory)
            } catch { print("单文件备份失败: \(error)") }
        }
    }
    
    func getHistory(module: String, subID: String = "Global") -> [BackupFile] {
        let dir = getDirectory(for: module, subID: subID)
        return listFiles(in: dir, module: module, subID: subID)
    }
    
    private func performSmartRotation(in dir: URL) {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            let sortedFiles = urls.map { url -> (url: URL, date: Date) in
                let date = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return (url, date)
            }.sorted { $0.date > $1.date }
            
            if sortedFiles.count <= highDensityZone { return }
            
            var filesToKeep = Set<URL>()
            var seenDays = Set<String>()
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"
            
            for i in 0..<min(sortedFiles.count, highDensityZone) {
                filesToKeep.insert(sortedFiles[i].url)
            }
            
            let candidates = sortedFiles.dropFirst(highDensityZone)
            for file in candidates {
                let dayKey = dayFormatter.string(from: file.date)
                if !seenDays.contains(dayKey) {
                    filesToKeep.insert(file.url)
                    seenDays.insert(dayKey)
                }
            }
            
            let finalKeepList = sortedFiles
                .filter { filesToKeep.contains($0.url) }
                .prefix(maxSystemSnapshots)
                .map { $0.url }
            
            let finalKeepSet = Set(finalKeepList)
            
            for file in sortedFiles {
                if !finalKeepSet.contains(file.url) {
                    try? FileManager.default.removeItem(at: file.url)
                }
            }
        } catch { print("智能清理失败: \(error)") }
    }
    
    private func rotateBackupsSimple(dir: URL, limit: Int) {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            let sorted = urls.sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return d1 > d2
            }
            if sorted.count > limit {
                for i in limit..<sorted.count { try? FileManager.default.removeItem(at: sorted[i]) }
            }
        } catch { }
    }
    
    private func listFiles(in dir: URL, module: String, subID: String) -> [BackupFile] {
        guard let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else { return [] }
        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.creationDateKey]),
                  let date = values.creationDate else { return nil }
            return BackupFile(url: url, date: date, module: module, subID: subID)
        }.sorted { $0.date > $1.date }
    }
}

struct TimerBackupData: Codable {
    let records: [TimeRecord]
    let efficiencyData: [String: DailyEfficiency]
    let targetHours: Int
    let targetEfficiency: Int
    let appSettings: AppSettings
    let backupDate: Date
}



struct TTModalSheetContainer<Content: View>: View {
    let minWidth: CGFloat
    let minHeight: CGFloat
    let showsDismissButton: Bool
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: () -> Content
    
    init(
        minWidth: CGFloat = 760,
        minHeight: CGFloat = 620,
        showsDismissButton: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.showsDismissButton = showsDismissButton
        self.content = content
    }
    
    var body: some View {
        NavigationStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .toolbar {
                    if showsDismissButton {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(width: minWidth, height: minHeight)
        #endif
    }
}


// MARK: - 设置主页 - v11 - 增加 Debug 调整入口

struct SettingsView: View {
    @EnvironmentObject var ts: TimeStore
    @EnvironmentObject var es: EfficiencyStore
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showPaywall = false
    @State var showFuncSettings = false
    @State var showDataManagement = false
    @State private var showAbout = false
    
    // 【101号新增】
    @State private var showDebugSettings = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(I18n.t(.set_center)).font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.white)
                        Text(I18n.t(.set_subtitle)).font(.subheadline).foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "gearshape.2.fill").font(.system(size: 40)).foregroundStyle(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)).opacity(0.8)
                }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 30)
                
                VStack(spacing: 20) {
                    if !settingsStore.config.isPro {
                        SettingsGlassCard(
                            title: "升级 Pro",
                            subtitle: "解锁全部计时器皮肤",
                            icon: "crown.fill",
                            colors: [.yellow, .orange]
                        ) {
                            showPaywall = true
                        }
                    }
                    
                    SettingsGlassCard(
                        title: I18n.t(.set_func_config),
                        subtitle: I18n.t(.set_func_desc),
                        icon: "slider.horizontal.3",
                        colors: [.purple, .indigo]
                    ) {
                        showFuncSettings = true
                    }
                    
                    SettingsGlassCard(
                        title: I18n.t(.set_data_manage),
                        subtitle: I18n.t(.set_data_desc),
                        icon: "externaldrive.fill",
                        colors: [.blue, .cyan]
                    ) {
                        showDataManagement = true
                    }

                    // 【101号新增】：仅在 Debug 模式下出现的项目
                    #if DEBUG
                    SettingsGlassCard(
                        title: "Debug 调整",
                        subtitle: "开发者专用调试选项",
                        icon: "ant.fill",
                        colors: [.red, .orange]
                    ) {
                        showDebugSettings = true
                    }
                    #endif
                    
                }.padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    showAbout = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                        Text("软件简介与帮助")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(10)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                }
                .padding(.bottom, 8)
                
                Text("TimeTracker Pro v1.0").font(.caption2).foregroundColor(.white.opacity(0.2)).padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showFuncSettings) {
            TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                FunctionSettingsView().environmentObject(settingsStore)
            }
        }
        .sheet(isPresented: $showDataManagement) {
            TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                DataManagementView().environmentObject(settingsStore)
            }
        }
        .sheet(isPresented: $showPaywall) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                PaywallView()
                    .environmentObject(settingsStore)
                    .environmentObject(purchaseManager)
            }
        }
        .sheet(isPresented: $showAbout) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                AboutView()
            }
        }
        // 【101号新增】
        .sheet(isPresented: $showDebugSettings) {
            TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                DebugSettingsView().environmentObject(settingsStore)
            }
        }
        .onDisappear {
            settingsStore.backup()
        }
    }
}

// MARK: - 调试设置视图 - v8 - 增加时间算法对账开关

struct DebugSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: GlobalSettingsStore
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("自动化调试")) {
                    // 【324号新增】
                    Toggle("时间轴算法物理对账", isOn: $store.config.isTimeAlgorithmDebugEnabled).tint(.blue)
                }
                
                Section(header: Text("文件系统")) {
                    NavigationLink(destination: SandboxBrowserView(url: URL(fileURLWithPath: NSHomeDirectory()))) { Label("沙盒文件浏览器", systemImage: "folder.fill.badge.gear") }
                }
            }
            .navigationTitle("Debug 调整")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
    }
}

// MARK: - 时间算法对账弹窗 - v2 - 增加 L 列表滚动查阅功能

struct TimeAlgorithmDebugView: View {
    let data: TimeStore.AlgorithmDebugData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                debugSection(title: "新记录 [A]", record: data.recordA, color: .green)
                
                Section("冲突对账 [Step 2 & 3]") {
                    debugRow(label: "左邻居 [C]", record: data.recordC, color: .gray)
                    debugRow(label: "左冲突 [B]", record: data.recordB, color: .orange)
                    debugRow(label: "右冲突 [D]", record: data.recordD, color: .orange)
                    debugRow(label: "右邻居 [E]", record: data.recordE, color: .gray)
                }
                
                // 【325号新增】：缓存表 L 详情展示
                Section(header: Text("缓存表 L 全量记录 (\(data.listL.count)条)"), footer: Text("列表展示算法执行 Step 1 之前的初始缓存状态。")) {
                    if data.listL.isEmpty {
                        Text("缓存表为空").font(.caption).foregroundColor(.gray)
                    } else {
                        ForEach(Array(data.listL.enumerated()), id: \.offset) { index, r in
                            HStack {
                                Text("\(index + 1)").font(.system(.caption2, design: .monospaced)).foregroundColor(.gray).frame(width: 20)
                                VStack(alignment: .leading) {
                                    Text(r.category).font(.subheadline).bold()
                                        .foregroundColor(getColor(for: r.category))
                                    Text("\(Formatters.hhMM.string(from: r.startTime)) - \(r.isOngoing ? "Now" : Formatters.hhMM.string(from: r.endTime))")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("算法物理对账")
            .toolbar { Button("关闭") { dismiss() } }
        }
    }
    
    @ViewBuilder
    private func debugSection(title: String, record: TimeRecord, color: Color) -> some View {
        Section(title) {
            debugRow(label: "内容", record: record, color: color)
        }
    }
    
    @ViewBuilder
    private func debugRow(label: String, record: TimeRecord?, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.gray).frame(width: 60, alignment: .leading)
            if let r = record {
                VStack(alignment: .leading) {
                    Text(r.category).bold().foregroundColor(color)
                    Text("\(Formatters.hhMM.string(from: r.startTime)) - \(r.isOngoing ? "Now" : Formatters.hhMM.string(from: r.endTime))")
                        .font(.system(.caption, design: .monospaced))
                }
            } else {
                Text("未找到 (nil)").foregroundColor(.red.opacity(0.5))
            }
        }
    }
}

// MARK: - 沙盒文件浏览器 - v1 - 递归文件查看

struct SandboxBrowserView: View {
    let url: URL
    
    @State private var items: [FileItem] = []
    
    struct FileItem: Identifiable {
        let id = UUID()
        let url: URL
        let name: String
        let isDirectory: Bool
        let size: Int64
        let date: Date
    }
    
    var body: some View {
        List {
            if items.isEmpty {
                Text("空文件夹").foregroundColor(.gray).font(.caption)
            } else {
                ForEach(items) { item in
                    if item.isDirectory {
                        NavigationLink(destination: SandboxBrowserView(url: item.url)) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(item.name).font(.body)
                                    Text(item.date.formatted(date: .numeric, time: .shortened))
                                        .font(.caption2).foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        NavigationLink(destination: SandboxFileDetailView(url: item.url)) {
                            HStack {
                                Image(systemName: iconForFile(item.name))
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(item.name).font(.body)
                                    HStack {
                                        Text(formatBytes(item.size))
                                        Text("•")
                                        Text(item.date.formatted(date: .numeric, time: .shortened))
                                    }
                                    .font(.caption2).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(url.lastPathComponent)
        .ttNavigationBarTitleDisplayMode(.inline)
        .onAppear { loadContents() }
    }
    
    private func loadContents() {
        let fm = FileManager.default
        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            let fileURLs = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles])
            
            self.items = fileURLs.compactMap { fileURL -> FileItem? in
                let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
                let isDir = values?.isDirectory ?? false
                let size = Int64(values?.fileSize ?? 0)
                let date = values?.contentModificationDate ?? Date.distantPast
                return FileItem(url: fileURL, name: fileURL.lastPathComponent, isDirectory: isDir, size: size, date: date)
            }.sorted {
                if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        } catch {
            print("Error listing directory: \(error)")
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let b = Double(bytes)
        if b < 1024 { return "\(Int(b)) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", b / 1024) }
        return String(format: "%.1f MB", b / (1024 * 1024))
    }
    
    private func iconForFile(_ name: String) -> String {
        if name.hasSuffix(".json") { return "curlybraces" }
        if name.hasSuffix(".csv") { return "tablecells" }
        if name.hasSuffix(".jpg") || name.hasSuffix(".png") { return "photo" }
        if name.hasSuffix(".txt") || name.hasSuffix(".md") { return "doc.text" }
        return "doc"
    }
}

// MARK: - 沙盒文件详情页 - v1 - 支持图片与文本预览

struct SandboxFileDetailView: View {
    let url: URL
    
    @State private var textContent: String?
    @State private var imageContent: UIImage?
    @State private var showShare = false
    @State private var fileInfo: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let img = imageContent {
                // 图片预览模式
                ScrollView {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                }
            } else if let txt = textContent {
                // 文本预览模式
                ScrollView {
                    Text(txt)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // 无法预览
                VStack(spacing: 20) {
                    Image(systemName: "doc.question.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("二进制文件或无法读取")
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            }
            
            // 底部信息栏
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("路径: \(url.path)").font(.caption2).foregroundColor(.gray).lineLimit(2)
                Text(fileInfo).font(.caption).bold()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle(url.lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }
            }
        }
        .background(ShareSheet(isPresented: $showShare, items: [url]))
        .onAppear { loadFile() }
    }
    
    private func loadFile() {
        // 读取基本信息
        if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attr[.size] as? Int64 {
            fileInfo = "大小: \(formatBytes(size))"
        }
        
        // 尝试判断类型读取
        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic"].contains(ext) {
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                self.imageContent = img
            }
        } else if ["json", "csv", "txt", "md", "xml", "log"].contains(ext) {
            if let str = try? String(contentsOf: url, encoding: .utf8) {
                self.textContent = str
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let b = Double(bytes)
        if b < 1024 { return "\(Int(b)) B" }
        if b < 1024 * 1024 { return String(format: "%.1f KB", b / 1024) }
        return String(format: "%.1f MB", b / (1024 * 1024))
    }
}

// MARK: - 关于与帮助页面 - v2 - 适配 macOS 剪贴板

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showCopyAlert = false
    
    // 合规文案：强调“独立开发”和“共创”，避免“完成度不够”的表述
    private let devMessage = """
    你好，我是这款软件的独立开发者。
    
    由于是利用业余时间开发，更新节奏可能不如大厂应用快，但我致力于让它变得更好。这款软件属于我们每一个人，如果您有好的想法或功能建议，欢迎随时联系我。
    
    在能力范围内的合理需求，我都会在后续版本中努力实现。让我们一起共创这款工具。
    """
    
    private let contactEmail = "weightmatrix09@163.com"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. 开发者寄语区域
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 头像/Logo (可选)
                            HStack {
                                Spacer()
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Spacer()
                            }
                            .padding(.top, 10)
                            
                            // 寄语文本
                            Text(devMessage)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(6)
                                .padding(.horizontal, 10)
                            
                            // 联系方式卡片
                            Button {
                                // 【核心修改】：处理 macOS 下的剪贴板 API
                                #if os(macOS)
                                let pb = NSPasteboard.general
                                pb.clearContents()
                                pb.setString(contactEmail, forType: .string)
                                #else
                                UIPasteboard.general.string = contactEmail
                                #endif
                                
                                showCopyAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("联系邮箱 (点击复制)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(contactEmail)
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.12)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 10)
                            
                            // 说明书标题
                            HStack {
                                Image(systemName: "book.fill").foregroundColor(.cyan)
                                Text("详细使用手册").font(.headline).fontWeight(.bold).foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .padding(24)
                        
                        // 2. HTML 说明书 (WebView)
                        WebView(htmlContent: ManualData.htmlString)
                            .frame(height: 800) // 给定足够高度
                            .padding(.horizontal, 10)
                            .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("软件简介与帮助")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("已复制", isPresented: $showCopyAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("邮箱地址已复制到剪贴板。")
            }
        }
    }
}

// MARK: - 说明书数据源 - v1 - 详细 HTML 内容
//
// ManualData
// (逻辑：存储静态 HTML 字符串，包含 CSS样式 和 详细的功能说明。)

struct ManualData {
    static let htmlString = """
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        :root { --bg-color: #000000; --text-primary: #f5f5f7; --text-secondary: #86868b; --accent: #0a84ff; --border: #333; }
        body { font-family: -apple-system, sans-serif; background-color: var(--bg-color); color: var(--text-primary); padding: 20px; line-height: 1.6; }
        h1 { font-size: 24px; margin-bottom: 10px; color: #fff; }
        h2 { font-size: 18px; margin-top: 30px; border-bottom: 1px solid var(--border); padding-bottom: 8px; color: var(--accent); }
        h3 { font-size: 16px; margin-top: 20px; color: #fff; font-weight: bold; }
        p { margin-bottom: 12px; color: #ccc; font-size: 14px; }
        ul { padding-left: 20px; color: #ccc; font-size: 14px; }
        li { margin-bottom: 6px; }
        .tag { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 12px; font-weight: bold; margin-right: 5px; }
        .g-tap { background: rgba(48, 209, 88, 0.2); color: #30d158; }
        .g-long { background: rgba(255, 149, 0, 0.2); color: #ff9f0a; }
        .g-drag { background: rgba(10, 132, 255, 0.2); color: #0a84ff; }
    </style>
    </head>
    <body>
        <h1>功能使用手册</h1>
        <p>欢迎使用李知本·时间。本手册将帮助您了解每一个功能模块和操作细节。</p>

        <h2>1. 首页 (Home)</h2>
        <h3>顶部区域</h3>
        <ul>
            <li><strong>勋章：</strong> 显示昨日(左)和今日(右)的效率评分勋章。分数规则：100+(紫), 80+(金), 60+(绿), <60(灰)。</li>
            <li><strong>试用倒计时：</strong> 点击可查看 Pro 权益或恢复购买。</li>
        </ul>
        <h3>中央计时器</h3>
        <ul>
            <li><span class="tag g-tap">点击</span> 弹出“编辑当前记录”，可修改开始时间。</li>
            <li><strong>显示：</strong> 当前进行的分类及持续时间。</li>
        </ul>
        <h3>底部快速开始</h3>
        <p>点击四大分类按钮（工作/刚需/生活/监控）立即开始计时。支持磁吸连接和自动合并短记录。</p>

        <h2>2. 任务清单 (Tasks)</h2>
        <h3>顶部列表栏</h3>
        <ul>
            <li><span class="tag g-tap">点击</span> 筛选显示特定列表的任务。</li>
            <li><span class="tag g-long">长按</span> 编辑列表名称、颜色、图标及<strong>默认排序方式</strong>。</li>
            <li><span class="tag g-drag">拖拽归类</span> 将下方任务拖动到顶部图标上，即可移动任务到该列表。</li>
        </ul>
        <h3>任务交互</h3>
        <ul>
            <li><span class="tag g-tap">点击文字</span> 进入行内编辑。点击右侧 ℹ️ 图标进入详情页（设置优先级、旗标、备注）。</li>
            <li><span class="tag g-tap">点击圆圈</span> 完成/取消完成。</li>
            <li><span class="tag g-drag">侧滑</span> 删除任务。</li>
        </ul>

        <h2>3. 日程日历 (Calendar)</h2>
        <h3>独家功能：草稿模式</h3>
        <ul>
            <li><span class="tag g-drag">长按并拖动</span> 在时间轴空白处拖拽，生成蓝色半透明草稿块。</li>
            <li><strong>调整：</strong> 拖动草稿块调整时间，点击草稿块填写详情并保存。</li>
            <li><strong>关联行动：</strong> 新建日程时可选择关联“工作”等分类，日程开始时会提醒切换计时状态。</li>
        </ul>
        <h3>其他</h3>
        <ul>
            <li><span class="tag g-tap">课程表模式</span> 点击左上角图标，将当日日程作为模板按周复制。</li>
        </ul>

        <h2>4. 目标管理 (Goals)</h2>
        <ul>
            <li><strong>设定目标：</strong> 点击仪表盘数字设定每日目标时长和效率。</li>
            <li><strong>周视图：</strong> 点击每天下方的胶囊快速打分。长按某一天查看当日详细记录。</li>
            <li><strong>横屏适配：</strong> iPhone 横屏时自动隐藏仪表盘，最大化显示图表。</li>
        </ul>

        <h2>5. 历史记录 (Records)</h2>
        <h3>操作手势</h3>
        <ul>
            <li><span class="tag g-tap">点击列表</span> 修改记录详情。</li>
            <li><span class="tag g-long">长按列表</span> 呼出菜单：吞并前后记录、归并分类、延长1小时。</li>
            <li><span class="tag g-drag">时间轴拖拽</span> 拖动记录块顶部手柄调整开始时间（支持磁吸）。</li>
            <li><strong>撤销/重做：</strong> 底部按钮防误触。</li>
        </ul>

        <h2>6. 番茄专注 (Pomodoro)</h2>
        <ul>
            <li><span class="tag g-tap">点击圆环</span> 开始/暂停。</li>
            <li><span class="tag g-long">长按圆环</span> 放弃当前番茄钟。</li>
            <li><strong>横屏模式：</strong> 变为“左圆右文”的时钟模式，适合桌面摆放。</li>
        </ul>

        <h2>7. 设置 (Settings)</h2>
        <ul>
            <li><strong>数据管理：</strong> 查看自动快照、导出备份。</li>
            <li><strong>导航配置：</strong> 自定义底部 Tab 顺序。</li>
            <li><strong>计时器样式：</strong> 更换首页皮肤（如赛博故障、自定义照片）。</li>
        </ul>
        <br><br><br>
    </body>
    </html>
    """
}

// MARK: - Web视图包装器 - v2 - 适配 macOS
//
// WebView
// (修改内容：使用 #if !os(macOS) 和 #else 支持 Mac 原生 NSViewRepresentable)

import SwiftUI
import WebKit

#if !os(macOS)
struct WebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
#else
struct WebView: NSViewRepresentable {
    let htmlContent: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // Mac端开启透明背景
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
#endif

// MARK: - App 入口 - v26 - 切换至物理文件夹全量备份触发器

@main
struct TimeTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var timeStore = TimeStore()
    @StateObject private var efficiencyStore = EfficiencyStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var settingsStore: GlobalSettingsStore
    @StateObject private var purchaseManager: PurchaseManager
    @StateObject private var detailedCategoryStore = DetailedCategoryStore()
    
    let syncManager = CloudSyncManager.shared
    
    init() {
        let diagnosticStart = StartupDiagnostics.shared.begin("TimeTrackerApp.init")
        StartupDiagnostics.shared.watchMainThread()
        let settings = GlobalSettingsStore()
        let manager = PurchaseManager(settingsStore: settings)
        _settingsStore = StateObject(wrappedValue: settings)
        _purchaseManager = StateObject(wrappedValue: manager)
        StartupDiagnostics.shared.end("TimeTrackerApp.init", since: diagnosticStart)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if settingsStore.hasSeenOnboarding { MainView() }
                else { OnboardingView() }
            }
            .environmentObject(timeStore)
            .environmentObject(efficiencyStore)
            .environmentObject(taskStore)
            .environmentObject(calendarStore)
            .environmentObject(settingsStore)
            .environmentObject(purchaseManager)
            .environmentObject(detailedCategoryStore)
            
            .preferredColorScheme(.dark)
            .onAppear {
                StartupDiagnostics.shared.mark("WindowGroup.onAppear")
                #if os(macOS) && !targetEnvironment(macCatalyst)
                if let appMenu = NSApp.mainMenu?.items.first?.submenu {
                    let servicesMenu = NSApp.servicesMenu
                    if let servicesItem = appMenu.items.first(where: {
                        (servicesMenu != nil && $0.submenu === servicesMenu) ||
                        $0.title == "服务" || $0.title == "Services"
                    }) {
                        appMenu.removeItem(servicesItem)
                    }
                    NSApp.servicesMenu = nil
                }
                #endif
                timeStore.efficiencyStore = efficiencyStore
                PomodoroManager.shared.setup(timeStore: timeStore, settingsStore: settingsStore)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    StartupDiagnostics.shared.mark("DelayedStartup.begin")
                    DispatchQueue.global(qos: .utility).async {
                        CloudFileManager.shared.cleanLegacyStateFile()
                    }
                    Task { await purchaseManager.updatePurchaseStatus(); await purchaseManager.loadProducts() }
                    CloudSyncManager.shared.startObserving()
                    self.efficiencyStore.refreshCache(with: timeStore.records)
                    StartupDiagnostics.shared.mark("DelayedStartup.end")
                }
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name("TriggerManualFullBackup"), object: nil, queue: .main) { _ in self.performAutoBackup() }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { settingsStore.load() }
                else if newPhase == .background || newPhase == .inactive { performAutoBackup() }
            }
        }
    }
    
    private func performAutoBackup() {
        let backup = TimerBackupData(
            records: timeStore.records,
            efficiencyData: efficiencyStore.dailyData,
            targetHours: efficiencyStore.targetHours,
            targetEfficiency: efficiencyStore.targetEfficiency,
            appSettings: settingsStore.config,
            backupDate: Date()
        )
        if let data = try? JSONEncoder().encode(backup) {
            BackupManager.shared.saveSystemSnapshot(data)
        }
    }
}

// MARK: - 全局辅助与模型
let allCategories = ["工作", "刚需", "生活", "监控", "空"]

func getColor(for category: String) -> Color {
    switch category {
    case "工作": return Color(red: 1.0, green: 0.78, blue: 0.1)
    case "刚需": return Color(red: 0.2, green: 0.85, blue: 0.5)
    case "生活": return Color(red: 0.25, green: 0.7, blue: 1.0)
    case "监控": return Color(red: 1.0, green: 0.4, blue: 0.45)
    case "空": return Color(white: 0.2)
    default: return .gray
    }
}

func formatDuration(_ s: TimeInterval, _ sec: Bool = false) -> String {
    let i = Int(s)
    let h = i/3600
    let m = (i%3600)/60
    let sc = i%60
    return sec ? String(format: "%02d:%02d:%02d", h, m, sc) : (h>0 ? "\(h)h \(m)m" : "\(m)m")
}

// MARK: - 全局日期时间合并工具 - v2 - 移除脱水逻辑，完整保留秒数精度

func combineDates(_ d: Date, _ t: Date) -> Date {
    let c = Calendar.current
    // 【32号修正】：不再强行设 second 为 0，完整保留 t 对象的时、分、秒
    let comps = c.dateComponents([.hour, .minute, .second], from: t)
    
    return c.date(bySettingHour: comps.hour ?? 0,
                  minute: comps.minute ?? 0,
                  second: comps.second ?? 0,
                  of: d) ?? d
}


// MARK: - 详细统计视图 - v2 - 退出自动备份
//
// struct DetailedStatsView
// (修改：新增 onDisappear 触发 dcs.backup)

struct DetailedStatsView: View {
    @EnvironmentObject var ts: TimeStore
    @EnvironmentObject var dcs: DetailedCategoryStore
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部窄条 (状态栏)
            currentStatusNarrowBar
            
            ScrollView {
                VStack(spacing: 24) {
                    // 2. 按四大分类展示按钮组
                    categoryGroup(title: "工作", icon: "briefcase.fill", color: getColor(for: "工作"))
                    categoryGroup(title: "生活", icon: "house.fill", color: getColor(for: "生活"))
                    categoryGroup(title: "刚需", icon: "bus.fill", color: getColor(for: "刚需"))
                    categoryGroup(title: "监控", icon: "eye.fill", color: getColor(for: "监控"))
                }
                .padding(20)
            }
        }
        .background(Color.black.ignoresSafeArea())
        // 【核心新增】
        .onDisappear {
            dcs.backup()
        }
    }
    
    // 顶部窄条组件
    private var currentStatusNarrowBar: some View {
        HStack {
            if let cur = ts.currentRecord {
                HStack(spacing: 4) {
                    Text(I18n.cat(cur.category)).bold()
                    if let sub = cur.subCategory {
                        Text("|").opacity(0.5)
                        Text(sub).bold()
                    }
                    Spacer()
                    Text(formatDuration(cur.duration, true))
                        .monospacedDigit()
                        .foregroundColor(getColor(for: cur.category))
                }
                .font(.system(size: 14))
                .padding(.horizontal, 16)
            } else {
                Text("等待开始...").font(.caption).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(Color.white.opacity(0.05))
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5), alignment: .bottom)
    }
    
    // 分类按钮组渲染
    private func categoryGroup(title: String, icon: String, color: Color) -> some View {
        let items = dcs.getItems(for: title)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(I18n.cat(title)).font(.headline).foregroundColor(.white)
                Spacer()
            }
            
            if items.isEmpty {
                Text("请在设置中添加\(title)项目").font(.caption2).foregroundColor(.gray.opacity(0.5))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(items) { item in
                        subItemButton(for: item, baseColor: color)
                    }
                }
            }
        }
    }
    
    // 单个子项快捷按钮
    private func subItemButton(for item: SubCategoryItem, baseColor: Color) -> some View {
        Button {
            // 启动逻辑：大类保持一致，记录具体子类
            ts.start(category: item.parentCategory, subCategory: item.name)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // 计算该子项今天的总时间
                Text(formatSubItemTodayDuration(item))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(baseColor.opacity(0.8))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
    
    // 辅助：计算子项今日时长
    private func formatSubItemTodayDuration(_ item: SubCategoryItem) -> String {
        let todayRecs = ts.getRecordsForDisplay(for: Date())
        let total = todayRecs
            .filter { $0.category == item.parentCategory && $0.subCategory == item.name }
            .reduce(0.0) { $0 + $1.duration }
        return formatDuration(total)
    }
}

// MARK: - 基础数据模型 - V4 - 增加 Equatable
//
// DailyEfficiency / CurrentState / BackupData
// (修改：为 DailyEfficiency 增加 Equatable，解决 DayShowcaseView 报错。
//  CurrentState 顺手加上 Equatable 方便比较。)

struct CurrentState: Codable, Equatable {
    let category: String
    let startTime: Date
}

struct DailyEfficiency: Codable, Equatable {
    var morningEff: Int = 6
    var afternoonEff: Int = 6
    var eveningEff: Int = 6
}

struct BackupData: Codable {
    let records: [TimeRecord]
    let efficiencyData: [String: DailyEfficiency]
    let targetHours: Int
    let targetEfficiency: Int
}

// MARK: - 番茄时间管理器 - v6 - 后台运行与通知修复
//
// PomodoroManager
// (逻辑修复：
//  1. [FIX] 引入 UNUserNotificationCenter，在开始计时时向系统注册本地通知，确保锁屏/后台也能响铃。
//  2. [FIX] 计时逻辑从“递减计数”改为“目标时间差计算”。记录 endTime，tick 时计算 (endTime - Now)，解决锁屏后计时器暂停的问题。
//  3. [ADD] 增加 App 回到前台时的状态校准 restoreState()。
//  4. [FIX] 停止或完成时，自动撤销未发送的系统通知。)

class PomodoroManager: ObservableObject {
    static let shared = PomodoroManager()
    
    enum PomoState { case idle, focus, paused, breakTime }
    
    @Published var state: PomoState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var totalDuration: Int = 0
    @Published var currentCycle: Int = 1
    
    // 【核心新增】记录绝对结束时间点，解决后台计时暂停问题
    private var targetEndTime: Date?
    
    private var timer: Timer?
    private var timeStore: TimeStore?
    
    // 持有 SettingsStore 的引用
    private var settingsStore: GlobalSettingsStore?
    
    private var segmentStartTime: Date?
    
    private init() {
        // 监听 App 回到前台，立即校准时间
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        #elseif os(macOS)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        #endif
    }
    
    // Setup 必须传入 settingsStore
    func setup(timeStore: TimeStore, settingsStore: GlobalSettingsStore) {
        self.timeStore = timeStore
        self.settingsStore = settingsStore
        requestNotificationPermission()
    }
    
    // MARK: - 属性代理
    var config: AppSettings { settingsStore?.config ?? AppSettings() }
    
    var focusDuration: Int { config.pomoFocusDuration }
    var splitDuration: Int { config.pomoSplitDuration }
    var shortBreak: Int { config.pomoShortBreak }
    var longBreak: Int { config.pomoLongBreak }
    var cyclesBeforeLong: Int { config.pomoCyclesBeforeLong }
    var autoStart: Bool { config.pomoAutoStart }
    
    // MARK: - 系统通知权限
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("Notification Error: \(error)") }
        }
    }
    
    // MARK: - Actions
    func startSession() {
        stopTimer()
        currentCycle = 1
        startFocus()
    }
    
    func togglePause() {
        if state == .focus {
            // 暂停：取消系统通知，保存当前进度
            cancelPendingNotifications()
            saveCurrentSegment(category: "工作")
            state = .paused
            stopTimer()
            targetEndTime = nil // 暂停时不记录结束时间
        } else if state == .paused {
            // 恢复：重新计算结束时间，注册新通知
            segmentStartTime = Date()
            state = .focus
            // 恢复时，remainingSeconds 保持不变，基于当前时间推算新的 endTime
            startTimer(seconds: remainingSeconds)
        }
    }
    
    func skipBreak() {
        cancelPendingNotifications()
        saveCurrentSegment(category: "生活")
        stopTimer()
        currentCycle += 1
        startFocus()
    }
    
    func stop() {
        cancelPendingNotifications() // 极其重要：用户手动停止，必须撤销通知，否则一会还会响
        if state == .focus { saveCurrentSegment(category: "工作") }
        else if state == .breakTime { saveCurrentSegment(category: "生活") }
        stopTimer()
        state = .idle
        remainingSeconds = 0
        totalDuration = 0
        segmentStartTime = nil
        targetEndTime = nil
    }
    
    // MARK: - Logic
    
    private func startFocus() {
        state = .focus
        let seconds = focusDuration * 60
        totalDuration = seconds
        segmentStartTime = Date()
        startTimer(seconds: seconds)
        
        // 注册专注结束通知
        scheduleNotification(seconds: Double(seconds), title: "专注完成", body: "休息一下吧！")
    }
    
    private func startBreak(isLong: Bool) {
        state = .breakTime
        let mins = isLong ? longBreak : shortBreak
        let seconds = mins * 60
        totalDuration = seconds
        segmentStartTime = Date()
        startTimer(seconds: seconds)
        
        // 注册休息结束通知
        scheduleNotification(seconds: Double(seconds), title: "休息结束", body: "准备开始新的专注。")
    }
    
    // 【核心修改】启动计时器，接收具体的秒数
    private func startTimer(seconds: Int) {
        remainingSeconds = seconds
        // 计算绝对结束时间点 = 当前 + 剩余秒数
        targetEndTime = Date().addingTimeInterval(TimeInterval(seconds))
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }
    
    private func stopTimer() {
        timer?.invalidate(); timer = nil
    }
    
    // 【核心修改】基于时间戳的 Tick，而非简单的减 1
    private func tick() {
        guard let endTime = targetEndTime else { return }
        let now = Date()
        
        // 计算剩余时间
        let diff = Int(endTime.timeIntervalSince(now))
        
        // 更新 UI
        if diff >= 0 {
            remainingSeconds = diff
            checkSplitSound()
        } else {
            // 时间到
            remainingSeconds = 0
            handleComplete()
        }
    }
    
    @objc private func handleAppDidBecomeActive() {
        // App 回到前台时，强制刷新一次时间
        if state == .focus || state == .breakTime {
            tick()
        }
    }
    
    private func checkSplitSound() {
        // 只有在前台运行时才播放切分音（后台无法播放短暂音效，除非申请后台音频权限，暂不处理）
        guard state == .focus, config.enableSplitSound else { return }
        let elapsed = totalDuration - remainingSeconds
        let splitSec = splitDuration * 60
        if elapsed > 0 && elapsed % splitSec == 0 {
            SoundManager.playSplit()
        }
    }
    
    private func handleComplete() {
        stopTimer()
        targetEndTime = nil
        
        // 注意：这里的 SoundManager.play 只在前台有效。
        // 后台响铃完全依赖 scheduleNotification 中的 sound 设置。
        
        if state == .focus {
            if config.enableFocusEndSound { SoundManager.play(config.focusEndSoundID) }
            saveCurrentSegment(category: "工作")
            
            let isLong = (currentCycle % cyclesBeforeLong == 0)
            startBreak(isLong: isLong)
            
        } else if state == .breakTime {
            if config.enableBreakEndSound { SoundManager.play(config.breakEndSoundID) }
            saveCurrentSegment(category: "生活")
            
            if state == .breakTime && totalDuration >= (longBreak * 60) {
                currentCycle = 0
            }
            currentCycle += 1
            
            if autoStart {
                startFocus()
            } else {
                state = .idle // 如果不自动开始，就回到空闲
            }
        }
    }
    
    private func saveCurrentSegment(category: String) {
        guard let start = segmentStartTime else { return }
        let now = Date()
        if now > start {
            timeStore?.addRecord(category: category, startTime: start, endTime: now)
        }
        segmentStartTime = nil
    }
    
    // MARK: - 系统通知核心逻辑
    
    private func scheduleNotification(seconds: TimeInterval, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // 使用系统默认声音，确保一定能响
        content.sound = .default
        
        // 如果想支持打断静音模式，需要配置 Critical Alerts（需要苹果特殊审批），暂用 default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "PomodoroTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["PomodoroTimer"])
    }
}

// MARK: - 番茄专注页 - v5 - 适配原生 macOS 编译
//
// PomodoroView
// (修改：
//  1. 将 UIDevice 的使用包裹在 #if !os(macOS) 中，适配 Mac 平台判定为非手机大屏。
//  2. 将 UIImpactFeedbackGenerator 的使用包裹在 #if !os(macOS) 中，解决 Mac 上无法编译震动反馈的问题。)

struct PomodoroView: View {
    @ObservedObject var manager = PomodoroManager.shared
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    
    // 进度比例
    var progress: CGFloat {
        if manager.totalDuration == 0 { return 0 }
        return CGFloat(manager.totalDuration - manager.remainingSeconds) / CGFloat(manager.totalDuration)
    }
    
    var ringColor: Color {
        switch manager.state {
        case .idle: return .gray
        case .focus, .paused: return .yellow
        case .breakTime: return .blue
        }
    }
    
    var stateText: String {
        switch manager.state {
        case .idle: return "点击开始"
        case .focus: return "专注中"
        case .paused: return "已暂停"
        case .breakTime: return "休息中"
        }
    }
    
    var timerString: String {
        let m = manager.remainingSeconds / 60
        let s = manager.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // 判断设备类型
    var isPad: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isPhoneLandscape = isLandscape && !isPad
            
            ZStack {
                if isPhoneLandscape {
                    // === iPhone 横屏布局 (左圈右文) ===
                    HStack(spacing: 40) {
                        // 左侧：缩小的圆环交互区
                        renderRing(size: 180, lineWidth: 15, showTextInside: false)
                            .onTapGesture { handleTap() }
                            .onLongPressGesture(minimumDuration: 1.0) { handleLongPress() }
                        
                        // 右侧：信息与数据区
                        VStack(alignment: .leading, spacing: 8) {
                            // 1. 大时间
                            Text(timerString)
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(manager.state == .paused ? 0.6 : 1.0)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                            // 2. 状态文本
                            Text(stateText)
                                .font(.title3.bold())
                                .foregroundColor(ringColor)
                            
                            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 4)
                            
                            // 3. 原底部数据 (移到此处)
                            HStack(spacing: 24) {
                                VStack(alignment: .leading) {
                                    Text("循环").font(.caption).foregroundColor(.gray)
                                    Text("#\(manager.currentCycle)").font(.headline).bold().foregroundColor(.white)
                                }
                                VStack(alignment: .leading) {
                                    Text("时长").font(.caption).foregroundColor(.gray)
                                    Text("\(manager.focusDuration) min").font(.headline).bold().foregroundColor(.yellow)
                                }
                            }
                        }
                        .frame(maxWidth: 200) // 限制文字区域宽度
                        .contentShape(Rectangle())
                        .onTapGesture { handleTap() } // 文字区域也能点击
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 50) // 【核心】避让底部导航栏
                    
                } else {
                    // === 竖屏/iPad 原始布局 ===
                    VStack {
                        Spacer()
                        
                        // 中间大交互圈
                        renderRing(size: 280, lineWidth: 20, showTextInside: true)
                            .onTapGesture { handleTap() }
                            .onLongPressGesture(minimumDuration: 1.0) { handleLongPress() }
                        
                        Spacer()
                        
                        // 底部统计信息
                        HStack(spacing: 40) {
                            VStack {
                                Text("当前循环").font(.caption).foregroundColor(.gray)
                                Text("#\(manager.currentCycle)").font(.title2).bold().foregroundColor(.white)
                            }
                            VStack {
                                Text("预设时长").font(.caption).foregroundColor(.gray)
                                Text("\(manager.focusDuration) min").font(.title2).bold().foregroundColor(.yellow)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    // 抽离圆环渲染逻辑
    @ViewBuilder
    func renderRing(size: CGFloat, lineWidth: CGFloat, showTextInside: Bool) -> some View {
        ZStack {
            // 背景光晕
            Circle()
                .fill(ringColor.opacity(0.15))
                .frame(width: size + 40, height: size + 40)
                .blur(radius: 30)
                .animation(.easeInOut(duration: 1.0), value: manager.state)
            
            // 进度底环
            Circle()
                .stroke(Color(white: 0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // 进度条
            Circle()
                .trim(from: 0, to: manager.state == .idle ? 1 : (1 - progress))
                .stroke(
                    AngularGradient(colors:[ringColor, ringColor.opacity(0.5)], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // 点击热区 & 内部内容
            ZStack {
                Circle().fill(Color.black.opacity(0.01))
                
                if showTextInside {
                    // 竖屏模式：文字在圈内
                    VStack(spacing: 8) {
                        if manager.state == .idle {
                            Image(systemName: "play.fill").font(.system(size: size * 0.2)).foregroundColor(ringColor)
                        } else {
                            Text(timerString)
                                .font(.system(size: size * 0.2, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(manager.state == .paused ? 0.6 : 1.0)
                            
                            Text(stateText)
                                .font(.title3).fontWeight(.bold).foregroundColor(ringColor)
                            
                            if manager.state != .idle {
                                Text(manager.state == .breakTime ? "点击直接开始" : (manager.state == .paused ? "点击继续" : "暂停 / 长按重置"))
                                    .font(.caption2).foregroundColor(.gray).padding(.top, 4)
                            }
                        }
                    }
                } else {
                    // 横屏模式：圈内只显示播放图标(空闲时)或简易状态
                    if manager.state == .idle {
                        Image(systemName: "play.fill").font(.system(size: size * 0.25)).foregroundColor(ringColor)
                    } else if manager.state == .paused {
                        Image(systemName: "pause.fill").font(.system(size: size * 0.25)).foregroundColor(ringColor.opacity(0.5))
                    }
                }
            }
            .frame(width: size - lineWidth, height: size - lineWidth)
        }
        .contentShape(Circle()) // 确保点击区域为圆形
        .focusable(false)
    }
    
    func handleTap() {
        #if !os(macOS)
        let gen = UIImpactFeedbackGenerator(style: .medium); gen.impactOccurred()
        #endif
        
        switch manager.state {
        case .idle: manager.startSession()
        case .focus, .paused: manager.togglePause()
        case .breakTime: manager.skipBreak()
        }
    }
    
    func handleLongPress() {
        if manager.state == .focus || manager.state == .paused {
            #if !os(macOS)
            let gen = UIImpactFeedbackGenerator(style: .heavy); gen.impactOccurred()
            #endif
            
            manager.stop()
        }
    }
}

// MARK: - TimeStore Part 1 - v180 - 扩展算法对账模型包含 L 列表

class TimeStore: ObservableObject {
    @Published var records: [TimeRecord] = []
    
    let lock = NSRecursiveLock()
    var isFreshLaunch = false
    weak var efficiencyStore: EfficiencyStore?
    var scoreTimer: Timer?
    
    // 【325号扩展】：增加 listL 用于存储缓存表快照
    struct AlgorithmDebugData: Identifiable, Equatable {
        let id = UUID()
        var recordA: TimeRecord
        var recordB: TimeRecord?
        var recordC: TimeRecord?
        var recordCPrev: TimeRecord?
        var recordD: TimeRecord?
        var recordE: TimeRecord?
        var listL: [TimeRecord] = [] // 【新增】
        
        static func == (lhs: AlgorithmDebugData, rhs: AlgorithmDebugData) -> Bool {
            return lhs.id == rhs.id
        }
    }
    @Published var lastAlgorithmDebug: AlgorithmDebugData?
    
    struct UndoSnapshot { let records: [TimeRecord] }
    var undoStack: [UndoSnapshot] = []
    var redoStack: [UndoSnapshot] = []
    var isUndoGrouping = false
    
    var isSyncingFromCloud = false
    var isInitialLoading = true
    private var hasSuccessfullyLoaded = false
    
    var lastSuccessfulCloudLoadDate = Date.distantPast
    let recordsFileName = "timeRecords_v20.json"
    let sharedKey = "sharedCurrentState"
    
    var reloadWorkItem: DispatchWorkItem?
    var pendingReload = false
    private var isLoadInProgress = false
    private var recordsRevision = 0
    var loadRetryCount = 0
    let maxLoadRetries = 3
    
    var currentRecord: TimeRecord? { records.last(where: { $0.isOngoing }) }
    
    init() {
        StartupDiagnostics.shared.mark("TimeStore.init")
        load()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.isInitialLoading = false }
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.efficiencyStore?.refreshCache(with: self.records, forceYesterday: false)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudFileChange), name: .CloudFileDidChange, object: nil)
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(checkForExternalUpdates), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif
    }
}

// MARK: - TimeStore Part 2 - v178 - 物理异步保存逻辑，消除主线程 I/O 阻塞

extension TimeStore {
    
    @objc func handleCloudFileChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String,
              path == "记录/\(recordsFileName)" else { return }

        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.handleCloudFileChange(notification) }
            return
        }
        
        pendingReload = true
        reloadWorkItem?.cancel()
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.pendingReload {
                self.pendingReload = false
                print("[TimeStore] 🕒 检测到云端变更，触发异步加载...")
                self.loadRetryCount = 0
                self.load()
            }
        }
        reloadWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }
    
    func load() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.load() }
            return
        }
        if isLoadInProgress {
            pendingReload = true
            return
        }
        isLoadInProgress = true
        let diagnosticStart = StartupDiagnostics.shared.begin("TimeStore.load")
        pendingReload = false
        let startingRevision = recordsRevision
        self.lock.lock()
        self.isSyncingFromCloud = true
        self.lock.unlock()
        
        let fileName = recordsFileName
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let loadedData = CloudFileManager.shared.smartLoad(folder: .records, fileName: fileName)
            let loadedRecords = loadedData.flatMap { try? JSONDecoder().decode([TimeRecord].self, from: $0) }
            let cloudURL = CloudFileManager.shared.getCloudDir(.records).appendingPathComponent(fileName)
            let cloudModDate = (try? cloudURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            DispatchQueue.main.async {
            if startingRevision != self.recordsRevision {
                self.isLoadInProgress = false
                self.isSyncingFromCloud = false
                if self.pendingReload { self.load() }
                StartupDiagnostics.shared.end("TimeStore.load.stale", since: diagnosticStart)
                return
            }
            if let loadedRecords {
                self.lock.lock()
                self.records = loadedRecords
                self.isFreshLaunch = false
                self.hasSuccessfullyLoaded = true
                if let cloudModDate {
                    self.lastSuccessfulCloudLoadDate = cloudModDate
                }
                self.lock.unlock()
                
                self.efficiencyStore?.refreshCache(with: self.records, forceYesterday: true)
                self.syncToAppGroup()
                self.objectWillChange.send()
                
                self.isSyncingFromCloud = false
                self.loadRetryCount = 0
            } else {
                self.isSyncingFromCloud = false
                if !self.pendingReload && self.loadRetryCount < self.maxLoadRetries {
                    self.loadRetryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.loadRetryCount) * 0.5) { self.load() }
                }
            }
            self.isLoadInProgress = false
            if self.pendingReload { self.load() }
            StartupDiagnostics.shared.end("TimeStore.load", since: diagnosticStart)
            }
        }
    }

    func save() {
        if isSyncingFromCloud || isInitialLoading { return }
        recordsRevision += 1
        
        guard hasSuccessfullyLoaded else {
            print("[Sync] 尚未完成安全加载，跳过保存以保护数据。")
            return
        }
        
        // 【266号核心修改】：将保存快照和磁盘 I/O 移出主线程
        let recordsToSave = self.records
        let lastLoadDateSnapshot = self.lastSuccessfulCloudLoadDate
        
        Task {
            if recordsToSave.isEmpty && lastLoadDateSnapshot != Date.distantPast {
                print("[Critical] 拦截异常空数据保存请求。")
                return
            }

            if let d = try? JSONEncoder().encode(recordsToSave) {
                CloudSyncManager.shared.ignoreNextUpdate(relativePath: "记录/\(recordsFileName)")
                // saveDual 内部已异步化
                CloudFileManager.shared.saveDual(data: d, folder: .records, fileName: recordsFileName)
                
                // 备份操作同样异步执行
                BackupManager.shared.saveBackup(data: d, module: "TimeRecords")
                
                await MainActor.run {
                    self.efficiencyStore?.refreshCache(with: recordsToSave, forceYesterday: true)
                    self.lastSuccessfulCloudLoadDate = Date()
                }
            }
        }
    }
}

// MARK: - TimeStore Part 3 - v183 - 实现新旧记录物理交接与双重算法清洗

extension TimeStore {

    /// 【361号物理对齐】：启动新记录，确保旧记录 A 在 t 点结算并清洗，新记录 B 在 t 点启动并清洗
    func start(category: String, subCategory: String? = nil, at clickTime: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        if isSyncingFromCloud || isInitialLoading { return }
        
        // 1. 分类一致性拦截：如果目标大类和子类完全没变，则忽略请求
        if let cur = records.last(where: { $0.isOngoing }),
           cur.category == category && cur.subCategory == subCategory { return }
        
        performBatchUpdate {
            // 暂存点击时间 t (Junction Time)
            let t = clickTime
            
            // 2. 结束并清洗刚刚正在进行的记录 A
            if let ongoingIdx = self.records.lastIndex(where: { $0.isOngoing }) {
                let recordA = self.records[ongoingIdx]
                
                // 将 A 的终点锁定在 t
                let finalizedA = TimeRecord(
                    id: recordA.id,
                    category: recordA.category,
                    subCategory: recordA.subCategory,
                    startTime: recordA.startTime,
                    endTime: t
                )
                // “洗一遍” A：处理 A 与其左侧或编辑范围内的冲突
                self.processNewRecord_Safe(targetA: finalizedA, scopeRef: recordA)
            }
            
            // 3. 新建并清洗正在进行的记录 B
            let newOngoingB = TimeRecord(
                category: category,
                subCategory: subCategory,
                startTime: t,
                endTime: Date.distantFuture // 25:00 逻辑
            )
            
            // “洗一遍” B：确保 B 与刚才结算的 A 完美吸附，并清理 B 之后的所有潜在冲突
            self.processNewRecord_Safe(targetA: newOngoingB)
            
            print("[Action] 361号逻辑执行：\(category) 已在 \(Formatters.hhMM.string(from: t)) 无缝接龙并完成双重清洗")
        }
    }

    func editRecord(original: TimeRecord, newCategory: String, newStart: Date, newEnd: Date) {
        lock.lock(); defer { lock.unlock() }
        performBatchUpdate {
            let refinedNew = TimeRecord(id: original.id, category: newCategory, subCategory: nil, startTime: newStart, endTime: newEnd)
            processNewRecord_Safe(targetA: refinedNew, scopeRef: original)
        }
    }
    
    func editOngoing(newStart: Date, newCategory: String) {
        lock.lock(); defer { lock.unlock() }
        performBatchUpdate {
            if let ongoing = records.last(where: { $0.isOngoing }) {
                let refinedOngoing = TimeRecord(id: ongoing.id, category: newCategory, subCategory: nil, startTime: newStart, endTime: Date.distantFuture)
                processNewRecord_Safe(targetA: refinedOngoing, scopeRef: ongoing)
            }
        }
    }
}

// MARK: - TimeStore Part 4 - v181 - 状态管理与核心持久化收口

extension TimeStore {
    
    /// 【修复点】：物理补全 sortAndSave 方法
    func sortAndSave() {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        var ongoingRecord: TimeRecord? = nil
        // 1. 提取进行中的记录（如果有）
        if let last = records.last, last.isOngoing {
            ongoingRecord = records.removeLast()
        }
        
        // 2. 清理空的占位符并按时间正序排列
        records.removeAll { $0.category == "空" }
        records.sort { $0.startTime < $1.startTime }
        
        // 3. 将进行中的记录放回末尾
        if let ongoing = ongoingRecord {
            records.append(ongoing)
        }
        
        // 4. 执行物理磁盘写入与云端同步
        self.save()
        
        // 5. 同步数据至 AppGroup 供小组件使用
        self.syncToAppGroup()
    }
    
    func performBatchUpdate(_ block: () -> Void) {
        if isUndoGrouping { block(); return }
        isUndoGrouping = true
        undoStack.append(UndoSnapshot(records: records))
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()
        block()
        isUndoGrouping = false
    }
    
    func undo() {
        lock.lock(); defer { lock.unlock() }
        guard let p = undoStack.popLast() else { return }
        redoStack.append(UndoSnapshot(records: records))
        records = p.records
        sortAndSave()
    }
    
    func redo() {
        lock.lock(); defer { lock.unlock() }
        guard let n = redoStack.popLast() else { return }
        undoStack.append(UndoSnapshot(records: records))
        records = n.records
        sortAndSave()
    }
    
    @objc func checkForExternalUpdates() {
        if isSyncingFromCloud || isInitialLoading { return }
        guard let shared = UserDefaults(suiteName: appGroupIdentifier),
              let d = shared.data(forKey: sharedKey),
              let ext = try? JSONDecoder().decode(CurrentState.self, from: d) else { return }
        let cur = self.currentRecord
        if cur == nil || cur?.category != ext.category || abs(cur?.startTime.timeIntervalSince(ext.startTime) ?? 0) > 2.0 {
            DispatchQueue.main.async { self.start(category: ext.category, at: ext.startTime) }
        }
    }
    
    func syncToAppGroup() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        Task { await startLiveActivity() }
        #endif
        guard let shared = UserDefaults(suiteName: appGroupIdentifier) else { return }
        if let c = currentRecord {
            if let d = try? JSONEncoder().encode(CurrentState(category: c.category, startTime: c.startTime)) {
                shared.set(d, forKey: sharedKey)
            }
        } else {
            shared.removeObject(forKey: sharedKey)
        }
        shared.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    private func startLiveActivity() async {
        guard let current = currentRecord else {
            for a in Activity<TimeTrackerAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) }
            return
        }
        let s = UserDefaults(suiteName: appGroupIdentifier)?.double(forKey: "sharedYesterdayScore") ?? 0.0
        let content = ActivityContent(state: TimeTrackerAttributes.ContentState(category: current.category, startTime: current.startTime, yesterdayScore: s), staleDate: nil)
        if let e = Activity<TimeTrackerAttributes>.activities.first {
            await e.update(content)
        } else {
            _ = try? Activity.request(attributes: TimeTrackerAttributes(), content: content, pushType: nil)
        }
    }
    #endif
}

// MARK: - 全量时间算法核心 - v195 - 增加微小记录物理吞噬逻辑，消除 0min 垃圾

extension TimeStore {
    
    func validateRecords() {
        let now = Date()
        for i in 0..<records.count {
            if !records[i].isOngoing {
                if records[i].endTime > now { records[i].endTime = now }
                if records[i].startTime > now { records[i].startTime = now; records[i].endTime = now }
            }
        }
    }
    
    func getRecordsForDisplay(for date: Date) -> [TimeRecord] {
        let cal = Calendar.current
        let sDay = cal.startOfDay(for: date)
        let eDay = cal.date(byAdding: .day, value: 1, to: sDay)!
        let now = Date()
        return records.filter { r in
            let effectiveEnd = r.isOngoing ? now : r.endTime
            return r.startTime < eDay && effectiveEnd > sDay
        }.sorted { $0.startTime < $1.startTime }
    }
    
    func getTodayDuration(category: String) -> TimeInterval {
        let recs = getRecordsForDisplay(for: Date())
        return recs.filter { $0.category == category }.reduce(0.0) {
            $0 + ( $1.isOngoing ? Date().timeIntervalSince($1.startTime) : $1.endTime.timeIntervalSince($1.startTime))
        }
    }
    
    func splitCrossDayHelper(_ record: TimeRecord) -> [TimeRecord] {
        if record.isOngoing { return [record] }
        let cal = Calendar.current
        var segments: [TimeRecord] = []
        var currentStart = record.startTime
        let finalEnd = record.endTime
        let category = record.category
        while !cal.isDate(currentStart, inSameDayAs: finalEnd) && currentStart < finalEnd {
            let nextMidnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: currentStart))!
            if nextMidnight > currentStart {
                let seg = TimeRecord(category: category, subCategory: nil, startTime: currentStart, endTime: Swift.min(nextMidnight, finalEnd))
                if seg.duration >= 1 { segments.append(seg) }
            }
            currentStart = nextMidnight
        }
        if finalEnd > currentStart {
            let seg = TimeRecord(category: category, subCategory: nil, startTime: currentStart, endTime: finalEnd)
            if seg.duration >= 1 { segments.append(seg) }
        }
        return segments
    }

    /// 【361-2号核心重构】：核心安检口算法，实装微小记录物理吞噬协议
    func processNewRecord_Safe(targetA: TimeRecord, scopeRef: TimeRecord? = nil) {
        
        // --- Step 0: 环境准备 ---
        var A = targetA; A.subCategory = targetA.subCategory
        let cal = Calendar.current
        var minStart = A.startTime; var maxEnd = A.isOngoing ? A.startTime : A.endTime
        
        if let B_ref = scopeRef {
            if B_ref.startTime < minStart { minStart = B_ref.startTime }
            let bEnd = B_ref.isOngoing ? Date() : B_ref.endTime
            if bEnd > maxEnd { maxEnd = bEnd }
        }
        
        let windowStart = cal.startOfDay(for: cal.date(byAdding: .day, value: -1, to: minStart)!)
        let windowEnd = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: maxEnd))!
        
        var L: [TimeRecord] = []; var Rest: [TimeRecord] = []
        for r in self.records {
            let rEnd = r.isOngoing ? Date.distantFuture : r.endTime
            if r.startTime < windowEnd && rEnd > windowStart { L.append(r) } else { Rest.append(r) }
        }
        L.sort { $0.startTime < $1.startTime }
        
        // --- Step 0.3: 微小记录物理吞噬 (针对快速点击导致的 0min 堆积) ---
        if !A.isOngoing && A.duration < 60 {
            // 寻找物理终点紧邻 A 起点的记录 C（允许 2 秒误差）
            if let cIdx = L.firstIndex(where: { abs($0.endTime.timeIntervalSince(A.startTime)) < 2.0 }) {
                // 执行物理吞噬：前一个记录 C 延长至 A 的终点
                var C = L[cIdx]
                C.endTime = A.endTime
                L[cIdx] = C
                
                // 如果被修改的是旧的 ongoing 副本，物理移除
                if let old = scopeRef { L.removeAll { $0.id == old.id } }
                
                self.records = Rest + L
                self.sortAndSave()
                print("[Algorithm] 361-2号补丁：已吞噬不足60秒的微小记录碎片")
                return // A 已被 C 吸收，逻辑闭环退出
            }
        }

        // --- Step 0.5: 对账快照捕捉 ---
        var debugInfo = AlgorithmDebugData(recordA: A, listL: L)
        if let bIdx = L.firstIndex(where: {
            let bE = $0.isOngoing ? Date.distantFuture : $0.endTime
            return $0.startTime < A.startTime && bE > (A.startTime + 1.0)
        }) {
            debugInfo.recordB = L[bIdx]; if bIdx > 0 { debugInfo.recordC = L[bIdx - 1] }
        }
        if !A.isOngoing {
            if let dIdx = L.firstIndex(where: {
                let dE = $0.isOngoing ? Date.distantFuture : $0.endTime
                return $0.startTime < (A.endTime - 1.0) && dE > A.endTime
            }) {
                debugInfo.recordD = L[dIdx]; if dIdx < L.count - 1 { debugInfo.recordE = L[dIdx + 1] }
            }
        }
        DispatchQueue.main.async { self.lastAlgorithmDebug = debugInfo }
        
        let aEndLimit = A.isOngoing ? Date.distantFuture : A.endTime

        // --- Step 1: 初始吞并 ---
        L.removeAll { R in
            let rEnd = R.isOngoing ? Date.distantFuture : R.endTime
            return R.startTime >= A.startTime && rEnd <= aEndLimit
        }
        
        // --- Step 2: 左边界处理 (1秒容差) ---
        var i = 0
        while i < L.count {
            let B = L[i]
            let bEnd = B.isOngoing ? Date.distantFuture : B.endTime
            if B.startTime < A.startTime && bEnd > (A.startTime + 1.0) {
                if B.category == A.category {
                    if i > 0 { L[i-1].endTime = A.startTime }
                    if bEnd > aEndLimit { L[i].startTime = A.startTime } else { L.remove(at: i); continue }
                } else {
                    let fragDur = A.startTime.timeIntervalSince(B.startTime)
                    if fragDur >= 60 {
                        var fragment = B; fragment.endTime = A.startTime; L.insert(fragment, at: i); i += 1; L[i].startTime = A.startTime
                    } else {
                        if i > 0 { L[i-1].endTime = A.startTime }; L[i].startTime = A.startTime
                    }
                    if (L[i].isOngoing ? Date.distantFuture : L[i].endTime) > aEndLimit { L[i].startTime = aEndLimit }
                    else { L.remove(at: i); continue }
                }
            }
            i += 1
        }
        
        // --- Step 3: 右边界处理 (1秒容差) ---
        if !A.isOngoing {
            var j = 0
            while j < L.count {
                let D = L[j]
                let dEnd = D.isOngoing ? Date.distantFuture : D.endTime
                if D.startTime < (A.endTime - 1.0) && dEnd > A.endTime {
                    if D.category == A.category {
                        if j + 1 < L.count { L[j+1].startTime = A.endTime }
                        L.remove(at: j); continue
                    } else {
                        if dEnd.timeIntervalSince(A.endTime) >= 60 { L[j].startTime = A.endTime }
                        else { if j + 1 < L.count { L[j+1].startTime = A.endTime }; L.remove(at: j); continue }
                    }
                }
                j += 1
            }
        }
        
        // --- Step 4: 最终缝合 ---
        if let old = scopeRef { L.removeAll { $0.id == old.id } }
        L.append(A); L.sort { $0.startTime < $1.startTime }
        if let idx = L.firstIndex(where: { $0.id == A.id }) {
            var finalA = L[idx]
            if idx > 0 && L[idx-1].category == finalA.category { finalA.startTime = L[idx-1].startTime; L.remove(at: idx-1) }
            if let curI = L.firstIndex(where: { $0.id == finalA.id }), curI < L.count - 1 && L[curI+1].category == finalA.category {
                finalA.endTime = L[curI+1].endTime; L.remove(at: curI+1); L[curI] = finalA
            } else if let curI = L.firstIndex(where: { $0.id == finalA.id }) { L[curI] = finalA }
        }
        
        // --- Step 5: 跨日裁断 ---
        var tempL: [TimeRecord] = []
        for r in L { tempL.append(contentsOf: splitCrossDayHelper(r)) }
        L = tempL
        
        // --- Step 6: 连贯处理 ---
        L.sort { $0.startTime < $1.startTime }
        if L.count > 1 {
            for k in 1..<L.count {
                if !L[k-1].isOngoing { L[k].startTime = L[k-1].endTime }
            }
        }
        
        // --- Step 7: 存档与外向吸附 ---
        if !L.isEmpty {
            if let restPrev = Rest.filter({ $0.endTime <= windowStart }).sorted(by: { $0.endTime < $1.endTime }).last {
                let gap = L[0].startTime.timeIntervalSince(restPrev.endTime)
                if abs(gap) <= 60 { L[0].startTime = restPrev.endTime }
            }
            if let lastIdx = L.indices.last, !L[lastIdx].isOngoing {
                if let restNext = Rest.filter({ $0.startTime >= windowEnd }).sorted(by: { $0.startTime < $1.startTime }).first {
                    let gap = restNext.startTime.timeIntervalSince(L[lastIdx].endTime)
                    if abs(gap) <= 60 { L[lastIdx].endTime = restNext.startTime }
                }
            }
        }
        
        self.records = Rest + L
        self.sortAndSave()
    }
}

// MARK: - TimeStore Part 6 - v171 - 物理补全记录增删工具方法

extension TimeStore {
    
    /// 【修复点】：物理补全 addRecord，适配补录页面调用
    func addRecord(category: String, startTime: Date, endTime: Date) {
        lock.lock(); defer { lock.unlock() }
        if category == "空" { return }
        performBatchUpdate {
            // 物理转发至核心安检口执行 Step 0-6
            processNewRecord_Safe(targetA: TimeRecord(category: category, subCategory: nil, startTime: startTime, endTime: endTime))
        }
    }
    
    /// 【修复点】：物理补全 deleteRecord
    func deleteRecord(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        performBatchUpdate {
            if let i = records.firstIndex(where: {$0.id == r.id}) {
                records.remove(at: i)
            }
            sortAndSave()
        }
    }
    
    func restore(from b: BackupFile) {
        if let data = try? Data(contentsOf: b.url), let r = try? JSONDecoder().decode([TimeRecord].self, from: data) {
            self.records = r
            self.isFreshLaunch = false
            self.save()
            self.syncToAppGroup()
            self.objectWillChange.send()
        }
    }
    
    func clearAllData() {
        lock.lock(); defer { lock.unlock() }
        records.removeAll()
        save()
        syncToAppGroup()
    }
    
    func canUndo() -> Bool { !undoStack.isEmpty }
    func canRedo() -> Bool { !redoStack.isEmpty }
    
    func findLastEndTime() -> Date? {
        records.filter{ !$0.isOngoing }.sorted { $0.endTime < $1.endTime }.last?.endTime
    }
    
    func findPreviousEndTime(before d: Date, excludeId: UUID? = nil) -> Date? {
        let s = records.filter { $0.id != excludeId && !$0.isOngoing }.sorted { $0.endTime < $1.endTime }
        for r in s.reversed() {
            if r.endTime <= d.addingTimeInterval(2.0) { return r.endTime }
        }
        return nil
    }
    
    func findNextStartTime(after d: Date, excludeId: UUID? = nil) -> Date? {
        let s = records.filter { $0.id != excludeId }.sorted { $0.startTime < $1.startTime }
        for r in s {
            if r.startTime >= d.addingTimeInterval(-2.0) { return r.startTime }
        }
        return nil
    }
    
    func findAddRecordDefaultStartTime(for d: Date) -> Date? {
        let ds = Calendar.current.startOfDay(for: d)
        let de = Calendar.current.date(byAdding: .day, value: 1, to: ds)!
        let c = records.filter { !$0.isOngoing && $0.endTime > ds && $0.endTime <= de }.sorted { $0.endTime < $1.endTime }
        if let l = c.last { return abs(l.endTime.timeIntervalSince(de)) < 2.0 ? ds : l.endTime }
        return ds
    }
    
    func findAddRecordDefaultEndTime(for d: Date, after sT: Date) -> Date? {
        let de = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: d))!
        let next = records.filter { $0.startTime >= sT }.sorted { $0.startTime < $1.startTime }.first
        return next != nil ? next!.startTime : min(sT.addingTimeInterval(3600), de)
    }
    
    // --- 快捷上下文动作 ---
    
    func eatNext(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        if let i = records.firstIndex(where: {$0.id == r.id}), i < records.count - 1 {
            if !records[i+1].isOngoing {
                editRecord(original: r, newCategory: r.category, newStart: r.startTime, newEnd: records[i+1].endTime)
            }
        }
    }
    
    func eatPrevious(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        if let i = records.firstIndex(where: {$0.id == r.id}), i > 0 {
            editRecord(original: r, newCategory: r.category, newStart: records[i-1].startTime, newEnd: r.endTime)
        }
    }
    
    func mergeIntoPrevious(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        if let i = records.firstIndex(where: {$0.id == r.id}), i > 0 {
            let pC = records[i-1].category
            if r.isOngoing { editOngoing(newStart: r.startTime, newCategory: pC) }
            else { editRecord(original: r, newCategory: pC, newStart: r.startTime, newEnd: r.endTime) }
        }
    }
    
    func mergeIntoNext(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        if let i = records.firstIndex(where: {$0.id == r.id}), i < records.count - 1 {
            let nC = records[i+1].category
            if r.isOngoing { editOngoing(newStart: r.startTime, newCategory: nC) }
            else { editRecord(original: r, newCategory: nC, newStart: r.startTime, newEnd: r.endTime) }
        }
    }
    
    func extendOneHour(_ r: TimeRecord) {
        lock.lock(); defer { lock.unlock() }
        if !r.isOngoing {
            editRecord(original: r, newCategory: r.category, newStart: r.startTime, newEnd: r.endTime.addingTimeInterval(3600))
        }
    }
    
    func updateStartTime(for r: TimeRecord, newStartTime: Date) {
        lock.lock(); defer { lock.unlock() }
        if r.isOngoing { editOngoing(newStart: newStartTime, newCategory: r.category) }
        else { editRecord(original: r, newCategory: r.category, newStart: newStartTime, newEnd: r.endTime) }
    }
    
    func updateCategory(for r: TimeRecord, to nC: String) {
        lock.lock(); defer { lock.unlock() }
        if r.isOngoing { editOngoing(newStart: r.startTime, newCategory: nC) }
        else { editRecord(original: r, newCategory: r.category, newStart: r.startTime, newEnd: r.endTime) }
    }
    
    func mergePreviousIntoOngoing() {
        lock.lock(); defer { lock.unlock() }
        guard let cur = currentRecord,
              let i = records.firstIndex(where: { $0.id == cur.id }),
              i > 0,
              abs(records[i-1].endTime.timeIntervalSince(cur.startTime)) < 2.0 else { return }
        let nS = records[i-1].startTime
        records.remove(at: i-1)
        editOngoing(newStart: nS, newCategory: cur.category)
    }
}







// MARK: - iCloud 同步监听器 - v31 - 修复路径解析编译错误
//
// CloudSyncManager
// (修改：
//  1. 修复 extractRelativePath 中的数组切片报错，改用 dropFirst。
//  2. 保持文件级事件总线功能。)

extension Notification.Name {
    /// 文件级变更通知
    /// userInfo: ["path": "记录/xxx.json", "date": Date, "type": "modified"]
    static let CloudFileDidChange = Notification.Name("CloudFileDidChange")
}

// MARK: - iCloud 同步监听器

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    private var query: NSMetadataQuery?
    private var debounceTimer: Timer?
    
    // 缓存最后更新时间：Key = relativePath (e.g. "记录/timeRecords_v20.json")
    private var lastKnownUpdateDates: [String: Date] = [:]
    
    // 忽略列表：Key = relativePath
    private var ignoreList: [String: Date] = [:]
    private let lock = NSLock()
    
    init() {
        // 延时启动，避免 App 启动瞬间争抢资源
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.startObserving() }
    }
    
    // 告诉管理器忽略某个文件的下一次更新 (防回声)
    // 格式要求：relativePath (e.g. "记录/timeRecords.json")
    func ignoreNextUpdate(relativePath: String) {
        lock.lock()
        ignoreList[relativePath] = Date()
        lock.unlock()
        print("[CloudSync] 添加忽略规则: \(relativePath)")
    }
    
    func startObserving() {
        if query != nil { return }
        StartupDiagnostics.shared.mark("CloudSyncManager.startObserving")
        
        let q = NSMetadataQuery()
        q.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        let activeFileNames = [
            "timeRecords_v20.json", "efficiency_data_final_v20.json",
            "weekly_targets_v20.json", "efficiency_settings_v20.json",
            "sub_categories_config.json", "global_settings.json"
        ]
        q.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: activeFileNames.map {
            NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, $0)
        })
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(processUpdates), name: .NSMetadataQueryDidFinishGathering, object: q)
        nc.addObserver(self, selector: #selector(processUpdates), name: .NSMetadataQueryDidUpdate, object: q)
        
        q.start()
        self.query = q
        print("[CloudSync] 同步雷达已启动 (文件级精准模式)")
    }
    
    @objc private func processUpdates(_ notification: Notification) {
        guard let q = query else { return }
        let diagnosticStart = StartupDiagnostics.shared.begin("CloudSyncManager.processUpdates count=\(q.results.count)")
        defer { StartupDiagnostics.shared.end("CloudSyncManager.processUpdates", since: diagnosticStart) }
        
        q.disableUpdates()
        
        var globalRefreshNeeded = false
        
        for item in q.results {
            guard let metaItem = item as? NSMetadataItem,
                  let url = metaItem.value(forAttribute: NSMetadataItemURLKey) as? URL,
                  let modDate = metaItem.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date else { continue }
            
            // 解析相对路径
            let relativePath = extractRelativePath(from: url)
            let status = metaItem.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            
            lock.lock()
            
            // 1. 检查是否在忽略名单中 (5秒内的写入视为回声)
            if let lastWrite = ignoreList[relativePath], Date().timeIntervalSince(lastWrite) < 5.0 {
                lastKnownUpdateDates[relativePath] = modDate
                lock.unlock()
                continue
            }
            
            // 2. 检查是否未下载
            if status == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
                try? FileManager.default.startDownloadingUbiquitousItem(at: url)
                lock.unlock()
                continue
            }
            
            // 3. 检查是否真的是新变化
            let lastDate = lastKnownUpdateDates[relativePath] ?? Date.distantPast
            if modDate.timeIntervalSince(lastDate) > 1.1 {
                lastKnownUpdateDates[relativePath] = modDate
                globalRefreshNeeded = true
                
                print("[CloudSync] 📝 变更检测: \(relativePath)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CloudFileDidChange"),
                        object: nil,
                        userInfo: [
                            "path": relativePath,
                            "date": modDate,
                            "type": "modified"
                        ]
                    )
                }
            }
            lock.unlock()
        }
        
        q.enableUpdates()
        
        // 4. 触发全局兜底通知 (兼容旧代码)
        if globalRefreshNeeded {
            triggerThrottledGlobalReload()
        }
    }
    
    // 辅助：从 URL 解析出 "文件夹/文件名.ext"
    private func extractRelativePath(from url: URL) -> String {
        let pathComponents = url.pathComponents
        let knownFolders = ["记录", "设置"]
        
        // 倒序查找已知文件夹名
        for (i, component) in pathComponents.enumerated().reversed() {
            if knownFolders.contains(component) {
                // 找到了父文件夹，接下来的就是文件名
                if i + 1 < pathComponents.count {
                    let fileName = pathComponents.dropFirst(i + 1).joined(separator: "/")
                    return "\(component)/\(fileName)"
                }
            }
        }
        // 兜底：直接返回文件名
        return url.lastPathComponent
    }
    
    private func triggerThrottledGlobalReload() {
        debounceTimer?.invalidate()
        // 1.5秒防抖，避免频繁刷新
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            DispatchQueue.main.async {
                print("[CloudSync] 🌍 触发全局兼容刷新 (CloudDataUpdated)")
                NotificationCenter.default.post(name: NSNotification.Name("CloudDataUpdated"), object: nil)
            }
        }
    }
}

// MARK: - 修改记录视图 - v5 - 适配 macOS 震动反馈

struct EditRecordView: View, Identifiable {
    var id: UUID { record.id }
    let record: TimeRecord
    @EnvironmentObject var ts: TimeStore
    @Environment(\.dismiss) var dismiss
    
    @State var cat = ""
    @State var sDate = Date(); @State var sTime = Date()
    @State var eDate = Date(); @State var eTime = Date()
    
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            getColor(for: cat).opacity(0.15).ignoresSafeArea().blur(radius: 60)
            
            VStack(spacing: 12) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.down.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4)) }
                    Spacer()
                    Text(NSLocalizedString("edit_record_title", comment: "")).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill").opacity(0)
                }.padding(.horizontal).padding(.top, 20).padding(.bottom, 5)
                
                HStack(spacing: 15) {
                    ForEach(allCategories.filter{$0 != "空"}, id: \.self) { c in
                        WidgetStyleCategoryBtn(title: c, isSelected: cat == c) { withAnimation { cat = c } }
                    }
                }.padding(.bottom, 5)
                
                VStack(spacing: 8) {
                    GlassInputContainer(title: NSLocalizedString("start_time", comment: "")) {
                        HStack(spacing: 8) {
                            DatePicker("", selection: $sDate, in: ...Date(), displayedComponents: .date).labelsHidden().colorScheme(.dark)
                            DatePicker("", selection: $sTime, in: ...Date(), displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            Spacer()
                            GlassActionBtn(icon: "", title: NSLocalizedString("equal_end", comment: "")) { sDate = eDate; sTime = eTime }
                            GlassActionBtn(icon: "", title: NSLocalizedString("connect_prev", comment: "")) {
                                if let p = ts.findPreviousEndTime(before: record.startTime) { updateStart(to: p) }
                            }
                        }.frame(height: 36)
                    }
                    QuickActionGrid { minutes in modifyTime(isStart: true, minutes: minutes) }
                }
                
                VStack(spacing: 8) {
                    GlassInputContainer(title: NSLocalizedString("end_time_limit", comment: "")) {
                        HStack(spacing: 8) {
                            DatePicker("", selection: $eDate, in: ...Date(), displayedComponents: .date).labelsHidden().colorScheme(.dark)
                            DatePicker("", selection: $eTime, in: ...Date(), displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            Spacer()
                            GlassActionBtn(icon: "", title: NSLocalizedString("equal_start", comment: "")) { eDate = sDate; eTime = sTime }
                            GlassActionBtn(icon: "", title: NSLocalizedString("connect_next", comment: "")) {
                                if let n = ts.findNextStartTime(after: record.endTime, excludeId: record.id) { updateEnd(to: n) }
                            }
                        }.frame(height: 36)
                    }
                    QuickActionGrid { minutes in modifyTime(isStart: false, minutes: minutes) }
                }
                
                Spacer()
                
                GradientMainButton(title: NSLocalizedString("save_change", comment: ""), icon: "checkmark") {
                    let fs = combineDates(sDate, sTime)
                    let fe = combineDates(eDate, eTime)
                    
                    if fs > fe {
                        showAlert = true
                        return
                    }
                    
                    let finalEnd = min(fe, Date())
                    ts.editRecord(original: record, newCategory: cat, newStart: fs, newEnd: finalEnd)
                    dismiss()
                }.padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            cat = record.category == "空" ? "生活" : record.category
            sDate = record.startTime; sTime = record.startTime
            eDate = record.isOngoing ? Date() : record.endTime
            eTime = record.isOngoing ? Date() : record.endTime
        }
        .presentationDetents([.fraction(0.85)])
        .alert("错误", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("开始时间不能晚于结束时间")
        }
    }
    
    func modifyTime(isStart: Bool, minutes: Int) {
        let base = isStart ? combineDates(sDate, sTime) : combineDates(eDate, eTime)
        if let new = Calendar.current.date(byAdding: .minute, value: minutes, to: base) {
            let now = Date()
            if isStart {
                if new > now { sDate = now; sTime = now } else { sDate = new; sTime = new }
            } else {
                if new > now {
                    eDate = now; eTime = now
                    #if !os(macOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                }
                else { eDate = new; eTime = new }
            }
        }
    }
    func updateStart(to date: Date) { sDate = date; sTime = date }
    func updateEnd(to date: Date) { let now = Date(); if date > now { eDate = now; eTime = now } else { eDate = date; eTime = date } }
}

// MARK: - 任务视图 - v59 - 消除系统导航栏冲突与适配 macOS

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var efficiencyStore: EfficiencyStore
    
    @State private var newTaskTitle: String = ""
    @FocusState private var isFocused: Bool
    
    @State private var dragTargetListID: String? = nil
    @State private var editingCalendar: EKCalendar? = nil
    @State private var showingAllViewSettings = false
    @State private var detailTask: TaskItem? = nil
    
    @AppStorage("task_list_icons_v1") var listIconCache: String = "{}"
    @AppStorage("settings_showCompletedTasks") var showCompletedTasks = false
    
    enum FilterType: Equatable { case all; case scheduled; case list(String) }
    @State private var selectedFilter: FilterType = .all
    
    var themeColor: Color {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let s = GlobalLogic.calculateScore(for: yesterday, records: timeStore.getRecordsForDisplay(for: yesterday), es: efficiencyStore)
        if s >= 100 { return Color(red: 0.6, green: 0.2, blue: 1.0) }
        if s >= 80 { return .yellow }
        if s >= 60 { return .green }
        return Color(white: 0.6)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                GeometryReader { geo in MainBackgroundView(themeColor: themeColor).frame(height: UIScreen.mainSafe.bounds.height).offset(y: -geo.frame(in: .global).minY) }.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                TaskHeaderIcon(
                                    icon: "tray.fill",
                                    color: .gray,
                                    label: I18n.t(.task_all),
                                    count: taskStore.tasks.filter { !$0.isCompleted }.count,
                                    isSelected: selectedFilter == .all,
                                    isDropTarget: false,
                                    action: { withAnimation { selectedFilter = .all } },
                                    onLongPress: {
                                        #if !os(macOS)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        #endif
                                        showingAllViewSettings = true
                                    }
                                )
                                
                                ForEach(taskStore.taskLists, id: \.calendarIdentifier) { calendar in
                                    TaskHeaderIcon(
                                        icon: getIconForList(id: calendar.calendarIdentifier),
                                        color: Color(cgColor: calendar.cgColor),
                                        label: calendar.title,
                                        count: taskStore.tasks.filter { !$0.isCompleted && $0.listName == calendar.title }.count,
                                        isSelected: selectedFilter == .list(calendar.calendarIdentifier),
                                        isDropTarget: dragTargetListID == calendar.calendarIdentifier,
                                        action: { withAnimation { selectedFilter = .list(calendar.calendarIdentifier) } },
                                        onLongPress: {
                                            #if !os(macOS)
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            #endif
                                            editingCalendar = calendar
                                        }
                                    )
                                    .onDrop(of: [.text], isTargeted: Binding(get: { dragTargetListID == calendar.calendarIdentifier }, set: { isTargeted in if isTargeted { dragTargetListID = calendar.calendarIdentifier } else if dragTargetListID == calendar.calendarIdentifier { dragTargetListID = nil } }), perform: { providers in handleTaskDrop(providers: providers, targetListID: calendar.calendarIdentifier) })
                                }
                            }
                            .padding(.horizontal, 24).padding(.vertical, 15)
                        }
                    }
                    .background(.ultraThinMaterial.opacity(0.3))
                    
                    List {
                        Color.clear.frame(height: 10).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        if selectedFilter == .all && taskStore.allViewGroupByList {
                            let grouped = Dictionary(grouping: getSortedBaseTasks(), by: { $0.listName })
                            let sortedKeys = grouped.keys.sorted()
                            ForEach(sortedKeys, id: \.self) { listName in
                                Section {
                                    ForEach(grouped[listName] ?? []) { task in
                                        TaskNativeRow(task: task, onEditDetail: { detailTask = task })
                                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)).listRowBackground(Color.clear).listRowSeparator(.hidden).onDrag { NSItemProvider(object: task.id.uuidString as NSString) }
                                    }
                                } header: { Text(listName).font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(.white.opacity(0.4)).padding(.leading, 4) }
                            }
                        } else {
                            ForEach(getFilteredAndSortedTasks()) { task in
                                TaskNativeRow(task: task, onEditDetail: { detailTask = task })
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)).listRowBackground(Color.clear).listRowSeparator(.hidden).onDrag { NSItemProvider(object: task.id.uuidString as NSString) }.swipeActions(edge: .leading, allowsFullSwipe: true) { Button(role: .destructive) { taskStore.delete(task) } label: { Label(I18n.t(.delete), systemImage: "trash") } }
                            }
                        }
                        Color.clear.frame(height: 150).listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .ignoresSafeArea(edges: .bottom)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22, weight: .bold)).foregroundColor(.blue)
                    TextField(I18n.t(.task_add_placeholder), text: $newTaskTitle).font(.system(size: 15, weight: .medium, design: .rounded)).submitLabel(.done).focused($isFocused).onSubmit { addNewTask() }
                }.padding(.horizontal, 16).padding(.vertical, 10).background { Capsule().fill(.ultraThinMaterial).shadow(color: .black.opacity(0.3), radius: 10, y: 5) }.overlay { Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5) }.padding(.horizontal, 20).padding(.bottom, 10)
            }
            .ttToolbarHidden(for: .navigationBar)
            .sheet(item: $editingCalendar) { calendar in
                TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                    TaskListEditSheet(calendar: calendar).environmentObject(taskStore)
                }
            }
            .sheet(isPresented: $showingAllViewSettings) {
                TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                    TaskAllViewSortSheet().environmentObject(taskStore)
                }
            }
            .sheet(item: $detailTask) { task in
                TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                    TaskDetailEditView(task: task, taskLists: taskStore.taskLists).environmentObject(taskStore)
                }
            }
            .onDisappear { taskStore.backup() }
        }
    }
    
    private func getSortedBaseTasks() -> [TaskItem] { let base = taskStore.tasks.filter { showCompletedTasks || !$0.isCompleted }; return sortTasks(base, by: taskStore.allViewSortOrder) }
    private func getFilteredAndSortedTasks() -> [TaskItem] { let base = taskStore.tasks.filter { showCompletedTasks || !$0.isCompleted }; switch selectedFilter { case .all: return sortTasks(base, by: taskStore.allViewSortOrder); case .scheduled: return sortTasks(base.filter { $0.dueDate != nil }, by: .dueDate); case .list(let id): let name = taskStore.taskLists.first(where: {$0.calendarIdentifier == id})?.title ?? ""; let order = taskStore.getSortConfigs()[id] ?? .manual; return sortTasks(base.filter { $0.listName == name }, by: order) } }
    private func sortTasks(_ list: [TaskItem], by order: TaskStore.TaskListSortOrder) -> [TaskItem] { switch order { case .manual, .creationDate: return list.sorted { (t1, t2) in t1.createdAt > t2.createdAt }; case .dueDate: return list.sorted { (t1, t2) in (t1.dueDate ?? Date.distantFuture) < (t2.dueDate ?? Date.distantFuture) }; case .priority: return list.sorted { (t1, t2) -> Bool in func weight(_ p: Int) -> Int { if p == 1 { return 0 }; if p == 5 { return 1 }; if p == 9 { return 2 }; return 3 }; let w1 = weight(t1.priority); let w2 = weight(t2.priority); if w1 != w2 { return w1 < w2 }; return t1.createdAt > t2.createdAt }; case .title: return list.sorted { (t1, t2) in t1.title.localizedStandardCompare(t2.title) == .orderedAscending } } }
    func getIconForList(id: String) -> String { if let data = listIconCache.data(using: .utf8), let dict = try? JSONDecoder().decode([String: String].self, from: data) { return dict[id] ?? "list.bullet" }; return "list.bullet" }
    func addNewTask() { guard !newTaskTitle.isEmpty else { return }; var targetID: String? = nil; if case .list(let id) = selectedFilter { targetID = id }; taskStore.addTask(title: newTaskTitle, listID: targetID); newTaskTitle = "" }
    
    func handleTaskDrop(providers:[NSItemProvider], targetListID: String) -> Bool {
        guard let item = providers.first else { return false }
        item.loadObject(ofClass: NSString.self) { (str, err) in
            if let uuidStr = str as? String, let uuid = UUID(uuidString: uuidStr) {
                DispatchQueue.main.async {
                    if let task = taskStore.tasks.first(where: { $0.id == uuid }) {
                        if let currentListID = taskStore.taskLists.first(where: { $0.title == task.listName })?.calendarIdentifier, currentListID != targetListID {
                            taskStore.moveToList(task, targetListID: targetListID)
                            #if !os(macOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }
                    }
                    self.dragTargetListID = nil
                }
            }
        }
        return true
    }
}

// MARK: - “全部”视图设置弹窗 - v1 - 全局排序与列表分类控制
//
// TaskAllViewSortSheet
// (逻辑内容：
//  1. 控制 TaskStore.allViewSortOrder。
//  2. 控制 TaskStore.allViewGroupByList 分类开关。)

struct TaskAllViewSortSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("布局方式")) {
                    Toggle("按照列表分类显示", isOn: $taskStore.allViewGroupByList)
                        .tint(.blue)
                }
                
                Section(header: Text("内部排序")) {
                    Picker("排序维度", selection: $taskStore.allViewSortOrder) {
                        ForEach(TaskStore.TaskListSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
                
                Section(footer: Text("开启分类显示后，任务将按所属提醒列表分层，组内按所选维度排序。")) {
                    EmptyView()
                }
            }
            .navigationTitle("“全部”视图设置")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}



// MARK: - 列表编辑弹窗 - v2 - 增加排序方式同步选择
//
// TaskListEditSheet
// (修改内容：
//  1. 增加了“默认排序方式”选择器，对齐系统维度。
//  2. 整合保存逻辑，确保排序偏好与物理属性一并更新。)

struct TaskListEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let calendar: EKCalendar
    
    @State private var title: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "list.bullet"
    @State private var selectedSortOrder: TaskStore.TaskListSortOrder = .manual // 【新增】
    
    @AppStorage("task_list_icons_v1") var listIconCache: String = "{}"
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .gray]
    let icons: [String] = ["list.bullet", "house.fill", "briefcase.fill", "cart.fill", "heart.fill", "star.fill", "bell.fill", "bookmark.fill", "flag.fill", "tag.fill"]

    init(calendar: EKCalendar) {
        self.calendar = calendar
        _title = State(initialValue: calendar.title)
        if let cgColor = calendar.cgColor {
            _selectedColor = State(initialValue: Color(cgColor: cgColor))
        }
        
        // 【新增】初始化排序配置
        let configs = TaskStore().getSortConfigs() // 临时实例读取或通过参数传递更佳
        _selectedSortOrder = State(initialValue: configs[calendar.calendarIdentifier] ?? .manual)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("列表信息") {
                    TextField("列表名称", text: $title)
                    HStack {
                        Text("当前图标")
                        Spacer()
                        Image(systemName: selectedIcon).foregroundColor(selectedColor).font(.title2)
                    }
                }
                
                // 【新增】排序方式选择
                Section("列表展示") {
                    Picker("默认排序方式", selection: $selectedSortOrder) {
                        ForEach(TaskStore.TaskListSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
                
                Section("颜色同步") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.self) { color in
                                Circle().fill(color).frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0))
                                    .onTapGesture { selectedColor = color }
                            }
                        }.padding(.vertical, 5)
                    }
                }
                
                Section("图标样式 (仅 App 内部展示)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon).font(.title3).frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedColor, lineWidth: selectedIcon == icon ? 2 : 0))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }
            }
            .navigationTitle("编辑列表")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("完成") { save() }.fontWeight(.bold) }
            }
            .onAppear { loadInitialData() }
        }
        .presentationDetents([.medium, .large])
    }
    
    func loadInitialData() {
        if let data = listIconCache.data(using: .utf8), let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            selectedIcon = dict[calendar.calendarIdentifier] ?? "list.bullet"
        }
        let configs = taskStore.getSortConfigs()
        selectedSortOrder = configs[calendar.calendarIdentifier] ?? .manual
    }

    func save() {
        taskStore.updateListProperties(calendarID: calendar.calendarIdentifier, newTitle: title, newColor: UIColor(selectedColor))
        taskStore.updateListSortOrder(calendarID: calendar.calendarIdentifier, order: selectedSortOrder) // 【同步排序】
        
        var dict: [String: String] = [:]
        if let data = listIconCache.data(using: .utf8), let decoded = try? JSONDecoder().decode([String: String].self, from: data) { dict = decoded }
        dict[calendar.calendarIdentifier] = selectedIcon
        if let encoded = try? JSONEncoder().encode(dict), let str = String(data: encoded, encoding: .utf8) { listIconCache = str }
        dismiss()
    }
}


// MARK: - 任务详情编辑页 - v1 - 模仿苹果提醒事项详情交互
//
// TaskDetailEditView
// (逻辑内容：
//  1. 提供标题、备注、日期、列表、优先级、旗标的综合编辑 UI。
//  2. 自动载入任务当前属性。
//  3. 点击“完成”调用 TaskStore 进行苹果系统层面的属性同步。)

struct TaskDetailEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let task: TaskItem
    
    @State private var title: String
    @State private var notes: String
    @State private var useDate: Bool
    @State private var dueDate: Date
    @State private var selectedList: EKCalendar?
    @State private var priority: Int
    @State private var isFlagged: Bool

    init(task: TaskItem, taskLists: [EKCalendar]) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes ?? "")
        _useDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date().addingTimeInterval(3600))
        _priority = State(initialValue: task.priority)
        _isFlagged = State(initialValue: task.isFlagged)
        
        let initialList = taskLists.first(where: { $0.title == task.listName })
        _selectedList = State(initialValue: initialList)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...10)
                }
                
                Section {
                    Toggle(isOn: $useDate) {
                        Label("日期与时间", systemImage: "calendar")
                    }
                    if useDate {
                        DatePicker("截止时间", selection: $dueDate)
                    }
                }
                
                Section {
                    Picker(selection: $selectedList) {
                        ForEach(taskStore.taskLists, id: \.calendarIdentifier) { cal in
                            HStack {
                                Circle().fill(Color(cgColor: cal.cgColor)).frame(width: 8, height: 8)
                                Text(cal.title)
                            }.tag(cal as EKCalendar?)
                        }
                    } label: {
                        Label("列表", systemImage: "list.bullet")
                    }
                }
                
                Section {
                    Picker("优先级", selection: $priority) {
                        Text("无").tag(0)
                        Text("低").tag(9)
                        Text("中").tag(5)
                        Text("高").tag(1)
                    }
                    
                    Toggle(isOn: $isFlagged) {
                        Label("旗标", systemImage: "flag.fill")
                    }
                }
            }
            .navigationTitle("详细信息")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                    }.fontWeight(.bold)
                }
            }
        }
    }
    
    func save() {
        taskStore.updateTaskProperties(
            item: task,
            newTitle: title,
            newNotes: notes.isEmpty ? nil : notes,
            newPriority: priority,
            newFlag: isFlagged,
            newDueDate: useDate ? dueDate : nil,
            newList: selectedList
        )
        dismiss()
    }
}




// MARK: - 任务头部图标按钮 - v6 - 增加长按修改手势
//
// TaskHeaderIcon
// (修改内容：
//  1. 增加 onLongPress 闭包属性。
//  2. 实装 onLongPressGesture 手势，用于触发列表属性编辑。
//  3. 视觉上强化选中与拖拽目标的反馈。)

struct TaskHeaderIcon: View {
    let icon: String
    let color: Color
    let label: String
    let count: Int
    let isSelected: Bool
    let isDropTarget: Bool
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil // 【新增】
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    ZStack {
                        Circle().fill(color).frame(width: 30, height: 30)
                        Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                HStack {
                    Text(label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(isSelected ? 0.9 : 0.4))
                        .lineLimit(1)
                    Spacer()
                }
            }
            .padding(12)
            .frame(width: 106, height: 84)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDropTarget ? color.opacity(0.3) : Color.white.opacity(isSelected ? 0.12 : 0.06))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDropTarget ? color : (isSelected ? color.opacity(0.6) : Color.white.opacity(0.1)), lineWidth: isDropTarget ? 2 : 1.5)
            }
            .scaleEffect(isDropTarget ? 1.05 : 1.0)
            .animation(.spring(), value: isDropTarget)
        }
        .buttonStyle(.plain)
        // 【新增长按逻辑】
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
    }
}


// MARK: - 任务行组件 - v9 - 移除列表名称显示
//
// TaskNativeRow
// (修改：
//  1. 移除了 task.listName 的显示逻辑，使行高更紧凑。
//  2. 保持日期和优先级的显示。)

struct TaskNativeRow: View {
    let task: TaskItem
    @EnvironmentObject var taskStore: TaskStore
    @State private var localTitle: String = ""
    @FocusState private var isFocused: Bool
    
    var onEditDetail: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if task.indentationLevel > 0 { Color.clear.frame(width: 20) }
            
            Button { taskStore.toggleComplete(task) } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.gray.opacity(0.5) : task.listColor, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(task.listColor)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    TextField("", text: $localTitle)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(task.isCompleted ? .white.opacity(0.3) : .white)
                        .strikethrough(task.isCompleted)
                        .focused($isFocused)
                        .onSubmit { taskStore.updateTitle(task, newTitle: localTitle) }
                        .onDrop(of: [.text], isTargeted: nil) { _ in return true }
                    
                    // 点击进入编辑模式后显示详情入口
                    if isFocused || localTitle != task.title {
                        Button {
                            onEditDetail?()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundColor(task.listColor)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                
                // 第二行：日期、优先级 (已移除列表名称，高度自适应)
                HStack(spacing: 8) {
                    if let date = task.dueDate, !task.isCompleted {
                        Label(formatDate(date), systemImage: "alarm.fill")
                            .foregroundColor(date < Date() ? .red : .white.opacity(0.4))
                    }
                    
                    if task.priority > 0 {
                        Text(priorityLabel(task.priority))
                            .foregroundColor(.orange).font(.caption2).bold()
                    }
                }
                .font(.system(size: 11, weight: .bold))
            }
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? task.listColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
        }
        .onAppear { localTitle = task.title }
        .onChange(of: task.title) { _, newValue in if !isFocused { localTitle = newValue } }
        .animation(.spring(response: 0.3), value: isFocused)
    }
    
    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { f.dateFormat = "HH:mm"; return "今天 " + f.string(from: date) }
        else { f.dateFormat = "MM/dd HH:mm"; return f.string(from: date) }
    }
    
    func priorityLabel(_ p: Int) -> String {
        switch p { case 1: return "!!!"; case 5: return "!!"; case 9: return "!"; default: return "" }
    }
}

// MARK: - 过滤器图标按钮 - v1
struct FilterIconBtn: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(isSelected ? color : Color(white: 0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : color)
                }
                Text(title).font(.caption).foregroundColor(isSelected ? .white : .gray)
                if count > 0 {
                    Text("\(count)").font(.caption2).foregroundColor(.gray.opacity(0.8))
                }
            }
            .frame(width: 60)
            .padding(4)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}



// MARK: - 任务行组件 - v23 - 适配新设计
//
//  TaskRow
//  (微调样式以适应分组卡片布局，去除圆角背景，改为透明以便嵌入 Group 容器)

struct TaskRow: View {
    let task: TaskItem
    @EnvironmentObject var taskStore: TaskStore
    
    var body: some View {
        HStack(spacing: 12) {
            Button { taskStore.toggleTask(task) } label: {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.gray : task.listColor, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if task.isCompleted {
                        Circle().fill(Color.gray).frame(width: 14, height: 14)
                    }
                }
            }.buttonStyle(.plain)
            
            Text(task.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(task.isCompleted ? .gray : .white)
                .strikethrough(task.isCompleted, color: .gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 仅在已完成时显示删除按钮 (虽然本视图过滤了已完成，但为了逻辑完整性保留)
            if task.isCompleted {
                Button { taskStore.deleteTask(task) } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 14))
                }.buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.clear) // 背景透明，由父容器控制
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3), value: task.isCompleted)
    }
}



// MARK: - 日历主页 - v37 - 增加草稿悬浮取消按钮
//
// CalendarPageView
// (修改内容：
//  1. 在最外层嵌套 ZStack。
//  2. 增加逻辑判断：当 draftStart != nil 时，在右下角显示“取消新建”悬浮按钮。
//  3. 按钮位置通过 padding 调整，确保在底部导航栏上方。)

struct CalendarPageView: View {
    @EnvironmentObject var cs: CalendarStore
    @State private var timelineType = 0
    @State private var date = Date()
    @State private var pickDate = false
    @State private var showSettings = false
    @State private var showScheduleMaker = false
    
    // Draft State
    @State private var isDrafting = false
    @State private var draftStart: Date? = nil
    @State private var draftEnd: Date? = nil
    @State private var showInputSheet = false
    
    private let totalHeight: CGFloat = 24 * 60
    @AppStorage("cal_default_duration") private var defaultDuration: Int = 60
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) { // 嵌套 ZStack 以支持悬浮按钮
            VStack(spacing: 0) {
                // 1. 顶部控制栏
                VStack(spacing: 8) {
                    HStack {
                        // 左：设置
                        Button { showSettings = true } label: { Image(systemName: "gearshape").font(.body).foregroundColor(.white.opacity(0.8)) }
                        
                        Spacer()
                        // 中：视图切换
                        Picker("", selection: $timelineType) { Text("日").tag(0); Text("周").tag(1); Text("月").tag(2) }
                            .pickerStyle(.segmented).frame(width: 160)
                        Spacer()
                        
                        // 右：课程表入口 + 今天
                        HStack(spacing: 16) {
                            if timelineType == 0 {
                                Button { showScheduleMaker = true } label: {
                                    Image(systemName: "rectangle.3.group")
                                        .font(.body).foregroundColor(.blue)
                                }
                            }
                            Button { date = Date() } label: { Text("今天").font(.body).foregroundColor(.red) }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    HStack {
                        // 日期导航
                        Button { mv(-1) } label: { Image(systemName: "chevron.left").font(.title3).foregroundColor(.white.opacity(0.6)) }
                        Spacer()
                        Button { pickDate = true } label: {
                            Text(getHeaderTitle())
                                .font(.title3).fontWeight(.semibold).foregroundColor(.white)
                        }
                        Spacer()
                        Button { mv(1) } label: { Image(systemName: "chevron.right").font(.title3).foregroundColor(.white.opacity(0.6)) }
                    }
                    .padding(.horizontal).padding(.bottom, 8)
                }
                .background(Color.clear)
                
                // 2. 时间轴主体
                GeometryReader { geo in
                    let availableWidth = geo.size.width
                    let availableHeight = geo.size.height
                    
                    if timelineType == 0 {
                        ScrollViewReader { proxy in
                            ScrollView {
                                ZStack(alignment: .top) {
                                    HStack(alignment: .top, spacing: 0) {
                                        TimeScale(step: 4, customHeight: totalHeight).frame(width: 50, height: totalHeight)
                                        
                                        ZStack(alignment: .topLeading) {
                                            CalendarDayColumn(date: date, width: availableWidth - 50, height: totalHeight, enableDrag: !isDrafting, enableEdit: !isDrafting, isDrafting: isDrafting)
                                            
                                            DraftTimelineLayer(
                                                date: date,
                                                draftStart: $draftStart,
                                                draftEnd: $draftEnd,
                                                totalHeight: totalHeight,
                                                width: availableWidth - 50,
                                                onTapBlock: { showInputSheet = true }
                                            )
                                            
                                            if Calendar.current.isDateInToday(date) {
                                                CurrentTimeLine(width: availableWidth - 50).offset(y: getCurrentTimeOffset())
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 100)
                            }
                            .onAppear { if !isDrafting { proxy.scrollTo(Int(getCurrentTimeOffset() / 60), anchor: .center) } }
                        }
                    } else if timelineType == 1 {
                        let days = getWeekDays(from: date)
                        let colWidth = (availableWidth - 50) / 7
                        HStack(alignment: .top, spacing: 0) {
                            TimeScale(step: 4, customHeight: availableHeight).frame(height: availableHeight)
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(days, id: \.self) { d in
                                    VStack(spacing: 0) {
                                        Text(wkDay(d)).font(.caption2).fontWeight(.bold).foregroundColor(Calendar.current.isDateInToday(d) ? .red : .gray).frame(height: 20)
                                        CalendarDayColumn(date: d, width: colWidth, height: availableHeight - 20, enableDrag: false, enableEdit: true, isDrafting: false)
                                    }.frame(width: colWidth)
                                }
                            }
                        }
                    } else {
                        let days = getMonthDays(from: date)
                        let colWidth = (availableWidth - 50) / CGFloat(max(1, days.count))
                        HStack(alignment: .top, spacing: 0) {
                            TimeScale(step: 4, customHeight: availableHeight).frame(height: availableHeight)
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(days, id: \.self) { d in CalendarDayColumn(date: d, width: colWidth, height: availableHeight, enableDrag: false, enableEdit: false, isDrafting: false) }
                            }
                        }
                    }
                }
            }
            
            // 3. 【新增】右下角悬浮取消按钮
            if draftStart != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    cancelDraft()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("取消新建")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.red.opacity(0.8)).shadow(radius: 10))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90) // 位于底部 TabBar 之上
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .scale)
                ))
                .zIndex(500)
            }
        }
        .sheet(isPresented: $pickDate) {
            TTModalSheetContainer(minWidth: 520, minHeight: 420) {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
            }
        }
        .sheet(isPresented: $showSettings) {
            TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                CalendarSettingsView()
            }
        }
        .sheet(isPresented: $showScheduleMaker) {
            TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                ClassScheduleSheet(sourceDate: date)
            }
        }
        .sheet(isPresented: $showInputSheet) {
            if let start = draftStart, let end = draftEnd {
                TTModalSheetContainer(minWidth: 860, minHeight: 720) {
                    NativeEventFormView(startDate: start, endDate: end) { title, notes, alarmOffset, calendarID, category in
                        cs.addEvent(title: title, start: start, end: end, isAllDay: false, location: "", notes: notes, calendarID: calendarID, category: category)
                        cancelDraft()
                    }
                }
            }
        }
        .onAppear { cs.selectedDate = date; cs.fetchEvents() }
        .onChange(of: date) { _, newVal in cs.selectDate(newVal) }
    }
    
    // Helpers
    func mv(_ i: Int) { let c = Calendar.current; var comp: Calendar.Component = .day; if timelineType == 1 { comp = .weekOfYear } else if timelineType == 2 { comp = .month }; if let n = c.date(byAdding: comp, value: i, to: date) { withAnimation { date = n } } }
    func getHeaderTitle() -> String { if timelineType == 0 { return Formatters.mmDDEEEE.string(from: date) }; return Formatters.yyyyMM.string(from: date) }
    func getWeekDays(from start: Date) -> [Date] { var c = Calendar.current; c.firstWeekday = 2; let ws = c.date(from: c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: start)) ?? start; return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: ws) } }
    func getMonthDays(from start: Date) -> [Date] { let c = Calendar.current; guard let r = c.range(of: .day, in: .month, for: start), let ms = c.date(from: c.dateComponents([.year, .month], from: start)) else { return [] }; return r.compactMap { c.date(byAdding: .day, value: $0 - 1, to: ms) } }
    func wkDay(_ d: Date) -> String { Formatters.weekDay.string(from: d) }
    func getCurrentTimeOffset() -> CGFloat { let now = Date(); let c = Calendar.current; return CGFloat(c.component(.hour, from: now) * 60 + c.component(.minute, from: now)) }
    func cancelDraft() { withAnimation(.spring(response: 0.3)) { draftStart = nil; draftEnd = nil } }
}

// MARK: - 草稿时间轴层 - v34 - 适配 macOS 震动反馈

struct DraftTimelineLayer: View {
    let date: Date
    @Binding var draftStart: Date?
    @Binding var draftEnd: Date?
    let totalHeight: CGFloat
    let width: CGFloat
    var onTapBlock: () -> Void
    
    @State private var initialDragStart: Date?
    @State private var initialDragEnd: Date?
    @AppStorage("cal_default_duration") private var defaultDuration: Int = 60
    @AppStorage("cal_default_title") private var defaultTitle: String = "新日程"
    
    var scale: CGFloat { totalHeight / (24 * 60) }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.opacity(0.001) // 响应区域
                .frame(width: width, height: totalHeight)
                .gesture(
                    LongPressGesture(minimumDuration: 0.3)
                        .onEnded { _ in }
                        .sequenced(before: DragGesture(minimumDistance: 0).onEnded { value in
                            createNewBlock(at: value.location.y)
                        })
                )
            
            if let start = draftStart, let end = draftEnd {
                let top = CGFloat(minutesFromStartOfDay(start)) * scale
                let height = CGFloat(end.timeIntervalSince(start) / 60.0) * scale
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                    
                    HStack {
                        Rectangle().fill(Color.blue).frame(width: 4)
                        Spacer()
                    }.clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(defaultTitle).font(.system(size: 12, weight: .semibold)).foregroundColor(.primary)
                        Text("\(Formatters.hhMM.string(from: start)) - \(Formatters.hhMM.string(from: end))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8).padding(.top, 4)
                }
                .frame(width: width - 4, height: max(20, height))
                .offset(y: top)
                .padding(.horizontal, 2)
                .onTapGesture { onTapBlock() }
                .gesture(DragGesture().onChanged { handleBlockMove($0) }.onEnded { _ in endDrag() })
                
                Color.clear.frame(width: width, height: 20).contentShape(Rectangle())
                    .offset(y: top - 10)
                    .gesture(DragGesture().onChanged { handleResize($0, isTop: true) }.onEnded { _ in endDrag() })
                
                Color.clear.frame(width: width, height: 20).contentShape(Rectangle())
                    .offset(y: top + height - 10)
                    .gesture(DragGesture().onChanged { handleResize($0, isTop: false) }.onEnded { _ in endDrag() })
            }
        }
        .frame(width: width, height: totalHeight)
    }
    
    func minutesFromStartOfDay(_ d: Date) -> Int {
        let c = Calendar.current; return c.component(.hour, from: d) * 60 + c.component(.minute, from: d)
    }
    func createNewBlock(at y: CGFloat) {
        let mins = Int(y / scale); let snapMins = (mins / 15) * 15
        let c = Calendar.current
        let start = c.date(bySettingHour: snapMins / 60, minute: snapMins % 60, second: 0, of: date) ?? date
        let end = start.addingTimeInterval(TimeInterval(defaultDuration * 60))
        withAnimation(.spring(response: 0.3)) { draftStart = start; draftEnd = end }
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    func handleBlockMove(_ value: DragGesture.Value) {
        if initialDragStart == nil {
            initialDragStart = draftStart; initialDragEnd = draftEnd
            #if !os(macOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        guard let s = initialDragStart, let e = initialDragEnd else { return }
        let delta = value.translation.height / scale
        let c = Calendar.current
        let rawS = s.addingTimeInterval(delta * 60)
        let m = c.component(.minute, from: rawS); let rm = (m/15)*15
        let newS = c.date(bySettingHour: c.component(.hour, from: rawS), minute: rm, second: 0, of: rawS) ?? rawS
        let dur = e.timeIntervalSince(s)
        if newS >= c.startOfDay(for: date) { draftStart = newS; draftEnd = newS.addingTimeInterval(dur) }
    }
    func handleResize(_ value: DragGesture.Value, isTop: Bool) {
        if initialDragStart == nil {
            initialDragStart = draftStart; initialDragEnd = draftEnd
            #if !os(macOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        guard let s = initialDragStart, let e = initialDragEnd else { return }
        let delta = value.translation.height / scale; let c = Calendar.current
        if isTop {
            let rawS = s.addingTimeInterval(delta * 60); let m = c.component(.minute, from: rawS); let rm = (m/15)*15
            let newS = c.date(bySettingHour: c.component(.hour, from: rawS), minute: rm, second: 0, of: rawS) ?? rawS
            if newS <= (draftEnd ?? e).addingTimeInterval(-900) { draftStart = newS }
        } else {
            let rawE = e.addingTimeInterval(delta * 60); let m = c.component(.minute, from: rawE); let rm = (m/15)*15
            let newE = c.date(bySettingHour: c.component(.hour, from: rawE), minute: rm, second: 0, of: rawE) ?? rawE
            if newE >= (draftStart ?? s).addingTimeInterval(900) { draftEnd = newE }
        }
    }
    func endDrag() {
        initialDragStart = nil; initialDragEnd = nil
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

// MARK: - 仿原生日程表单 - v3 - 增加行动类型选择
struct NativeEventFormView: View {
    let startDate: Date
    let endDate: Date
    // 回调增加 category 参数
    let onSave: (String, String, Int, String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cs: CalendarStore
    
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @AppStorage("cal_default_alarm_offset") private var alarmOffset: Int = -15
    @AppStorage("cal_default_calendar_id") private var calendarID: String = ""
    @AppStorage("cal_default_title") private var defaultTitle: String = "新日程"
    
    // 新增：默认行动类型
    @AppStorage("cal_default_category") private var selectedCategory: String = "工作"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(defaultTitle, text: $title)
                        .font(.system(size: 20))
                    TextField("位置", text: $location)
                }
                
                // 新增：选择 App 属性
                Section(header: Text("关联行动 (时间记录器)")) {
                    Picker("行动类型", selection: $selectedCategory) {
                        ForEach(allCategories.filter{$0 != "空"}, id: \.self) { cat in
                            HStack {
                                Circle().fill(getColor(for: cat)).frame(width: 8, height: 8)
                                Text(I18n.cat(cat))
                            }.tag(cat)
                        }
                    }
                }
                
                Section {
                    // 只读时间显示
                    HStack {
                        Text("开始")
                        Spacer()
                        Text(Formatters.mmDDEEEE.string(from: startDate) + " " + Formatters.hhMM.string(from: startDate))
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("结束")
                        Spacer()
                        Text(Formatters.mmDDEEEE.string(from: endDate) + " " + Formatters.hhMM.string(from: endDate))
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Picker("提醒", selection: $alarmOffset) {
                        Text("无").tag(0)
                        Text("日程发生时").tag(0)
                        Text("5分钟前").tag(-5)
                        Text("15分钟前").tag(-15)
                        Text("30分钟前").tag(-30)
                        Text("1小时前").tag(-60)
                        Text("1天前").tag(-1440)
                    }
                }
                
                Section {
                    Picker("日历", selection: $calendarID) {
                        Text("系统默认").tag("")
                        ForEach(cs.calendars, id: \.calendarIdentifier) { cal in
                            HStack {
                                Circle().fill(Color(cgColor: cal.cgColor)).frame(width: 8, height: 8)
                                Text(cal.title)
                            }.tag(cal.calendarIdentifier)
                        }
                    }
                }
                
                Section {
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新日程")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let finalTitle = title.isEmpty ? defaultTitle : title
                        onSave(finalTitle, notes, alarmOffset, calendarID, selectedCategory)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}


// MARK: - 课程表排课设置页 - V1
struct ClassScheduleSheet: View {
    let sourceDate: Date
    @EnvironmentObject var cs: CalendarStore
    @Environment(\.dismiss) var dismiss
    
    // 默认选中当前这天所在的星期
    @State private var selectedWeekdays: Set<Int> = []
    // 默认结束时间：3个月后 (模拟学期)
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 4, to: Date())!
    
    // 星期配置
    let weekDays = [
        (2, "周一"), (3, "周二"), (4, "周三"), (5, "周四"),
        (6, "周五"), (7, "周六"), (1, "周日")
    ]
    
    init(sourceDate: Date) {
        self.sourceDate = sourceDate
        // 初始化时，默认选中当前这一天
        let currentWeekday = Calendar.current.component(.weekday, from: sourceDate)
        _selectedWeekdays = State(initialValue: [currentWeekday])
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 说明区域
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("课程表排课模式")
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)
                        Text("将 \(Formatters.mmDDEEEE.string(from: sourceDate)) 的所有日程\n作为模板，按周复制到选定日期。")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // 1. 选择重复日
                    VStack(alignment: .leading, spacing: 12) {
                        Text("每周在这些天重复：").font(.headline).foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            ForEach(weekDays, id: \.0) { item in
                                WeekdayToggleBtn(
                                    title: item.1.replacingOccurrences(of: "周", with: ""),
                                    isSelected: selectedWeekdays.contains(item.0)
                                ) {
                                    if selectedWeekdays.contains(item.0) {
                                        selectedWeekdays.remove(item.0)
                                    } else {
                                        selectedWeekdays.insert(item.0)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                    
                    // 2. 选择截止日期
                    VStack(alignment: .leading, spacing: 12) {
                        Text("直到学期结束：").font(.headline).foregroundColor(.white)
                        DatePicker("截止日期", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .background(Color(white: 0.05))
                            .cornerRadius(10)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                    
                    Spacer()
                    
                    // 按钮
                    Button {
                        cs.applyClassSchedule(sourceDate: sourceDate, targetWeekdays: selectedWeekdays, endDate: endDate)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("生成课表 / 循环日程")
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(selectedWeekdays.isEmpty ? Color.gray : Color.blue))
                    }
                    .disabled(selectedWeekdays.isEmpty)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
        }
        .presentationDetents([.fraction(0.85)]) // 类似半屏弹窗
    }
}

// 辅助：星期选择按钮
struct WeekdayToggleBtn: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color(white: 0.2))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }
}




  // MARK: - 辅助组件：草稿胶囊手柄 - V1 - UI细节
  struct DraftCapsuleHandle: View {
      let time: Date
      let isTop: Bool
      
      var body: some View {
          HStack {
              if !isTop { Spacer() } // 下方手柄靠右
              HStack(spacing: 6) {
                  Image(systemName: "line.3.horizontal")
                      .font(.system(size: 10, weight: .bold))
                      .foregroundColor(.purple)
                  Text(Formatters.hhMM.string(from: time))
                      .font(.system(size: 12, weight: .bold, design: .monospaced))
                      .foregroundColor(.black)
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.3), radius: 3, y: 2))
              .overlay(Capsule().stroke(Color.purple, lineWidth: 1.5))
              if isTop { Spacer() } // 上方手柄靠左
          }
      }
  }

// MARK: - 草稿事件层 - V29 - 左右分栏交互版与适配 macOS 震动反馈

struct DraftEventLayer: View {
    @Binding var start: Date
    @Binding var end: Date
    let containerHeight: CGFloat
    let containerWidth: CGFloat
    let timeOffsetX: CGFloat
    
    @State private var initialStart: Date?
    @State private var initialEnd: Date?
    
    var scale: CGFloat { containerHeight / (24 * 60) }
    
    var body: some View {
        let dayStart = Calendar.current.startOfDay(for: start)
        let topPoint = CGFloat(start.timeIntervalSince(dayStart) / 60.0) * scale
        let durationMins = CGFloat(end.timeIntervalSince(start) / 60.0)
        let heightPoint = durationMins * scale
        
        let blockWidth = (containerWidth - 10) * 0.75
        let handleWidth = (containerWidth - 10) * 0.25
        
        ZStack(alignment: .topLeading) {
            
            HStack(alignment: .top, spacing: 0) {
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple)
                        .shadow(color: .purple.opacity(0.4), radius: 5, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("新日程")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text(formatDuration(mins: Int(durationMins)))
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(8)
                }
                .frame(width: blockWidth, height: max(20, heightPoint))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleMove(value)
                        }
                        .onEnded { _ in
                            initialStart = nil
                            initialEnd = nil
                            #if !os(macOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }
                )
                
                ZStack {
                    if heightPoint > 20 {
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 2, height: max(0, heightPoint - 20))
                            .offset(y: 0)
                    }
                    
                    VStack(spacing: 0) {
                        TimeCapsuleHandle(time: start, color: .purple)
                            .offset(y: -12)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in handleResize(value, isTop: true) }
                                    .onEnded { _ in endResize() }
                            )
                        
                        Spacer()
                        
                        TimeCapsuleHandle(time: end, color: .purple)
                            .offset(y: 12)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in handleResize(value, isTop: false) }
                                    .onEnded { _ in endResize() }
                            )
                    }
                    .frame(height: max(20, heightPoint))
                }
                .frame(width: handleWidth, height: max(20, heightPoint))
            }
            .offset(x: timeOffsetX + 5, y: topPoint)
        }
    }
    
    func handleMove(_ value: DragGesture.Value) {
        if initialStart == nil {
            initialStart = start
            initialEnd = end
        }
        
        guard let baseStart = initialStart, let baseEnd = initialEnd else { return }
        
        let deltaMins = Double(value.translation.height / scale)
        let rawDate = baseStart.addingTimeInterval(deltaMins * 60)
        
        let snapMins = (Calendar.current.component(.minute, from: rawDate) / 5) * 5
        let newStart = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: rawDate), minute: snapMins, second: 0, of: rawDate) ?? rawDate
        
        let duration = baseEnd.timeIntervalSince(baseStart)
        
        let dayStart = Calendar.current.startOfDay(for: baseStart)
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)
        
        if newStart >= dayStart && newStart.addingTimeInterval(duration) <= dayEnd {
            start = newStart
            end = start.addingTimeInterval(duration)
        }
    }
    
    func handleResize(_ value: DragGesture.Value, isTop: Bool) {
        if initialStart == nil {
            initialStart = start
            initialEnd = end
        }
        
        guard let baseStart = initialStart, let baseEnd = initialEnd else { return }
        
        let deltaMins = Double(value.translation.height / scale)
        let fiveMinInSec: TimeInterval = 300
        
        if isTop {
            let rawNewStart = baseStart.addingTimeInterval(deltaMins * 60)
            let snapMins = (Calendar.current.component(.minute, from: rawNewStart) / 5) * 5
            let newStart = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: rawNewStart), minute: snapMins, second: 0, of: rawNewStart) ?? rawNewStart
            
            if newStart <= end.addingTimeInterval(-fiveMinInSec) {
                start = newStart
            }
        } else {
            let rawNewEnd = baseEnd.addingTimeInterval(deltaMins * 60)
            let snapMins = (Calendar.current.component(.minute, from: rawNewEnd) / 5) * 5
            let newEnd = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: rawNewEnd), minute: snapMins, second: 0, of: rawNewEnd) ?? rawNewEnd
            
            if newEnd >= start.addingTimeInterval(fiveMinInSec) {
                end = newEnd
            }
        }
    }
    
    func endResize() {
        initialStart = nil
        initialEnd = nil
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    func formatDuration(mins: Int) -> String {
        let h = mins / 60
        let m = mins % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

  // MARK: - 辅助组件：时间胶囊手柄 - V1
  struct TimeCapsuleHandle: View {
      let time: Date
      let color: Color
      
      var body: some View {
          HStack(spacing: 4) {
              Image(systemName: "line.3.horizontal")
                  .font(.system(size: 8, weight: .bold))
                  .foregroundColor(color)
              Text(Formatters.hhMM.string(from: time))
                  .font(.system(size: 10, weight: .bold, design: .monospaced))
                  .foregroundColor(.black)
          }
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .background(Capsule().fill(Color.white))
          .overlay(Capsule().stroke(color, lineWidth: 1.5))
          .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
      }
  }

// MARK: - 日历时间轴列组件 - v28 - 适配 macOS 震动反馈

struct CalendarDayColumn: View {
    let date: Date
    let width: CGFloat
    let height: CGFloat
    let enableDrag: Bool
    let enableEdit: Bool
    let isDrafting: Bool
    
    @EnvironmentObject var cs: CalendarStore
    @State private var editingEvent: CalendarEventWrapper?
    
    var events: [CalendarEventWrapper] {
        cs.getEvents(for: date).filter { !$0.isAllDay }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TimelineGridBackground(width: width, totalHeight: height)
            
            ForEach(events) { event in
                CalendarEventBlock(
                    event: event,
                    dayStart: Calendar.current.startOfDay(for: date),
                    totalHeight: height,
                    columnWidth: width
                )
                .opacity(isDrafting ? 0.3 : 1.0)
                .onLongPressGesture {
                    if enableEdit && !isDrafting {
                        #if !os(macOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

  // MARK: - 日历事件块 - V1
  struct CalendarEventBlock: View {
      let event: CalendarEventWrapper
      let dayStart: Date
      let totalHeight: CGFloat
      let columnWidth: CGFloat
      
      var body: some View {
          let frame = calculateFrame()
          if frame.height > 0 {
              RoundedRectangle(cornerRadius: 6)
                  .fill(event.color.opacity(0.8))
                  .overlay(
                      VStack(alignment: .leading, spacing: 0) {
                          Text(event.title)
                              .font(.system(size: 11, weight: .bold))
                              .foregroundColor(.white)
                              .lineLimit(1)
                          if frame.height > 30 {
                              Text(Formatters.hhMM.string(from: event.startDate))
                                  .font(.system(size: 9))
                                  .foregroundColor(.white.opacity(0.8))
                          }
                          Spacer()
                      }
                      .padding(4)
                      , alignment: .topLeading
                  )
                  .frame(width: columnWidth - 4, height: frame.height)
                  .offset(y: frame.top)
                  .padding(.horizontal, 2)
          }
      }
      
      func calculateFrame() -> (top: CGFloat, height: CGFloat) {
          let start = max(event.startDate, dayStart)
          let end = min(event.endDate, dayStart.addingTimeInterval(24*3600))
          
          let startMins = start.timeIntervalSince(dayStart) / 60.0
          let durationMins = end.timeIntervalSince(start) / 60.0
          
          let scale = totalHeight / (24 * 60)
          return (CGFloat(startMins) * scale, max(10, CGFloat(durationMins) * scale))
      }
  }

// MARK: - 口算训练视图 - v6 - 适配 macOS 震动反馈屏蔽

struct MentalMathView: View {
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var efficiencyStore: EfficiencyStore
    
    @State private var num1: Int = 0
    @State private var num2: Int = 0
    @State private var userInput: String = ""
    @State private var totalSolved: Int = 0
    @State private var correctCount: Int = 0
    @State private var usedNumbers: Set<Int> = []
    @State private var showSuccessFeedback: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var themeColor: Color {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return GlobalLogic.calculateScore(for: yesterday, records: timeStore.getRecordsForDisplay(for: yesterday), es: efficiencyStore) >= 80 ? .yellow : .green
    }
    
    var body: some View {
        ZStack {
            MainBackgroundView(themeColor: themeColor).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 顶部统计
                HStack(spacing: 16) {
                    statCard(title: I18n.t(.math_solved), value: "\(totalSolved)", color: .gray)
                    statCard(title: I18n.t(.math_correct), value: "\(correctCount)", color: .green)
                }
                .padding(.horizontal, 24).padding(.top, 10)
                
                // 【166号修正】：间距从 50 减至 10，上移 40px
                Spacer().frame(height: 10)
                
                // 2. 题目显示
                HStack(spacing: 15) {
                    numberBox(value: num1)
                    Text("×").font(.system(size: 32, weight: .black)).foregroundColor(.orange)
                    numberBox(value: num2)
                }
                // 【166号修正】：间距从 40 减至 20，输入框相对再上移 20px（总计 60px）
                .padding(.bottom, 20)
                
                // 3. 输入区
                VStack(spacing: 12) {
                    TextField(I18n.t(.math_input), text: $userInput)
                        .focused($isTextFieldFocused)
                        .keyboardType(.numberPad)
                        .font(.system(size: 54, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.08)))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .onChange(of: userInput) { _, _ in checkAnswer() }
                    
                    Text(I18n.t(.math_hint)).font(.caption).foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Button(I18n.t(.math_reset)) {
                    totalSolved = 0; correctCount = 0; usedNumbers.removeAll(); generateNewProblem()
                }
                .font(.caption).foregroundColor(.red.opacity(0.4)).padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            if showSuccessFeedback {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 100)).foregroundColor(.green)
                        Text(I18n.t(.math_success)).font(.system(size: 40, weight: .black, design: .rounded)).foregroundColor(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                }.zIndex(100)
            }
        }
        .onAppear { generateNewProblem(); isTextFieldFocused = true }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) { Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.5)); Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(color) }
        .frame(maxWidth: .infinity).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }
    
    private func numberBox(value: Int) -> some View {
        Text("\(value)").font(.system(size: 48, weight: .black, design: .monospaced)).foregroundColor(.white).frame(width: 100, height: 100).background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.12)))
    }
    
    private func generateNewProblem() {
        num1 = getValidRandomNumber(); num2 = getValidRandomNumber(); userInput = ""
    }
    
    private func getValidRandomNumber() -> Int {
        var attempts = 0
        while attempts < 100 {
            let n = Int.random(in: 21...99)
            let lastDigit = n % 10
            if lastDigit > 1 && !usedNumbers.contains(n) {
                usedNumbers.insert(n)
                return n
            }
            attempts += 1
        }
        usedNumbers.removeAll()
        return Int.random(in: 22...99)
    }
    
    private func checkAnswer() {
        guard let val = Int(userInput) else { return }
        if val == (num1 * num2) {
            correctCount += 1
            totalSolved += 1
            
            #if !os(macOS)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            #endif
            
            withAnimation(.spring()) {
                showSuccessFeedback = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showSuccessFeedback = false
                    generateNewProblem()
                }
            }
        }
    }
}

// MARK: - 日历设置视图 - v4 - 适配 GlobalSettingsStore
struct CalendarSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cs: CalendarStore
    // 【核心变化】使用全局设置
    @EnvironmentObject var store: GlobalSettingsStore
    
    let alarmOptions = [0: "无", -300: "5分钟前", -900: "15分钟前", -1800: "30分钟前", -3600: "1小时前", -86400: "1天前"]
    let durationOptions = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("APP 联动设置")) {
                    Picker("默认行动类型", selection: $store.config.calDefaultCategory) {
                        ForEach(allCategories.filter{$0 != "空"}, id: \.self) { cat in
                            HStack {
                                Circle().fill(getColor(for: cat)).frame(width: 8, height: 8)
                                Text(I18n.cat(cat))
                            }.tag(cat)
                        }
                    }
                    Text("所有新建日程将默认关联此行动类型，到点提醒切换。").font(.caption).foregroundColor(.gray)
                }
                
                Section(header: Text("默认日程信息")) {
                    HStack {
                        Text("默认标题")
                        TextField("例如：新日程", text: $store.config.calDefaultTitle).multilineTextAlignment(.trailing)
                    }
                    
                    Picker("默认时长", selection: $store.config.calDefaultDuration) {
                        ForEach(durationOptions, id: \.self) { min in Text("\(min) 分钟").tag(min) }
                    }
                }
                
                Section(header: Text("偏好设置")) {
                    Picker("默认提醒", selection: $store.config.calDefaultAlarmOffset) {
                        ForEach(alarmOptions.keys.sorted(by: >), id: \.self) { key in
                            Text(alarmOptions[key] ?? "").tag(key)
                        }
                    }
                    
                    Picker("默认日历", selection: $store.config.calDefaultCalendarID) {
                        Text("系统默认").tag("")
                        ForEach(cs.calendars, id: \.calendarIdentifier) { cal in
                            HStack {
                                Circle().fill(Color(cgColor: cal.cgColor)).frame(width: 8, height: 8)
                                Text(cal.title)
                            }.tag(cal.calendarIdentifier)
                        }
                    }
                }
            }
            .navigationTitle("日历设置")
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } }
            }
            .onAppear { cs.fetchAllCalendars() }
        }
    }
}


// MARK: - 添加日程 Sheet - V2 - 适配分类参数 (修复参数缺失)
  struct AddEventSheet: View {
      @EnvironmentObject var cs: CalendarStore
      @Environment(\.dismiss) var dismiss
      let date: Date
      @State private var title = ""
      @State private var start: Date
      @State private var end: Date
      @State private var isAllDay = false
      
      // 新增：默认分类状态 (读取 AppStorage 默认值)
      @AppStorage("cal_default_category") private var selectedCategory: String = "工作"
      
      init(date: Date) {
          self.date = date
          _start = State(initialValue: date)
          _end = State(initialValue: date.addingTimeInterval(3600))
      }
      
      var body: some View {
          NavigationStack {
              Form {
                  Section {
                      TextField(I18n.text("event_placeholder"), text: $title)
                  }
                  
                  // 新增：行动类型选择器 (必须选择，否则无法调用 addEvent)
                  Section(header: Text("关联行动")) {
                      Picker("行动类型", selection: $selectedCategory) {
                          ForEach(allCategories.filter{$0 != "空"}, id: \.self) { cat in
                              HStack {
                                  Circle().fill(getColor(for: cat)).frame(width: 8, height: 8)
                                  Text(I18n.cat(cat))
                              }.tag(cat)
                          }
                      }
                  }
                  
                  Section {
                      Toggle(I18n.text("all_day"), isOn: $isAllDay)
                      DatePicker(I18n.text("start_time"), selection: $start, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                      DatePicker(I18n.text("end_time"), selection: $end, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                  }
              }
              .navigationTitle(I18n.text("add_event"))
              .ttNavigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .cancellationAction) { Button(I18n.text("cancel")) { dismiss() } }
                  ToolbarItem(placement: .confirmationAction) {
                      Button(I18n.text("save_record")) {
                          // 修复：传入缺少的 category 参数
                          cs.addEvent(
                              title: title,
                              start: start,
                              end: end,
                              isAllDay: isAllDay,
                              category: selectedCategory // 传入当前选择的分类
                          )
                          dismiss()
                      }.disabled(title.isEmpty)
                  }
              }
          }.presentationDetents([.medium])
      }
  }

// MARK: - 主界面 - v41 - 算法对账弹窗监听逻辑闭环

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var efficiencyStore: EfficiencyStore
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showPaywall = false
    @State private var algorithmDebugTarget: TimeStore.AlgorithmDebugData?

    var headerTitle: String {
        switch selectedTab {
        case 0: return I18n.t(.tab_home); case 1: return I18n.t(.tab_tasks)
        case 2: return I18n.t(.tab_calendar)
        case 4: return I18n.t(.tab_goals); case 5: return I18n.t(.tab_records)
        case 6: return I18n.t(.tab_pomo)
        case 9: return I18n.t(.tab_mental_math)
        default: return I18n.t(.tab_settings)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let themeColor = getThemeColor(efficiencyStore.yesterdayScoreCache)
            
            ZStack(alignment: .bottom) {
                MainBackgroundView(themeColor: themeColor).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    MainHeaderView(isLandscape: isLandscape, headerTitle: headerTitle)
                    
                    Group {
                        switch selectedTab {
                        case 0: HomeView()
                        case 1: TaskListView()
                        case 2: CalendarPageView()
                        case 4: GoalsView()
                        case 5: RecordsView()
                        case 9: MentalMathView()
                        case 6:
                            if settingsStore.isProEffective { PomodoroView() }
                            else { LockedFeaturePlaceholder(title: "高级番茄专注", desc: "试用期已结束", icon: "timer.square") { showPaywall = true } }
                        default: SettingsView()
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 80)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                
                CustomFloatingTabBar(selectedTab: $selectedTab) {
                    if selectedTab == 6 && !settingsStore.isProEffective { showPaywall = true }
                }
                .padding(.bottom, 15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .sheet(isPresented: $showPaywall) {
                TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                    PaywallView().environmentObject(settingsStore).environmentObject(purchaseManager)
                }
            }
            .sheet(item: $algorithmDebugTarget) { data in
                TTModalSheetContainer(minWidth: 900, minHeight: 720) {
                    TimeAlgorithmDebugView(data: data)
                }
            }
            // 响应模型层 Equatable 协议后的变更监听
            .onChange(of: timeStore.lastAlgorithmDebug) { _, newValue in
                if settingsStore.config.isTimeAlgorithmDebugEnabled {
                    self.algorithmDebugTarget = newValue
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if !settingsStore.isProEffective { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showPaywall = true } }
                settingsStore.load()
            }
        }
    }
    
    func getThemeColor(_ s: Double) -> Color {
        if s >= 100 { return Color(red: 0.6, green: 0.2, blue: 1.0) }
        if s >= 80 { return .yellow }
        if s >= 60 { return .green }
        return Color(white: 0.6)
    }
}

// MARK: - 付费功能锁定占位视图
struct LockedFeaturePlaceholder: View {
    let title: String
    let desc: String
    let icon: String
    var onUnlock: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color.orange.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: icon).font(.system(size: 50)).foregroundColor(.orange)
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Circle().fill(Color.black))
                    .foregroundColor(.white)
                    .offset(x: 35, y: 35)
            }
            
            VStack(spacing: 8) {
                Text(title).font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(desc).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
            }
            
            Button(action: onUnlock) {
                Text("升级 Pro 解锁")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.orange))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
}





// MARK: - 全局头部视图 - v3 - 物理压缩高度与边距修复

struct MainHeaderView: View {
    let isLandscape: Bool
    let headerTitle: String
    
    var body: some View {
        Group {
            if isLandscape {
                // 横屏极简模式 (iPhone / iPad / Mac)
                HStack(alignment: .center, spacing: 10) {
                    appNameText(fontSize: 22)
                    statusPill
                        .font(.caption2)
                        .scaleEffect(0.9)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
            } else {
                // 竖屏标准模式 (iPhone 优化)
                VStack(spacing: 4) { // 间距 10 -> 4
                    appNameText(fontSize: 30) // 字号 34 -> 30
                        .padding(.top, 5) // 减少顶部内边距
                    
                    statusPill
                        .font(.system(size: 11, weight: .medium))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                }
                // 【核心修改】：移除 padding(.top, 40)，由 MainView 的安全区自动处理
                .padding(.bottom, 10) // 底部间距 20 -> 10
            }
        }
    }
    
    private func appNameText(fontSize: CGFloat) -> some View {
        Text(I18n.t(.app_name))
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(LinearGradient(
                colors: [.white, Color(red: 0.7, green: 0.85, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .shadow(color: Color(red: 0.2, green: 0.5, blue: 1.0).opacity(0.35), radius: 10, x: 0, y: 5)
    }
    
    private var statusPill: some View {
        HStack(spacing: isLandscape ? 6 : 8) {
            HStack(spacing: 4) {
                Image(systemName: "hourglass.circle.fill")
                Text(I18n.t(.subtitle_timer))
            }
            .foregroundColor(.gray)
            
            Circle()
                .fill(.gray.opacity(0.5))
                .frame(width: 3, height: 3)
            
            Text(headerTitle)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }
}

// MARK: - 拆分出的子视图 (背景)
struct MainBackgroundView: View {
    let themeColor: Color
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(
                colors: [themeColor.opacity(0.4), themeColor.opacity(0.15), Color.black.opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            RadialGradient(
                colors: [themeColor.opacity(0.3), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            ).ignoresSafeArea()
        }
    }
}

// MARK: - 自定义浮动导航栏 - v14 - 适配原生 macOS 大屏判定

struct CustomFloatingTabBar: View {
    @Binding var selectedTab: Int
    var onTabChanged: () -> Void
    @AppStorage("settings_tab_config_v251216") var tabConfigJSON: String = ""
    @AppStorage("settings_maxVisibleTabs_v25") var maxVisibleTabs: Int = 4
    
    struct TabConfigItem: Codable, Identifiable, Equatable { var id: Int; var isVisible: Bool }
    struct TabMeta { let id: Int; let icon: String; let title: String; let activeColor: Color }
    
    static var allTabs:[Int: TabMeta] {[
            0: TabMeta(id: 0, icon: "house.fill", title: I18n.t(.tab_home), activeColor: .blue),
            1: TabMeta(id: 1, icon: "checkmark.circle.fill", title: I18n.t(.tab_tasks), activeColor: .pink),
            2: TabMeta(id: 2, icon: "calendar", title: I18n.t(.tab_calendar), activeColor: .purple),
            4: TabMeta(id: 4, icon: "medal.fill", title: I18n.t(.tab_goals), activeColor: .red),
            5: TabMeta(id: 5, icon: "list.bullet.rectangle.fill", title: I18n.t(.tab_records), activeColor: .orange),
            6: TabMeta(id: 6, icon: "timer", title: I18n.t(.tab_pomo), activeColor: .yellow),
            // 【166号修正】：更换为兼容性更好的 SF Symbol，确保状态栏和设置页均可见
            9: TabMeta(id: 9, icon: "number.square.fill", title: I18n.t(.tab_mental_math), activeColor: .green),
            7: TabMeta(id: 7, icon: "gearshape.fill", title: I18n.t(.tab_settings), activeColor: .gray)
        ]
    }
    
    static func loadConfig() -> [TabConfigItem] {
        let storedJSON = UserDefaults.standard.string(forKey: "settings_tab_config_v251216") ?? ""
        if let data = storedJSON.data(using: .utf8), let decoded = try? JSONDecoder().decode([TabConfigItem].self, from: data), !decoded.isEmpty {
            let activeIDs = [0, 1, 2, 4, 5, 6, 9]
            let existingIDs = Set(decoded.map { $0.id }); var final = decoded.filter { activeIDs.contains($0.id) }
            for i in activeIDs { if !existingIDs.contains(i) { final.append(TabConfigItem(id: i, isVisible: true)) } }
            return final
        }
        return [0, 1, 2, 4, 5, 6, 9].map { TabConfigItem(id: $0, isVisible: true) }
    }
    
    var isPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    var body: some View {
        let config = Self.loadConfig(); let vItems = config.filter { $0.isVisible }.map { $0.id } + [7]; let currentTabs = Self.allTabs
        ZStack {
            ZStack { Rectangle().fill(.ultraThinMaterial); Color.black.opacity(0.4); RoundedRectangle(cornerRadius: 35).strokeBorder(LinearGradient(colors:[.white.opacity(0.2), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }.clipShape(RoundedRectangle(cornerRadius: 35)).shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5).frame(height: 66)
            if isPadOrMac {
                HStack(spacing: 0) { ForEach(vItems, id: \.self) { id in if let meta = currentTabs[id] { TabItem(icon: meta.icon, title: meta.title, isSelected: selectedTab == meta.id, activeColor: meta.activeColor, index: meta.id) { selectedTab = meta.id; onTabChanged() }.frame(maxWidth: .infinity) } } }.padding(.horizontal, 16)
            } else {
                let chunkSize = max(3, maxVisibleTabs); let pages = vItems.chunked(into: chunkSize)
                let initPage: Int = { for (i, p) in pages.enumerated() { if p.contains(selectedTab) { return i } }; return 0 }()
                TabView(selection: .constant(initPage)) { ForEach(0..<pages.count, id: \.self) { i in let pItems = pages[i]; HStack(spacing: 0) { ForEach(pItems, id: \.self) { id in if let meta = currentTabs[id] { TabItem(icon: meta.icon, title: meta.title, isSelected: selectedTab == meta.id, activeColor: meta.activeColor, index: meta.id) { selectedTab = meta.id; onTabChanged() }.frame(maxWidth: .infinity) } }; if pItems.count < chunkSize { ForEach(0..<(chunkSize - pItems.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) } } }.padding(.horizontal, 16).tag(i) } }.ttPageTabViewStyle().frame(height: 66)
            }
        }.padding(.horizontal, 10).frame(maxWidth: isPadOrMac ? 750 : .infinity)
    }
}

// MARK: - 数组分块扩展 (修复编译器切片类型推断错误)
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        // 使用 stride 生成步进索引
        for index in stride(from: 0, to: count, by: size) {
            // 显式计算结束位置，避免闭包内类型推断失败
            let end = Swift.min(index + size, count)
            // 显式定义 Range<Int>
            let range = index..<end
            // 通过 Range 获取切片并转回 Array
            let chunk = Array(self[range])
            chunks.append(chunk)
        }
        return chunks
    }
}


  struct TabItem: View {
      let icon: String
      let title: String
      let isSelected: Bool
      var activeColor: Color = .blue
      let index: Int
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              VStack(spacing: 4) {
                  ZStack {
                      if isSelected { Circle().fill(activeColor.opacity(0.2)).frame(width: 50, height: 50).blur(radius: 5) }
                      Image(systemName: icon).font(.system(size: 26, weight: isSelected ? .bold : .medium)).foregroundColor(isSelected ? activeColor : .gray).scaleEffect(isSelected ? 1.1 : 1.0)
                  }.frame(height: 34)
                  if isSelected { Circle().fill(activeColor).frame(width: 5, height: 5).offset(y: 4) }
                  else { Circle().fill(.clear).frame(width: 5, height: 5).offset(y: 4) }
              }.frame(maxWidth: .infinity).contentShape(Rectangle())
          }.buttonStyle(.plain).animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
      }
  }

// MARK: - 首页 - v15 - 物理上提首页分类按钮与适配 macOS 大屏判定

struct HomeView: View {
    @EnvironmentObject var timeStore: TimeStore
    @EnvironmentObject var efficiencyStore: EfficiencyStore
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showingEdit = false
    @State private var showPaywall = false

    // 【核心修改】：封装设备判定，适配原生 macOS
    var isPad: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            // 【核心修改】：使用外部计算属性替换原有的局部变量
            
            let yScore = efficiencyStore.yesterdayScoreCache
            let tScore = efficiencyStore.todayScoreCache
            
            ZStack {
                if let current = timeStore.currentRecord {
                    getColor(for: current.category).opacity(0.15).ignoresSafeArea().blur(radius: 60)
                }
                
                if isLandscape {
                    if isPad {
                        VStack(spacing: 30) {
                            HStack {
                                MedalBadgeView(score: yScore, label: NSLocalizedString("yesterday", comment: ""), scale: 1.3)
                                Spacer()
                                if !settingsStore.config.isPro {
                                    TrialCountdownPill(days: settingsStore.remainingTrialDays)
                                        .onTapGesture { showPaywall = true }
                                }
                                Spacer()
                                if tScore >= 60 {
                                    MedalBadgeView(score: tScore, label: NSLocalizedString("today", comment: ""), scale: 1.3)
                                } else { Color.clear.frame(width: 60, height: 60) }
                            }
                            .padding(.horizontal, 80).padding(.top, 20)
                            
                            HStack(alignment: .center, spacing: 80) {
                                BoxContainer {
                                    ActiveTimerRing(currentRecord: timeStore.currentRecord, onTap: { showingEdit = true })
                                        .scaleEffect(1.3).frame(width: 300 * 1.3, height: 300 * 1.3)
                                }.frame(maxWidth: .infinity)
                                BoxContainer {
                                    GlassCategoryGrid(isCompact: true)
                                        .scaleEffect(1.3).frame(width: 260 * 1.3, height: 260 * 1.3)
                                }.frame(maxWidth: .infinity)
                            }.padding(.horizontal, 60)
                            Spacer()
                        }
                    } else {
                        HStack(alignment: .center, spacing: 50) {
                            BoxContainer {
                                ActiveTimerRing(currentRecord: timeStore.currentRecord, onTap: { showingEdit = true })
                                    .scaleEffect(0.7).frame(width: 300 * 0.7, height: 300 * 0.7)
                                    .overlay(alignment: .topLeading) {
                                        MedalBadgeView(score: yScore, label: NSLocalizedString("yesterday", comment: ""), scale: 0.8)
                                            .offset(x: -30, y: -10)
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        if tScore >= 60 {
                                            MedalBadgeView(score: tScore, label: NSLocalizedString("today", comment: ""), scale: 0.8)
                                                .offset(x: 30, y: -10)
                                        }
                                    }
                            }.frame(maxWidth: .infinity)
                            BoxContainer {
                                GlassCategoryGrid(isCompact: true).scaleEffect(1.25).frame(width: 260, height: 260)
                            }.frame(maxWidth: .infinity)
                        }.padding(.horizontal, 30).padding(.top, 30)
                    }
                } else {
                    VStack(spacing: 0) {
                        HStack(alignment: .top) {
                            VStack(spacing: 4) {
                                LargeMedalView(score: yScore).scaleEffect(1.1).frame(width: 60, height: 60)
                                Text(NSLocalizedString("yesterday", comment: "昨日")).font(.caption2).foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            if !settingsStore.config.isPro {
                                TrialCountdownPill(days: settingsStore.remainingTrialDays)
                                    .onTapGesture { showPaywall = true }.padding(.top, 10)
                            }
                            Spacer()
                            if tScore >= 60 {
                                VStack(spacing: 4) {
                                    LargeMedalView(score: tScore).scaleEffect(1.1).frame(width: 60, height: 60)
                                    Text(NSLocalizedString("today", comment: "今日")).font(.caption2).foregroundColor(.white.opacity(0.5))
                                }.transition(.scale.combined(with: .opacity))
                            } else { Color.clear.frame(width: 60, height: 60) }
                        }.padding(.horizontal, 30).padding(.top, 20)
                        
                        Spacer()
                        
                        ActiveTimerRing(currentRecord: timeStore.currentRecord, onTap: { showingEdit = true })
                            .scaleEffect(isPad ? 1.3 : 1.0)
                            .offset(y: -30)
                        
                        Spacer()
                        
                        // 【163号修改】：底部 Padding 物理加大至 70 像素，避让导航栏
                        GlassCategoryGrid(isCompact: false)
                            .scaleEffect(isPad ? 1.3 : 1.0)
                            .padding(.bottom, 70)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            efficiencyStore.refreshCache(with: timeStore.records, forceYesterday: false)
        }
        .sheet(isPresented: $showingEdit) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                EditCurrentRecordView()
            }
        }
        .sheet(isPresented: $showPaywall) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                PaywallView().environmentObject(settingsStore).environmentObject(purchaseManager)
            }
        }
    }
}


// 【新增】倒计时胶囊组件
struct TrialCountdownPill: View {
    let days: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Pro 试用")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            if days > 0 {
                Text("剩 \(days) 天")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
            } else {
                Text("已过期")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            Capsule()
                .stroke(days > 0 ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
        // 增加点击提示光晕
        .shadow(color: (days > 0 ? Color.orange : Color.red).opacity(0.2), radius: 5)
    }
}


// MARK: - 辅助：番茄状态显示胶囊 - V2 - 适配新枚举
struct PomoStatusBadge: View {
    @ObservedObject var manager: PomodoroManager
    
    var statusText: String {
        // 计算剩余分钟数
        let mins = manager.remainingSeconds / 60
        // 可选：如果想要秒数，可以加 % 60
        
        switch manager.state {
        case .focus:
            return "专注中 (\(mins)m)"
        case .paused:
            return "已暂停 (\(mins)m)"
        case .breakTime:
            return "休息中 (\(mins)m)"
        case .idle:
            return ""
        }
    }
    
    var statusColor: Color {
        switch manager.state {
        case .focus:
            return .red        // 专注红
        case .paused:
            return .yellow     // 暂停黄
        case .breakTime:
            return .green      // 休息绿
        default:
            return .clear
        }
    }
    
    var body: some View {
        // 只有非空闲状态才显示
        if manager.state != .idle {
            HStack(spacing: 6) {
                Image(systemName: manager.state == .paused ? "pause.circle.fill" : "timer")
                    .font(.caption2)
                Text(statusText)
                    .font(.caption)
                    .bold()
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.6)))
            .overlay(Capsule().stroke(statusColor, lineWidth: 1))
            .foregroundColor(statusColor)
        }
    }
}



// MARK: - 带标签的勋章组合 - v2 - 适配试用期解锁逻辑
//
// MedalBadgeView
// (修改：将付费判定由 .isPro 改为 .isProEffective，确保试用期内勋章不被锁定)

struct MedalBadgeView: View {
    let score: Double
    let label: String
    let scale: CGFloat
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                LargeMedalView(score: score)
                    .scaleEffect(scale)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    // 【核心修改】使用 isProEffective 判定，试用期显示彩色
                    .grayscale(settingsStore.isProEffective ? 0 : 1.0)
                    .opacity(settingsStore.isProEffective ? 1.0 : 0.8)
                
                // 【核心修改】试用期内隐藏锁头
                if !settingsStore.isProEffective {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10 * scale, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.orange))
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .offset(x: 2, y: 2)
                }
            }
            .frame(width: 54 * scale, height: 54 * scale)
            
            Text(label)
                .font(.system(size: 14 * scale, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.5), radius: 2)
        }
    }
}

  struct BoxContainer<Content: View>: View {
      let content: Content; init(@ViewBuilder content: () -> Content) { self.content = content() }; var body: some View { ZStack { content } }
  }

// MARK: - 活跃计时器圆环 - v11 - 撤销 drawingGroup 以修复方形背景视觉 Bug
struct ActiveTimerRing: View {
    let currentRecord: TimeRecord?
    let onTap: () -> Void
    @AppStorage("settings_timerStyle_v25") var timerStyle = 0
    
    @State private var isAnimating = false
    @State private var youthIndex = 0
    @State private var timerCount = 0
    @State private var userPhoto: UIImage? = nil
    
    // 保持：本地高频时间源，确保文字走秒极其丝滑且不干扰父视图
    @State private var localNow = Date()
    @State private var cometAngle: Double = 0.0
    
    // 保持：30FPS 刷新频率 (约 33ms)
    let animationTimer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    
    var category: String { currentRecord?.category ?? "无" }
    var startTime: Date { currentRecord?.startTime ?? Date() }
    var isRunning: Bool { currentRecord != nil }
    var baseColor: Color { isRunning ? getColor(for: category) : Color.gray }
    
    let size: CGFloat = 300
    let ringSize: CGFloat = 260
    let lineWidth: CGFloat = 24
    var radius: CGFloat { ringSize / 2 }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 逻辑修正：移除外层的 .drawingGroup()，回归原生混合模式渲染
                // 这将解决渲染缓冲区导致的方形背景残留问题
                ZStack {
                    if isRunning {
                        backgroundContent
                    }
                    
                    if ![1, 2, 5, 7, 8, 9, 10, 11].contains(timerStyle) {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                            .frame(width: ringSize, height: ringSize)
                    }
                    
                    if isRunning && timerStyle == 0 {
                        renderCometForeground()
                    }
                }
                
                // 文本内容层
                renderTextContent()
            }
        }
        .buttonStyle(.plain)
        .onReceive(animationTimer) { date in
            if isRunning {
                localNow = date
                
                timerCount += 1
                if timerStyle == 10 && timerCount % 30 == 0 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        youthIndex = (youthIndex + 1) % 6
                    }
                }
                
                if timerStyle == 0 {
                    let cycle = 10.0
                    let progress = date.timeIntervalSince1970.remainder(dividingBy: cycle) / cycle
                    let adjustedProgress = progress >= 0 ? progress : (1 + progress)
                    cometAngle = adjustedProgress * 360
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserPhotoUpdated"))) { _ in
            if timerStyle == 9 { self.userPhoto = UserPhotoManager.shared.loadPhoto() }
        }
        .onAppear {
            if timerStyle == 9 && userPhoto == nil { userPhoto = UserPhotoManager.shared.loadPhoto() }
            if isRunning { isAnimating = true }
        }
        .onChange(of: isRunning) { _, newValue in
            if newValue { isAnimating = true }
        }
    }
    
    @ViewBuilder
    var backgroundContent: some View {
        switch timerStyle {
        case 1: renderBreathingBackground()
        case 2: renderUltramanBackground()
        case 3: renderRadarBackground()
        case 4: renderCyberGlitchBackground()
        case 5: renderForbiddenCityBackground()
        case 6: renderTacticalHUDBackground()
        case 7: renderPixelCoreBackground()
        case 8: renderShanghaiLightBackground()
        case 9: renderPhotoBackground()
        case 10: YouthGraphicView(index: youthIndex, size: size, ringSize: ringSize, isAnimating: isAnimating)
        case 11: AtomicGraphicView(baseColor: baseColor, ringSize: ringSize, isAnimating: isAnimating)
        default: renderCometBackground()
        }
    }
    
    @ViewBuilder func renderCometBackground() -> some View {
        Circle().fill(baseColor).opacity(0.15).frame(width: size, height: size).blur(radius: 20)
    }
    
    @ViewBuilder func renderCometForeground() -> some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [baseColor.opacity(0), baseColor]), center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
            
            Circle()
                .fill(baseColor.opacity(0.9))
                .frame(width: lineWidth, height: lineWidth)
                .blur(radius: 3)
                .shadow(color: baseColor, radius: 8, x: 0, y: 0)
                .offset(x: 0, y: -radius)
                .rotationEffect(.degrees(270))
        }
        .rotationEffect(.degrees(cometAngle))
    }
    
    @ViewBuilder func renderBreathingBackground() -> some View {
        ZStack {
            Circle().fill(baseColor.opacity(0.05)).frame(width: ringSize, height: ringSize)
            Circle().strokeBorder(AngularGradient(gradient: Gradient(colors: [baseColor.opacity(0), baseColor, baseColor.opacity(0)]), center: .center), lineWidth: 4).frame(width: ringSize, height: ringSize).scaleEffect(isAnimating ? 1.0 : 0.33).opacity(isAnimating ? 0.8 : 0.0).blur(radius: isAnimating ? 0 : 5)
            Circle().stroke(baseColor.opacity(0.3), lineWidth: 1).frame(width: ringSize * 0.8, height: ringSize * 0.8).scaleEffect(isAnimating ? 1.0 : 0.2).opacity(isAnimating ? 0.5 : 0.0).animation(.easeInOut(duration: 4).delay(0.2).repeatForever(autoreverses: true), value: isAnimating)
            Circle().fill(baseColor.opacity(0.2)).frame(width: 80, height: 80).scaleEffect(isAnimating ? 1.2 : 0.8).blur(radius: 10)
        }.onAppear { withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
    
    @ViewBuilder func renderUltramanBackground() -> some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.4), Color(white: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: size, height: size).shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            Circle().fill(Color.black.opacity(0.8)).frame(width: size - 30, height: size - 30)
            Circle().fill(RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.9), baseColor, baseColor.opacity(0.6)]), center: .center, startRadius: 0, endRadius: 130)).frame(width: size - 40, height: size - 40)
            Circle().fill(baseColor).blur(radius: 20).scaleEffect(isAnimating ? 1.05 : 0.85).opacity(isAnimating ? 0.8 : 0.3)
            Circle().trim(from: 0, to: 0.8).stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 10])).frame(width: size - 60, height: size - 60).rotationEffect(.degrees(isAnimating ? 360 : 0))
            Circle().fill(LinearGradient(colors: [.white.opacity(0.9), .clear], startPoint: .top, endPoint: .bottom)).frame(width: 80, height: 40).rotationEffect(.degrees(-45)).offset(x: -60, y: -60).blur(radius: 2)
        }.onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
    
    @ViewBuilder func renderRadarBackground() -> some View {
        ZStack {
            ForEach(0..<4) { i in Circle().stroke(baseColor, lineWidth: 1.5).frame(width: ringSize, height: ringSize).scaleEffect(isAnimating ? 4.0 : 0.0).opacity(isAnimating ? 0.0 : 0.8).animation(.easeOut(duration: 3).repeatForever(autoreverses: false).delay(Double(i) * 0.7), value: isAnimating) }
            ForEach(0..<3) { i in Circle().stroke(baseColor.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [10, 20])).frame(width: ringSize, height: ringSize).scaleEffect(isAnimating ? 1.0 : 3.5).opacity(isAnimating ? 0.5 : 0.0).rotationEffect(.degrees(Double(i) * 45)).animation(.linear(duration: 4).repeatForever(autoreverses: false).delay(Double(i) * 1.0), value: isAnimating) }
            Circle().trim(from: 0, to: 0.25).stroke(AngularGradient(colors: [.clear, baseColor], center: .center), style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)).frame(width: ringSize, height: ringSize).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            Circle().fill(baseColor.opacity(0.1)).frame(width: ringSize, height: ringSize)
        }.onAppear { isAnimating = true }
    }
    
    @ViewBuilder func renderCyberGlitchBackground() -> some View {
        ZStack {
            Circle().trim(from: 0.2, to: 0.9).stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .butt, dash: [10, 20])).frame(width: ringSize + 10, height: ringSize + 10).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating).offset(x: isAnimating ? 2 : -2, y: 0)
            Circle().trim(from: 0, to: 0.7).stroke(Color.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .butt, dash: [15, 25])).frame(width: ringSize - 10, height: ringSize - 10).rotationEffect(.degrees(isAnimating ? -360 : 0)).animation(.linear(duration: 4).repeatForever(autoreverses: false), value: isAnimating).offset(x: isAnimating ? -2 : 2, y: 0)
            Circle().stroke(baseColor, lineWidth: 2).frame(width: ringSize, height: ringSize).overlay(Circle().fill(baseColor.opacity(0.1)))
        }.onAppear { withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
    
    @ViewBuilder func renderForbiddenCityBackground() -> some View {
        let palaceRed = Color(red: 0.6, green: 0.1, blue: 0.1); let palaceGold = Color(red: 0.8, green: 0.65, blue: 0.2)
        ZStack {
            Circle().fill(palaceRed).frame(width: size, height: size).shadow(color: .black.opacity(0.5), radius: 10)
            Circle().strokeBorder(palaceGold, lineWidth: 4).frame(width: size - 10, height: size - 10)
            Circle().stroke(palaceGold.opacity(0.6), style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [20, 40])).frame(width: ringSize, height: ringSize).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
            Circle().stroke(palaceGold, lineWidth: 2).frame(width: ringSize - 30, height: ringSize - 30)
            ForEach(0..<4) { i in Circle().fill(palaceGold).frame(width: 8, height: 8).offset(y: -ringSize/2).rotationEffect(.degrees(Double(i) * 90)) }
        }.onAppear { isAnimating = true }
    }
    
    @ViewBuilder func renderTacticalHUDBackground() -> some View {
        let tacticalColor = Color.green
        ZStack {
            Circle().trim(from: 0, to: 0.6).stroke(tacticalColor, style: StrokeStyle(lineWidth: 2, lineCap: .butt)).frame(width: ringSize + 15, height: ringSize + 15).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isAnimating)
            Circle().trim(from: 0, to: 0.8).stroke(tacticalColor.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .butt, dash: [5, 10])).frame(width: ringSize - 20, height: ringSize - 20).rotationEffect(.degrees(isAnimating ? -360 : 0)).animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
            ForEach(0..<3) { i in Image(systemName: "arrowtriangle.down.fill").font(.caption2).foregroundColor(tacticalColor).offset(y: -(ringSize/2 + 20)).rotationEffect(.degrees(Double(i) * 120 + (isAnimating ? 360 : 0))) }.animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
            Circle().fill(tacticalColor.opacity(0.1)).frame(width: ringSize, height: ringSize)
        }.onAppear { isAnimating = true }
    }
    
    @ViewBuilder func renderPixelCoreBackground() -> some View {
        ZStack {
            Circle().stroke(baseColor, style: StrokeStyle(lineWidth: 18, lineCap: .butt, dash: [12, 8])).frame(width: ringSize, height: ringSize).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
            Circle().stroke(baseColor.opacity(0.5), style: StrokeStyle(lineWidth: 8, lineCap: .butt, dash: [6, 6])).frame(width: ringSize - 40, height: ringSize - 40).rotationEffect(.degrees(isAnimating ? -360 : 0)).animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
            Circle().fill(baseColor.opacity(0.15)).frame(width: size, height: size)
        }.onAppear { isAnimating = true }
    }
    
    @ViewBuilder func renderShanghaiLightBackground() -> some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(red: 0.1, green: 0.0, blue: 0.3), Color.black], center: .center, startRadius: 10, endRadius: 150)).frame(width: size, height: size)
            ForEach(0..<12) { i in Capsule().fill(AngularGradient(gradient: Gradient(colors: [.purple, .cyan, .clear]), center: .bottom)).frame(width: 8, height: radius * 1.1).blur(radius: 6).offset(y: -radius/2).rotationEffect(.degrees(Double(i) * 30 + (isAnimating ? 360 : 0))).opacity(0.5) }.animation(.linear(duration: 24).repeatForever(autoreverses: false), value: isAnimating)
            ShanghaiSkylineShape().stroke(LinearGradient(colors: [.cyan, .purple, .blue], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)).frame(width: 180, height: 80).offset(y: 30).shadow(color: .cyan.opacity(0.8), radius: 5)
            Circle().strokeBorder(LinearGradient(colors: [.purple.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5).frame(width: ringSize, height: ringSize)
        }.onAppear { isAnimating = true }
    }
    
    @ViewBuilder func renderPhotoBackground() -> some View {
        ZStack {
            Circle().fill(Color(white: 0.1)).frame(width: size, height: size)
            if let img = userPhoto {
                Image(uiImage: img).resizable().aspectRatio(contentMode: .fit).frame(width: ringSize, height: ringSize).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)).opacity(isAnimating ? 1.0 : 0.6).scaleEffect(isAnimating ? 1.02 : 0.98).animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating).overlay(Circle().fill(Color.black.opacity(0.3)))
            } else {
                VStack(spacing: 4) { Image(systemName: "photo.badge.plus").font(.largeTitle).foregroundColor(.gray); Text(NSLocalizedString("set_photo", comment: "")).font(.caption2).foregroundColor(.gray) }
            }
            Circle().strokeBorder(baseColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [2, 10])).frame(width: size, height: size).rotationEffect(.degrees(isAnimating ? 360 : 0)).animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
        }.onAppear { isAnimating = true; if userPhoto == nil { userPhoto = UserPhotoManager.shared.loadPhoto() } }
    }
    
    struct ShanghaiSkylineShape: Shape { func path(in rect: CGRect) -> Path { var path = Path(); let w = rect.width; let h = rect.height; path.move(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: w*0.1, y: h*0.6)); path.addLine(to: CGPoint(x: w*0.15, y: h*0.5)); path.addLine(to: CGPoint(x: w*0.2, y: h*0.6)); path.addLine(to: CGPoint(x: w*0.3, y: h*0.6)); path.addLine(to: CGPoint(x: w*0.32, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.38, y: h*0.3)); path.addLine(to: CGPoint(x: w*0.4, y: h*0.6)); path.addLine(to: CGPoint(x: w*0.5, y: h*0.6)); path.addQuadCurve(to: CGPoint(x: w*0.6, y: h*0.6), control: CGPoint(x: w*0.55, y: 0)); path.addLine(to: CGPoint(x: w*0.7, y: h*0.6)); path.addLine(to: CGPoint(x: w*0.75, y: h*0.4)); path.addArc(center: CGPoint(x: w*0.75, y: h*0.35), radius: 5, startAngle: .degrees(90), endAngle: .degrees(-270), clockwise: false); path.addLine(to: CGPoint(x: w*0.75, y: h*0.2)); path.addLine(to: CGPoint(x: w*0.75, y: h*0.6)); path.addLine(to: CGPoint(x: w, y: h)); return path } }

    @ViewBuilder
    func renderTextContent() -> some View {
        VStack(spacing: 4) {
            if isRunning {
                let useWhiteText = [2, 5, 8, 9, 11].contains(timerStyle)
                let useBlackText = (timerStyle == 10)
                let textColor = useWhiteText ? .white.opacity(0.9) : (useBlackText ? .black.opacity(0.8) : baseColor)
                
                Text(I18n.cat(category))
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .padding(.bottom, 4)
                    .shadow(color: .black.opacity(useWhiteText ? 0.5 : 0), radius: 2)
                
                Text(formatDuration(max(0, localNow.timeIntervalSince(startTime)), true))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(useBlackText ? .black : .white)
                    .shadow(color: useBlackText ? .white.opacity(0.8) : (timerStyle == 9 ? .black.opacity(0.6) : baseColor.opacity(0.5)), radius: 8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(NSLocalizedString("tap_to_edit", comment: ""))
                    .font(.caption)
                    .foregroundColor(useBlackText ? .black.opacity(0.5) : .white.opacity(0.4))
                    .padding(.top, 8)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.4))
                    .padding(.bottom, 10)
                
                Text(NSLocalizedString("waiting_start", comment: ""))
                    .font(.title3).bold()
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - 独立出来的复杂组件 (解决编译超时)

struct YouthGraphicView: View {
    let index: Int
    let size: CGFloat
    let ringSize: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            Circle().fill(Color(white: 0.95)).frame(width: size, height: size).shadow(color: .black.opacity(0.3), radius: 5)
            Circle().strokeBorder(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 10])).frame(width: size - 15, height: size - 15)
            
            Group {
                switch index {
                case 0: YouthShape0()
                case 1: YouthShape1()
                case 2: YouthShape2()
                case 3: YouthShape3()
                case 4: YouthShape4()
                case 5: YouthShape5()
                default: EmptyView()
                }
            }.frame(width: 120, height: 120) // 统一容器大小
            
            Circle().trim(from: 0, to: 0.6).stroke(Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .onAppear { withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { } }
        }
    }
}

// 进一步拆分青春版内部图形，降低单一视图复杂度
struct YouthShape0: View { var body: some View { ZStack { Circle().stroke(Color.black, lineWidth: 3).frame(width: 80, height: 70); Path { p in p.move(to: CGPoint(x: 20, y: 30)); p.addLine(to: CGPoint(x: 10, y: 5)); p.addLine(to: CGPoint(x: 40, y: 20)) }.stroke(Color.black, lineWidth: 3); Path { p in p.move(to: CGPoint(x: 100, y: 30)); p.addLine(to: CGPoint(x: 110, y: 5)); p.addLine(to: CGPoint(x: 80, y: 20)) }.stroke(Color.black, lineWidth: 3); Rectangle().stroke(Color.black, lineWidth: 3).frame(width: 90, height: 20).offset(y: -35) } } }
struct YouthShape1: View { var body: some View { VStack(spacing: -5) { Circle().stroke(Color.green, lineWidth: 4).frame(width: 40, height: 40); Circle().stroke(Color.green, lineWidth: 4).frame(width: 60, height: 60) } } }
struct YouthShape2: View { var body: some View { ZStack { Circle().stroke(Color.red, lineWidth: 3).frame(width: 80, height: 80); Circle().stroke(Color.yellow, lineWidth: 4).frame(width: 80, height: 20).offset(y: -25); Path { p in p.move(to: CGPoint(x: 60, y: 100)); p.addQuadCurve(to: CGPoint(x: 60, y: 20), control: CGPoint(x: 0, y: 60)) }.stroke(Color.yellow, lineWidth: 4).frame(width: 120, height: 120) } } }
struct YouthShape3: View { var body: some View { ZStack { Circle().stroke(Color.blue, lineWidth: 3).frame(width: 80, height: 70); Path { p in p.move(to: CGPoint(x: 30, y: 30)); p.addCurve(to: CGPoint(x: 10, y: 50), control1: CGPoint(x: 10, y: 10), control2: CGPoint(x: 0, y: 40)) }.stroke(Color.blue, lineWidth: 4); Path { p in p.move(to: CGPoint(x: 90, y: 30)); p.addCurve(to: CGPoint(x: 110, y: 50), control1: CGPoint(x: 110, y: 10), control2: CGPoint(x: 120, y: 40)) }.stroke(Color.blue, lineWidth: 4); Circle().trim(from: 0, to: 0.5).stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [1, 10])).frame(width: 80, height: 80).offset(y: -30) } } }
struct YouthShape4: View { var body: some View { ZStack { RoundedRectangle(cornerRadius: 30).stroke(Color.brown, lineWidth: 4).frame(width: 90, height: 80); Circle().fill(Color.brown).frame(width: 25, height: 25).offset(x: -45, y: -40); Circle().fill(Color.brown).frame(width: 25, height: 25).offset(x: 45, y: -40) } } }
struct YouthShape5: View { var body: some View { ZStack { Circle().stroke(Color.pink, lineWidth: 3).frame(width: 70, height: 70); Circle().fill(Color.black).frame(width: 25, height: 25).offset(x: -35, y: -30); Circle().fill(Color.black).frame(width: 25, height: 25).offset(x: 35, y: -30); Circle().stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 4).frame(width: 100, height: 100) } } }

struct AtomicGraphicView: View {
    let baseColor: Color
    let ringSize: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [baseColor, .black], center: .center, startRadius: 2, endRadius: 20)).frame(width: 30, height: 30).shadow(color: baseColor, radius: 5)
            Group {
                AtomicOrbit(baseColor: baseColor, rotation: 0, isAnimating: isAnimating, duration: 3)
                AtomicOrbit(baseColor: baseColor, rotation: 60, isAnimating: isAnimating, duration: 4)
                AtomicOrbit(baseColor: baseColor, rotation: 120, isAnimating: isAnimating, duration: 5)
            }
            Circle().strokeBorder(baseColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5])).frame(width: ringSize, height: ringSize)
        }
        .onAppear { withAnimation { } }
    }
}

struct AtomicOrbit: View {
    let baseColor: Color
    let rotation: Double
    let isAnimating: Bool
    let duration: Double
    
    var body: some View {
        ZStack {
            Ellipse().stroke(baseColor.opacity(0.4), lineWidth: 1.5).frame(width: 80, height: 220)
            Circle().fill(baseColor).frame(width: 8, height: 8).offset(y: -110)
        }
        .rotationEffect(.degrees(rotation))
        .rotation3DEffect(.degrees(isAnimating ? 360 : 0), axis: (x: 1.0, y: 1.0, z: 0.0))
        .onAppear { withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) { } }
    }
}

  struct GlassCategoryGrid: View {
      var isCompact: Bool = false
      var body: some View {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
              HomeGlassBtn(cat: "刚需", icon: "bus.fill", isCompact: isCompact)
              HomeGlassBtn(cat: "工作", icon: "briefcase.fill", isCompact: isCompact)
              HomeGlassBtn(cat: "监控", icon: "eye.fill", isCompact: isCompact)
              HomeGlassBtn(cat: "生活", icon: "house.fill", isCompact: isCompact)
          }
      }
  }

  struct HomeGlassBtn: View {
      let cat: String
      let icon: String
      var isCompact: Bool = false
      @EnvironmentObject var ts: TimeStore
      var isSelected: Bool { ts.currentRecord?.category == cat }
      var baseColor: Color { getColor(for: cat) }
      
      var body: some View {
          Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ts.start(category: cat) } }) {
              HStack(spacing: isCompact ? 0 : 12) {
                  ZStack {
                      Circle().fill(isSelected ? AnyShapeStyle(baseColor) : AnyShapeStyle(baseColor.opacity(0.2))).frame(width: 42, height: 42)
                      Image(systemName: icon).font(.headline).foregroundColor(isSelected ? .white : baseColor)
                  }
                  if !isCompact {
                      VStack(alignment: .leading, spacing: 2) {
                          Text(I18n.cat(cat)).font(.headline).fontWeight(.bold).foregroundColor(isSelected ? .white : .white.opacity(0.9))
                          Text(formatDuration(ts.getTodayDuration(category: cat))).font(.caption2).monospacedDigit().fontWeight(.medium).foregroundColor(isSelected ? .white.opacity(0.8) : .gray).lineLimit(1).minimumScaleFactor(0.6)
                      }
                      Spacer()
                      if isSelected { Circle().fill(.white).frame(width: 6, height: 6).shadow(color: .white, radius: 4) }
                  }
              }
              .padding(16).frame(maxWidth: .infinity)
              .background { ZStack { RoundedRectangle(cornerRadius: 20).fill(isSelected ? baseColor.opacity(0.6) : Color(white: 0.15).opacity(0.6)); RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [.white.opacity(isSelected ? 0.6 : 0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) } }
              .shadow(color: isSelected ? baseColor.opacity(0.4) : .clear, radius: 10, x: 0, y: 5).scaleEffect(isSelected ? 1.02 : 1.0)
          }.buttonStyle(.plain)
      }
  }

// MARK: - 目标视图 - v6 - 退出自动备份与适配 macOS 大屏判定

struct GoalsView: View {
    @EnvironmentObject var es: EfficiencyStore
    @EnvironmentObject var ts: TimeStore
    @State private var viewScope = 0
    @State private var viewingWeekStart = Date()
    @State private var viewingMonthStart = Date()
    @State private var tempHours: Int = 8
    @State private var tempEff: Int = 6
    @State private var isLocked: Bool = false
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State private var refresher = Date()

    // 【核心修改】：封装设备判定，适配原生 macOS
    var isPad: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            // 【核心修改】：使用外部计算属性
            let isPhoneLandscape = isLandscape && !isPad
            
            let scaleFactor: CGFloat = isPhoneLandscape ? 0.7 : 1.0
            
            VStack(spacing: isPhoneLandscape ? 0 : 15) {
                if !isPhoneLandscape {
                    GoalDashboardView(hours: $tempHours, efficiency: $tempEff, isReadOnly: isLocked)
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .onChange(of: tempHours) { _,_ in saveGoals() }
                        .onChange(of: tempEff) { _,_ in saveGoals() }
                    
                    GlassScopeSwitcher(selection: $viewScope)
                        .padding(.horizontal)
                } else {
                    Color.clear.frame(height: 5)
                }
                
                ZStack(alignment: .topLeading) {
                    if viewScope == 0 {
                        WeeklyEfficiencyCard(
                            viewingWeekStart: $viewingWeekStart,
                            ts: ts,
                            es: es,
                            showNavigation: !isPhoneLandscape
                        )
                        .transition(AnyTransition.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                    } else {
                        MonthlyEfficiencyCard(
                            monthStart: $viewingMonthStart,
                            ts: ts,
                            es: es,
                            showNavigation: !isPhoneLandscape
                        )
                        .transition(AnyTransition.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .scaleEffect(scaleFactor, anchor: .topLeading)
                .frame(width: isPhoneLandscape ? geo.size.width / scaleFactor : geo.size.width)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .ignoresSafeArea(edges: .bottom)
            .id(refresher)
            .onAppear { initDate() }
            .onChange(of: viewingWeekStart) { _,_ in refreshData() }
            .onReceive(timer) { _ in if ts.currentRecord != nil { refresher = Date() } }
            // 【核心新增】退出页面时触发备份
            .onDisappear {
                es.backup()
            }
        }
    }

    func initDate() {
        var c = Calendar.current
        c.firstWeekday = 2
        let now = Date()
        if let w = c.date(from: c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) { viewingWeekStart = w }
        if let m = c.date(from: c.dateComponents([.year, .month], from: now)) { viewingMonthStart = m }
        refreshData()
    }

    func refreshData() {
        let targets = es.getTargets(for: viewingWeekStart)
        tempHours = targets.hours
        tempEff = targets.efficiency
        isLocked = es.isPastWeek(viewingWeekStart)
    }

    func saveGoals() { if !isLocked { es.updateTargets(for: viewingWeekStart, hours: tempHours, efficiency: tempEff) } }
}

// MARK: - 目标仪表盘视图 - v4 - 移除数值单位后缀
//
// GoalDashboardView
// (修改：将 DashboardCard 的 suffix 参数设置为空，移除 h 和 Lv 后缀)

struct GoalDashboardView: View {
    @Binding var hours: Int
    @Binding var efficiency: Int
    var isReadOnly: Bool = false
    var totalScore: Int { hours * efficiency }
    
    var body: some View {
        HStack(spacing: 10) {
            // 1. 时长卡片 - 移除 "h"
            DashboardCard(
                icon: "clock.badge.exclamationmark.fill",
                iconColor: .cyan,
                title: I18n.t(.goal_duration),
                suffix: "", // 已移除 "h"
                value: $hours,
                range: 1...24,
                isDisabled: isReadOnly
            )
            
            // 2. 效率卡片 - 移除 "Lv"
            DashboardCard(
                icon: "gauge.with.dots.needle.100percent",
                iconColor: .green,
                title: I18n.t(.goal_efficiency),
                suffix: "", // 已移除 "Lv"
                value: $efficiency,
                range: 1...10,
                isDisabled: isReadOnly
            )
            
            // 3. 总分卡片
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                
                HStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.caption2)
                        Text(I18n.t(.goal_total_score))
                            .font(.caption2)
                            .bold()
                    }
                    .foregroundColor(.purple.opacity(0.9))
                    .layoutPriority(1)
                    
                    Spacer()
                    
                    Text("\(totalScore)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .orange.opacity(0.5), radius: 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 46)
        }
        .opacity(isReadOnly ? 0.8 : 1.0)
    }
}

// MARK: - 仪表盘单元卡片 - v2 - 适配空单位后缀
//
// DashboardCard
// (逻辑：作为目标页顶部的基础交互单元。当 suffix 为空时，仅显示核心数值)

struct DashboardCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let suffix: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var isDisabled: Bool = false
    
    var body: some View {
        Menu {
            if !isDisabled {
                Picker("选择数值", selection: $value) {
                    ForEach(range, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isDisabled ? Color.gray.opacity(0.1) : Color.white.opacity(0.1), lineWidth: 1)
                
                HStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: isDisabled ? "lock.fill" : icon)
                            .font(.caption2)
                        Text(title)
                            .font(.caption2)
                            .bold()
                    }
                    .foregroundColor(isDisabled ? .gray : iconColor.opacity(0.8))
                    .layoutPriority(1)
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(value)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(isDisabled ? .gray : iconColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if !suffix.isEmpty {
                            Text(suffix)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 46)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(BouncyCardButtonStyle())
        .disabled(isDisabled)
    }
}

  struct BouncyCardButtonStyle: ButtonStyle {
      func makeBody(configuration: Configuration) -> some View { configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed) }
  }

// MARK: - 周效率卡片 - v3 - iPhone布局修正 & 适配 macOS 大屏判定

struct WeeklyEfficiencyCard: View {
    @Binding var viewingWeekStart: Date
    var ts: TimeStore
    var es: EfficiencyStore
    var showNavigation: Bool = true
    
    func canGoNextWeek() -> Bool { Calendar.current.date(byAdding: .weekOfYear, value: 1, to: viewingWeekStart)! <= Date() }
    func changeWeek(_ i: Int) { if let d = Calendar.current.date(byAdding: .weekOfYear, value: i, to: viewingWeekStart) { viewingWeekStart = d } }
    func getWeekDays(_ s: Date) -> [Date] { var c = Calendar.current; c.firstWeekday = 2; return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: s) } }
    func weekTitle(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "MM.dd"; let e = Calendar.current.date(byAdding: .day, value: 6, to: d)!; return "\(f.string(from: d)) - \(f.string(from: e))" }
    
    // 【核心修改】：封装设备判定，适配原生 macOS
    var isPad: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    var body: some View {
        // 【核心修改】：使用外部计算属性
        // 关键逻辑：只有 iPhone 的横屏才用 4-3 紧凑布局
        // iPad/Mac 无论横竖，都走下面的 3-3-1 宽敞布局
        let isPhoneLandscape = (!showNavigation && !isPad)
        
        let days = getWeekDays(viewingWeekStart)
        
        VStack(spacing: 0) {
            // 导航栏 (iPhone横屏时隐藏，iPad/Mac横屏显示)
            if showNavigation {
                HStack(spacing: 0) {
                    Button { changeWeek(-1) } label: { CompactNavArrow(icon: "chevron.left", isDisabled: false) }.buttonStyle(.plain)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "calendar").font(.system(size: 10, weight: .bold)).foregroundColor(.cyan.opacity(0.8))
                        Text(weekTitle(viewingWeekStart)).font(.system(size: 13, design: .monospaced)).fontWeight(.bold).foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                    Button { if canGoNextWeek() { changeWeek(1) } } label: { CompactNavArrow(icon: "chevron.right", isDisabled: !canGoNextWeek()) }.buttonStyle(.plain).disabled(!canGoNextWeek())
                }.padding(.top, 8).padding(.bottom, 6).padding(.horizontal, 12)
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.5).padding(.bottom, 15)
            }
            
            GeometryReader { geo in
                let totalWidth = geo.size.width
                
                VStack(spacing: 0) {
                    if isPhoneLandscape {
                        // === iPhone 横屏布局 (4-3) ===
                        let spacing: CGFloat = 12
                        let itemWidth = (totalWidth - (spacing * 3)) / 4
                        
                        // 第一排 (向下偏移 25px，解决顶边露出的问题)
                        HStack(spacing: spacing) {
                            ForEach(0..<4) { i in DayShowcaseView(date: days[i], ts: ts, es: es).frame(width: itemWidth) }
                        }
                        .padding(.top, 25) // 【修正】：增加顶部内边距
                        
                        Spacer().frame(height: 20) // 这里的间距
                        
                        // 第二排
                        HStack(spacing: spacing) {
                            ForEach(4..<7) { i in DayShowcaseView(date: days[i], ts: ts, es: es).frame(width: itemWidth) }
                        }
                        
                    } else {
                        // === iPad/Mac (横/竖) 和 iPhone (竖) 布局 (3-3-1) ===
                        // 这样大屏横屏时会利用宽大的屏幕横向铺开 3 个，并填满空间
                        let spacing: CGFloat = 12
                        let cols: CGFloat = 3
                        let itemWidth = (totalWidth - (spacing * (cols - 1))) / cols
                        
                        VStack(spacing: 27) {
                            HStack(spacing: spacing) { ForEach(0..<3) { i in DayShowcaseView(date: days[i], ts: ts, es: es).frame(width: itemWidth) } }
                            HStack(spacing: spacing) { ForEach(3..<6) { i in DayShowcaseView(date: days[i], ts: ts, es: es).frame(width: itemWidth) } }
                            HStack(spacing: spacing) { DayShowcaseView(date: days[6], ts: ts, es: es).frame(width: itemWidth) }
                        }
                    }
                }
            }
            // 动态高度调整
            // iPhone横屏：增加高度以容纳 padding.top
            // 其他：保持标准高度
            .frame(height: isPhoneLandscape ? 280 : 384)
            .padding(.horizontal, 12).padding(.bottom, 15)
        }
        .background(Color(white: 0.08).opacity(0.9))
        .cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.1), lineWidth: 1)).shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - iCloud 文件管理器 - v42 - 适配 Swift 6 并发协议与异步 IO 修复

final class CloudFileManager: @unchecked Sendable {
    static let shared = CloudFileManager()
    private init() {}
    
    private let appFolderName = "李知本时间管理"
    private let tombstoneDirName = ".tombstones"
    private let tombstoneSuffix = ".dead"
    private let watermarkKey = "cloud_sync_watermarks"
    
    private let legacyStateFileName = "currentRecordState_v20.json"
    
    // 【启动优化】：url(forUbiquityContainerIdentifier:) 每次调用都要和 iCloud 守护进程同步握手，
    // 首次调用（尤其是刚重新签名编译后）可能阻塞数秒。缓存解析结果，避免 getCloudDir 高频重复握手。
    private let iCloudRootLock = NSLock()
    private var cachedICloudRoot: URL?

    private var iCloudRoot: URL? {
        iCloudRootLock.lock()
        if let cached = cachedICloudRoot {
            iCloudRootLock.unlock()
            return cached
        }
        iCloudRootLock.unlock()

        guard let root = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            return nil
        }

        iCloudRootLock.lock()
        cachedICloudRoot = root
        iCloudRootLock.unlock()
        return root
    }
    
    private var localRoot: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent(appFolderName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    enum SubFolder: String {
        case records = "记录", settings = "设置"
    }
    
    func cleanLegacyStateFile() {
        let cloudLegacy = getCloudDir(.records).appendingPathComponent(legacyStateFileName)
        let localLegacy = getLocalMirrorDir(.records).appendingPathComponent(legacyStateFileName)
        try? FileManager.default.removeItem(at: cloudLegacy); try? FileManager.default.removeItem(at: localLegacy)
    }
    
    func getSanitizedFileName(_ rawName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return rawName.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    func getCloudDir(_ folder: SubFolder) -> URL {
        let root = iCloudRoot ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(appFolderName)
        let dir = root.appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: dir.path) { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    
    func getLocalMirrorDir(_ folder: SubFolder) -> URL {
        let dir = localRoot.appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: dir.path) { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    
    private func getTombstoneDir() -> URL {
        let root = iCloudRoot ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(appFolderName)
        let dir = root.appendingPathComponent(tombstoneDirName)
        if !FileManager.default.fileExists(atPath: dir.path) { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    
    private func getTombstoneURL(folder: SubFolder, fileName: String) -> URL {
        let safeName = fileName.replacingOccurrences(of: "/", with: "_")
        let mappedName = "\(folder.rawValue)_\(safeName)\(tombstoneSuffix)"
        return getTombstoneDir().appendingPathComponent(mappedName)
    }
    
    private func getRelativePath(folder: SubFolder, fileName: String) -> String { "\(folder.rawValue)/\(fileName)" }
    
    private func getLastPushedDate(folder: SubFolder, fileName: String) -> Date {
        let dict = UserDefaults.standard.dictionary(forKey: watermarkKey) as? [String: Double] ?? [:]
        let key = getRelativePath(folder: folder, fileName: fileName)
        return Date(timeIntervalSince1970: dict[key] ?? 0)
    }
    
    // 【266号修正】：标记为 nonisolated 以允许在异步 Task 中安全调用
    nonisolated private func updateWatermark(folder: SubFolder, fileName: String) {
        let key = "\(folder.rawValue)/\(fileName)"
        var dict = UserDefaults.standard.dictionary(forKey: "cloud_sync_watermarks") as? [String: Double] ?? [:]
        dict[key] = Date().timeIntervalSince1970
        UserDefaults.standard.set(dict, forKey: "cloud_sync_watermarks")
    }
    
    private func isStrictPullFile(folder: SubFolder, fileName: String) -> Bool {
        return folder == .records && fileName == "timeRecords_v20.json"
    }
    
    func smartLoad(folder: SubFolder, fileName: String) -> Data? {
        let diagnosticEvent = "CloudFileManager.smartLoad \(folder.rawValue)/\(fileName)"
        let diagnosticStart = StartupDiagnostics.shared.begin(diagnosticEvent)
        defer { StartupDiagnostics.shared.end(diagnosticEvent, since: diagnosticStart) }
        let localURL = getLocalMirrorDir(folder).appendingPathComponent(fileName)
        let cloudURL = getCloudDir(folder).appendingPathComponent(fileName)
        let tombstoneURL = getTombstoneURL(folder: folder, fileName: fileName)
        if FileManager.default.fileExists(atPath: tombstoneURL.path) {
            if FileManager.default.fileExists(atPath: localURL.path) { try? FileManager.default.removeItem(at: localURL) }
            return nil
        }
        let cloudExists = FileManager.default.fileExists(atPath: cloudURL.path)
        let strictPull = isStrictPullFile(folder: folder, fileName: fileName)
        if cloudExists {
            try? FileManager.default.startDownloadingUbiquitousItem(at: cloudURL)
            if let data = coordinatedRead(from: cloudURL, forStrictPull: strictPull) {
                try? data.write(to: localURL, options: .atomic)
                updateWatermark(folder: folder, fileName: fileName)
                return data
            } else { return nil }
        }
        if FileManager.default.fileExists(atPath: localURL.path) { return try? Data(contentsOf: localURL) }
        return nil
    }
    
    func saveDual(data: Data, folder: SubFolder, fileName: String) {
        let cloudURL = getCloudDir(folder).appendingPathComponent(fileName)
        let localURL = getLocalMirrorDir(folder).appendingPathComponent(fileName)
        let tombstoneURL = getTombstoneURL(folder: folder, fileName: fileName)
        
        // 物理修复：在脱离 Task 之前不再访问 self.fm 而是直接使用全局 default
        Task.detached(priority: .background) {
            let fm = FileManager.default
            if fm.fileExists(atPath: tombstoneURL.path) {
                await self.coordinatedDelete(at: tombstoneURL)
            }
            try? data.write(to: localURL, options: .atomic)
            await self.coordinatedWrite(data: data, to: cloudURL)
            self.updateWatermark(folder: folder, fileName: fileName)
        }
    }
    
    private func coordinatedRead(from url: URL, forStrictPull: Bool = false) -> Data? {
        var res: Data?
        NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [.withoutChanges], error: nil) { newURL in
            let values = try? newURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if values?.ubiquitousItemDownloadingStatus == .current || values?.ubiquitousItemDownloadingStatus == .downloaded {
                if let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: newURL), !conflicts.isEmpty {
                    if forStrictPull { res = nil } else {
                        let winner = conflicts.max(by: { ($0.modificationDate ?? Date.distantPast) < ($1.modificationDate ?? Date.distantPast) }) ?? NSFileVersion.currentVersionOfItem(at: newURL)
                        res = try? Data(contentsOf: winner?.url ?? newURL)
                        try? NSFileVersion.removeOtherVersionsOfItem(at: newURL)
                        conflicts.forEach { $0.isResolved = true }
                    }
                } else { res = try? Data(contentsOf: newURL) }
            } else { res = nil }
        }
        return res
    }
    
    // 【核心修复】：标记为 nonisolated 并使用 async 以支持后台 Task 物理写入
    nonisolated private func coordinatedWrite(data: Data, to url: URL) async {
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: nil) { try? data.write(to: $0, options: .atomic) }
    }
    
    nonisolated private func coordinatedDelete(at url: URL) async {
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forDeleting, error: nil) { try? FileManager.default.removeItem(at: $0) }
    }

    func saveDualAsync(data: Data, folder: SubFolder, fileName: String) async { saveDual(data: data, folder: folder, fileName: fileName) }
    func smartLoadAsync(folder: SubFolder, fileName: String) async -> Data? { return smartLoad(folder: folder, fileName: fileName) }
    func getBackupsDir() -> URL { let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LocalBackups")
        if !FileManager.default.fileExists(atPath: dir.path) { try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }

}

// MARK: - 新用户欢迎页 - v1 - 权益告知
//
// OnboardingView
// (新增：首次启动时展示。
//  核心文案：
//  1. 激活 30 天 Pro 体验。
//  2. 明确承诺：到期自动降级为免费版，基础功能永久可用，无自动扣费。)

struct OnboardingView: View {
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.1), .black], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 图标
                ZStack {
                    Circle().fill(Color.orange.opacity(0.15)).frame(width: 100, height: 100)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                }
                .shadow(color: .orange.opacity(0.3), radius: 10)
                
                // 标题
                VStack(spacing: 12) {
                    Text("欢迎使用 李知本·时间")
                        .font(.title).fontWeight(.heavy)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("已为您自动激活")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("30天 Pro 尊享体验")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.yellow.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                }
                
                // 权益列表
                VStack(alignment: .leading, spacing: 20) {
                    BenefitRow(icon: "lock.open.fill", color: .green, text: "解锁高级统计和全套皮肤")
                    BenefitRow(icon: "creditcard.slash", color: .blue, text: "无需绑定支付方式，绝无自动扣费")
                    // 【核心承诺】
                    BenefitRow(icon: "checkmark.shield.fill", color: .white, text: "30天后自动降级为免费版，基础功能永久可用，数据不丢失")
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.1)))
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 按钮
                Button {
                    withAnimation {
                        settingsStore.startTrial()
                    }
                } label: {
                    Text("开始体验")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    // 内部辅助组件
    struct BenefitRow: View {
        let icon: String
        let color: Color
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 15)) // 稍微调大字体
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}


// MARK: - 全局设置管理器 - v7 - 增加开发者调试权限绕过
//
// class GlobalSettingsStore
// (修改内容：
//  1. [Feature] 在 isProEffective 中增加 #if DEBUG 判定。只要是 Xcode 安装的开发版本，强制返回 true，解决开发阶段过期问题。
//  2. [Feature] 在 remainingTrialDays 中增加 #if DEBUG 判定。开发版显示 999 天，保持 UI 美观。
//  3. [STABLE] 维持原有的配置保存、云端文件监听与回声抑制逻辑。)
@MainActor
class GlobalSettingsStore: ObservableObject {
    @Published var config = AppSettings() {
        didSet {
            if !isLoadingData { save() }
        }
    }
    
    @AppStorage("settings_hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    private let fileName = "global_settings.json"
    private var isFreshLaunch = false
    private var isLoadingData = false
    
    // 【核心修改】：判定是否拥有 Pro 权限
    var isProEffective: Bool {
        #if DEBUG
        // 只要是 Xcode 调试安装的版本，永远拥有 Pro 权限
        return true
        #else
        // 生产版本（App Store 版）走正常付费逻辑
        if config.isPro { return true }
        if let installDate = config.installDate {
            return Date() < installDate.addingTimeInterval(30 * 24 * 3600)
        }
        return true
        #endif
    }
    
    // 【核心修改】：判定剩余天数
    var remainingTrialDays: Int {
        #if DEBUG
        return 999 // 开发版显示 999 天
        #else
        if config.isPro { return 999 }
        guard let installDate = config.installDate else { return 30 }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: installDate.addingTimeInterval(30 * 24 * 3600))
        return max(0, diff.day ?? 0)
        #endif
    }
    
    init() {
        load()
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloudFileChange), name: .CloudFileDidChange, object: nil)
    }
    
    @objc private func handleCloudFileChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let path = userInfo["path"] as? String else { return }
        
        let expectedPath = "设置/\(fileName)"
        if path == expectedPath {
            Task {
                if isFreshLaunch {
                    print("[GlobalSettings] 幽灵模式：检测到云端文件，尝试加载")
                    load()
                } else {
                    print("[GlobalSettings] 检测到配置更新，正在重载")
                    load()
                }
            }
        }
    }
    
    func startTrial() {
        if config.installDate == nil {
            config.installDate = Date()
        }
        hasSeenOnboarding = true
    }
    
    func save() {
        isFreshLaunch = false
        
        guard let data = try? JSONEncoder().encode(self.config) else { return }
        let fName = self.fileName
        
        let relativePath = "设置/\(fName)"
        CloudSyncManager.shared.ignoreNextUpdate(relativePath: relativePath)
        
        Task.detached(priority: .background) {
            await CloudFileManager.shared.saveDualAsync(data: data, folder: .settings, fileName: fName)
        }
    }
    
    func backup() {
        guard let data = try? JSONEncoder().encode(self.config) else { return }
        BackupManager.shared.saveBackup(data: data, module: "Settings")
    }
    
    func load() {
        isLoadingData = true
        let fName = self.fileName
        
        Task.detached(priority: .userInitiated) {
            if let data = await CloudFileManager.shared.smartLoadAsync(folder: .settings, fileName: fName) {
                await MainActor.run {
                    if let loadedConfig = try? JSONDecoder().decode(AppSettings.self, from: data) {
                        self.config = loadedConfig
                        self.isFreshLaunch = false
                    }
                    self.isLoadingData = false
                }
            } else {
                await MainActor.run {
                    self.isFreshLaunch = true
                    print("[GlobalSettings] 进入幽灵模式 (无本地/云端配置)")
                    self.isLoadingData = false
                }
            }
        }
    }
}


// MARK: - 单日详情弹窗 - v2 - 独立组件
//
// DayShowcaseEditSheet
// (新增：必须保留此结构体，它是 DayShowcaseView 的依赖组件，用于解决主视图编译器超时问题。)

struct DayShowcaseEditSheet: View {
    @Binding var showingEditSheet: Bool
    let date: Date
    let baseColor: Color
    @EnvironmentObject var ts: TimeStore

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [baseColor.opacity(0.2), Color.black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                // 顶部关闭栏
                HStack {
                    Button { showingEditSheet = false } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title2).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Text(Formatters.mmDDEEEE.string(from: date))
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill").opacity(0)
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
                
                // 记录列表
                ListRecordsView(date: .constant(date))
                    .environmentObject(ts)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 单日展示组件 - v55 - 编译器超时终极修复 (分块编译)
//
// DayShowcaseView
// (逻辑修复：
//  1. [FIX] 将 onChange 链条拆分为 loadListeners 和 saveListeners 两个独立属性。
//  2. 强制编译器分段处理类型推断，彻底解决 "unable to type-check" 错误。
//  3. 依赖外部定义的 DayShowcaseEditSheet (请确保文件里有该结构体)。)

struct DayShowcaseView: View {
    let date: Date
    var ts: TimeStore
    @ObservedObject var es: EfficiencyStore
    
    @State private var m = 6
    @State private var a = 6
    @State private var e = 6
    @State private var showingEditSheet = false
    
    // 动画与分数状态
    @State private var animateGlow = false
    @State private var score: Double = 0.0
    
    // 辅助格式化
    static let weekDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
    
    func getWorkDuration() -> String {
        let cal = Calendar.current
        let startOfDayDate = cal.startOfDay(for: date)
        let endOfDayDate = cal.date(byAdding: .day, value: 1, to: startOfDayDate)!
        let now = Date()
        let recs = ts.getRecordsForDisplay(for: date)
        var totalSeconds: TimeInterval = 0
        for r in recs {
            if r.category == "工作" {
                let rawEnd = r.isOngoing ? now : r.endTime
                let effectiveStart = max(r.startTime, startOfDayDate)
                let effectiveEnd = min(rawEnd, endOfDayDate)
                if effectiveEnd > effectiveStart { totalSeconds += effectiveEnd.timeIntervalSince(effectiveStart) }
            }
        }
        return String(format: "%.1fh", totalSeconds / 3600)
    }
    
    func getCrystalColor(_ s: Double) -> Color {
        if s >= 100 { return Color(red: 0.7, green: 0.3, blue: 1.0) }
        if s >= 80 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        if s >= 60 { return Color(red: 0.0, green: 0.9, blue: 0.6) }
        return Color.white.opacity(0.1)
    }
    
    // MARK: - 主视图 Body
    var body: some View {
        // 计算状态
        let isToday = Calendar.current.isDateInToday(date)
        let isFuture = date > Date()
        let weekDay = isToday ? NSLocalizedString("today", comment: "") : Self.weekDayFormatter.string(from: date)
        let shouldShowMedal = (!isFuture && (isToday ? score >= 60 : true))
        let baseColor = getCrystalColor(score)
        
        // 主视觉构建
        mainVisuals(weekDay: weekDay, isToday: isToday, isFuture: isFuture, shouldShowMedal: shouldShowMedal, baseColor: baseColor)
            .frame(height: 109)
            
            // --- 交互与生命周期 ---
            .onLongPressGesture { if !isFuture { showingEditSheet = true } }
            .sheet(isPresented: $showingEditSheet) {
                TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                    DayShowcaseEditSheet(showingEditSheet: $showingEditSheet, date: date, baseColor: baseColor)
                        .environmentObject(ts)
                }
            }
            .onAppear {
                loadData()
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
            
            // --- 数据监听层 (分块加载) ---
            // 将逻辑分为两层背景，避免单行修饰符过长
            .background(loadListeners)
            .background(saveListeners)
    }
    
    // MARK: - 拆分出的监听器 (解决编译器超时)
    
    // 1. 负责数据加载的监听器
    private var loadListeners: some View {
        Color.clear
            .onChange(of: date) { _,_ in loadData() }
            .onChange(of: ts.records) { _,_ in loadData() }
            .onChange(of: es.dailyData) { _,_ in loadData() }
            .onChange(of: es.weeklyTargets) { _,_ in loadData() }
    }
    
    // 2. 负责数据保存的监听器
    private var saveListeners: some View {
        Color.clear
            .onChange(of: m) { _,_ in save() }
            .onChange(of: a) { _,_ in save() }
            .onChange(of: e) { _,_ in save() }
    }
    
    // MARK: - 视觉构建器
    @ViewBuilder
    private func mainVisuals(weekDay: String, isToday: Bool, isFuture: Bool, shouldShowMedal: Bool, baseColor: Color) -> some View {
        ZStack {
            // 1. 光晕
            if !isFuture && score >= 60 {
                RoundedRectangle(cornerRadius: 24)
                    .fill(baseColor)
                    .blur(radius: 20)
                    .opacity(animateGlow ? 0.7 : 0.3)
                    .scaleEffect(animateGlow ? 1.1 : 1.0)
            }
            
            // 2. 背景
            RoundedRectangle(cornerRadius: 20)
                .fill(baseColor.opacity(0.15))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // 3. 内容
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Text(weekDay).font(.system(size: 8, weight: .bold)).foregroundColor(isToday ? .white : .white.opacity(0.7))
                        Spacer()
                    }
                    if !isFuture {
                        Text(getWorkDuration())
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.95))
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(baseColor.opacity(0.25)))
                    }
                    HStack {
                        Spacer()
                        if !isFuture {
                            Text(String(format: "%.0f", score)).font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [.white, baseColor], startPoint: .top, endPoint: .bottom))
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.top, 12)
                
                Spacer()
                
                // Medal
                ZStack {
                    if shouldShowMedal {
                        LargeMedalView(score: score).frame(width: 52, height: 52)
                    } else {
                        Text(isFuture ? "-" : "待提高").font(.caption2).foregroundColor(.white.opacity(0.2))
                    }
                }
                .frame(height: 54)
                
                Spacer()
                
                // Pills
                HStack(spacing: 6) {
                    PaleEffPill(icon: "sunrise.fill", value: $m)
                    PaleEffPill(icon: "sun.max.fill", value: $a)
                    PaleEffPill(icon: "moon.stars.fill", value: $e)
                }
                .padding(.horizontal, 10).padding(.bottom, 12)
                .opacity(isFuture ? 0.5 : 1.0).disabled(isFuture)
            }
        }
    }
    
    // MARK: - 数据逻辑
    func loadData() {
        let d = es.getEfficiency(for: date)
        m = d.morningEff
        a = d.afternoonEff
        e = d.eveningEff
        score = GlobalLogic.calculateScore(for: date, records: ts.getRecordsForDisplay(for: date), es: es)
    }
    
    func save() {
        es.updateEfficiency(for: date, m: m, a: a, e: e)
        loadData()
    }
}


  struct CompactNavArrow: View {
      let icon: String; let isDisabled: Bool
      var body: some View { ZStack { RoundedRectangle(cornerRadius: 8).fill(isDisabled ? Color.white.opacity(0.02) : Color.white.opacity(0.08)).frame(width: 40, height: 26); Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(isDisabled ? .gray.opacity(0.3) : .white.opacity(0.9)) }.contentShape(Rectangle()) }
  }

  struct PaleEffPill: View {
      let icon: String; @Binding var value: Int
      var body: some View { Menu { Picker("效率", selection: $value) { ForEach(1...10, id: \.self) { i in Text("\(i)").tag(i) } } } label: { ZStack { Capsule().fill(Color.white.opacity(0.05)); Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5); HStack(spacing: 2) { Image(systemName: icon).font(.system(size: 8)); Text("\(value)").font(.system(size: 9, weight: .bold)) }.foregroundColor(.white.opacity(0.7)) }.frame(height: 20) }.highPriorityGesture(TapGesture()) }
  }

  // MARK: - 勋章容器 - v26 - 新版分段规则
  //
  //  LargeMedalView
  //  (分数规则更新：
  //   1. >= 100: 紫色 (StMichaelMedal)
  //   2. 80 - 100: 金色 (FreedomMedal)
  //   3. 60 - 80: 绿色 (GreenBanyanMedal)
  //   4. < 60: 灰色 (SilverCloudMedal))

  struct LargeMedalView: View {
      let score: Double
      var body: some View {
          Group {
              if score >= 100 {
                  StMichaelMedal()    // 紫色
              } else if score >= 80 {
                  FreedomMedal()      // 金色 (80 <= score < 100)
              } else if score >= 60 {
                  GreenBanyanMedal()  // 绿色 (60 <= score < 80)
              } else {
                  SilverCloudMedal()  // 灰色 (< 60)
              }
          }
          .frame(width: 54, height: 54)
          .scaleEffect(0.9)
          .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
      }
  }





struct MonthlyEfficiencyCard: View {
    @Binding var monthStart: Date; var ts: TimeStore; var es: EfficiencyStore; var showNavigation: Bool = true
    func changeMonth(_ i: Int) { if let d = Calendar.current.date(byAdding: .month, value: i, to: monthStart) { monthStart = d } }
    func canGoNextMonth() -> Bool { Calendar.current.date(byAdding: .month, value: 1, to: monthStart)! <= Date() }
    func monthTitle(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy.MM"; return f.string(from: d) }
    func getDays() -> [Date?] { var c = Calendar.current; c.firstWeekday = 2; guard let range = c.range(of: .day, in: .month, for: monthStart) else { return [] }; let firstDayOfMonth = c.date(from: c.dateComponents([.year, .month], from: monthStart))!; let firstWeekday = c.component(.weekday, from: firstDayOfMonth); var padding = firstWeekday - 2; if padding < 0 { padding += 7 }; var result = Array(repeating: Date?.none, count: padding); for day in range { result.append(c.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)) }; return result }
    
    var body: some View {
        VStack(spacing: 0) {
            if showNavigation {
                HStack(spacing: 0) {
                    Button { changeMonth(-1) } label: { MonthNavArrow(icon: "chevron.left", isDisabled: false) }.buttonStyle(.plain)
                    Spacer()
                    HStack(spacing: 6) { Image(systemName: "calendar.badge.clock").font(.system(size: 12, weight: .bold)).foregroundColor(.purple.opacity(0.8)); Text(monthTitle(monthStart)).font(.system(size: 15, design: .monospaced)).fontWeight(.black).foregroundColor(.white.opacity(0.9)) }
                    Spacer()
                    Button { if canGoNextMonth() { changeMonth(1) } } label: { MonthNavArrow(icon: "chevron.right", isDisabled: !canGoNextMonth()) }.buttonStyle(.plain).disabled(!canGoNextMonth())
                }.padding(.top, 12).padding(.bottom, 12).padding(.horizontal, 16)
            }
            HStack(spacing: 8) { ForEach(["一","二","三","四","五","六","日"], id:\.self) { t in Text(t).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.3)).frame(maxWidth: .infinity) } }.padding(.horizontal, 16).padding(.bottom, 8).padding(.top, showNavigation ? 0 : 10)
            let days = getDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) { ForEach(Array(days.enumerated()), id: \.offset) { _, dayWrapper in if let date = dayWrapper { MonthGlassCell(date: date, ts: ts, es: es) } else { Color.clear.frame(height: 45) } } }.padding(.horizontal, 16).padding(.bottom, 20)
        }
        // 修改：使用固定深色背景
        .background(Color(white: 0.08).opacity(0.9))
        .cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.1), lineWidth: 1)).shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
    }
}


// MARK: - 月视图单元格 - v8 - 修复编译器超时
//
// MonthGlassCell
// (逻辑修复：
//  1. 将 LinearGradient 中复杂的透明度计算提取为局部变量 (fillOpacity, strokeOpacity)。
//  2. 解决 "The compiler is unable to type-check" 错误。
//  3. 保持 v7 的算分逻辑不变。)

struct MonthGlassCell: View {
    let date: Date
    var ts: TimeStore
    @ObservedObject var es: EfficiencyStore
    
    // 评分颜色逻辑
    func getScoreColor(_ s: Double) -> Color {
        if s >= 100 { return .purple }
        if s >= 90 { return .orange }
        if s >= 80 { return .yellow }
        if s >= 60 { return .green }
        return .gray
    }
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isFuture = date > Date()
        
        // 获取数据
        let cellRecords = ts.getRecordsForDisplay(for: date)
        let score = GlobalLogic.calculateScore(for: date, records: cellRecords, es: es)
        
        let hasScore = !isFuture && score > 0
        
        // 基础颜色
        let baseColor = hasScore ? getScoreColor(score) : (isToday ? .cyan : .gray)
        
        // 【核心修复】提取复杂逻辑，帮助编译器推断类型
        let fillOpacity = hasScore ? 0.3 : (isToday ? 0.2 : 0.05)
        let strokeOpacity = isToday ? 0.8 : (hasScore ? 0.5 : 0.1)
        let strokeWidth = isToday ? 1.5 : 0.8
        
        let fillGradient = LinearGradient(
            colors: [baseColor.opacity(fillOpacity), baseColor.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        let strokeGradient = LinearGradient(
            colors: [baseColor.opacity(strokeOpacity), baseColor.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(fillGradient)
            
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(strokeGradient, lineWidth: strokeWidth)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, design: .rounded))
                .fontWeight(isToday ? .heavy : .medium)
                .foregroundColor(isToday ? .white : (isFuture ? .white.opacity(0.2) : .white.opacity(0.9)))
                .shadow(color: baseColor.opacity(0.5), radius: isToday ? 4 : 0)
        }
        .frame(height: 45)
    }
}

  struct MonthNavArrow: View { let icon: String; let isDisabled: Bool; var body: some View { ZStack { RoundedRectangle(cornerRadius: 8).fill(isDisabled ? Color.white.opacity(0.02) : Color.white.opacity(0.08)).frame(width: 36, height: 26); Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(isDisabled ? .gray.opacity(0.3) : .white.opacity(0.9)) }.contentShape(Rectangle()) } }

struct GlassScopeSwitcher: View {
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 0) {
            SwitcherButton(title: NSLocalizedString("week_overview", comment: ""), icon: "calendar", isSelected: selection == 0) { selection = 0 }
            SwitcherButton(title: NSLocalizedString("month_review", comment: ""), icon: "calendar.badge.clock", isSelected: selection == 1) { selection = 1 }
        }
        .padding(4)
        // 修改：背景改为深色半透明
        .background(Capsule().fill(Color.black.opacity(0.3)).overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)))
    }
}
  struct SwitcherButton: View {
      let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
      var body: some View { Button(action: action) { HStack(spacing: 6) { Image(systemName: icon).font(.subheadline); Text(title).font(.subheadline).fontWeight(.bold) }.foregroundColor(isSelected ? .white : .gray).frame(maxWidth: .infinity).padding(.vertical, 10).background(ZStack { if isSelected { Capsule().fill(Color.blue.opacity(0.8)).shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4).overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)) } }).contentShape(Capsule()) }.buttonStyle(.plain).animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected) }
  }

// MARK: - 记录主视图 - v41 - 适配原生 macOS 大屏判定
//
// RecordsView
// (修改：
//  1. 引入 os(macOS) 替换 macCatalyst 判断。
//  2. 仅在 iPhone 横屏 (isPhoneLandscape) 时隐藏 Tab 并强制显示列表。
//  3. iPad/Mac 在横屏下依然保留 列表/饼图/时间轴 切换功能。)

struct RecordsView: View {
    @EnvironmentObject var ts: TimeStore
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var recordTab = 0
    @State private var date = Date()
    @State private var pick = false
    @State private var timelineType = 0
    @State private var showPaywall = false
    
    // 判断设备类型
    var isPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            // 【核心逻辑】只有 iPhone 的横屏才进入"纯列表沉浸模式"
            // iPad 和 Mac 无论横竖屏，都保持全功能 (带 Tab 切换)
            let isPhoneLandscape = isLandscape && !isPadOrMac
            
            VStack(spacing: 0) {
                // 1. Tab 切换器：iPhone横屏隐藏，其他情况(竖屏或iPad/Mac)显示
                if !isPhoneLandscape {
                    RecordTypeSwitcher(selection: $recordTab)
                        .padding(.horizontal, 40).padding(.top, 10).padding(.bottom, 15)
                } else {
                    Color.clear.frame(height: 10)
                }
                
                // 2. 顶部日期控制栏
                HStack {
                    Button {
                        if !settingsStore.isProEffective {
                            showPaywall = true
                        } else {
                            mv(-1)
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(settingsStore.isProEffective ? .gray : .orange)
                    }
                    Spacer()
                    Button { pick = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar").font(.caption).foregroundColor(.blue);
                            // 标题格式根据模式调整
                            Text(getHeaderTitle(isPhoneLandscape: isPhoneLandscape)).font(.headline).fontWeight(.bold).foregroundColor(.white).monospacedDigit()
                        }
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    Spacer()
                    Button { if canMoveForward() { mv(1) } } label: {
                        Image(systemName: "chevron.right.circle.fill").font(.title2)
                            .foregroundColor(canMoveForward() ? .gray : .gray.opacity(0.3))
                    }.disabled(!canMoveForward())
                }
                .padding(.horizontal).padding(.bottom, 8)
                
                // 3. 内容区域
                Group {
                    // iPhone横屏强制显示列表，否则根据 Tab 选择显示
                    if isPhoneLandscape || recordTab == 0 {
                        ListRecordsView(date: $date)
                    }
                    else if recordTab == 1 {
                        PieChartView(date: date)
                    }
                    else {
                        TimelineView(date: date, type: $timelineType)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .sheet(isPresented: $pick) {
                TTModalSheetContainer(minWidth: 520, minHeight: 420) {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetRecordsDate"))) { _ in
                date = Date(); recordTab = 0; timelineType = 0
            }
            .sheet(isPresented: $showPaywall) {
                TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                    PaywallView()
                        .environmentObject(settingsStore)
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
    
    func canMoveForward() -> Bool { return date < Calendar.current.startOfDay(for: Date()) }
    
    func mv(_ i: Int) {
        let cal = Calendar.current
        var component: Calendar.Component = .day
        if recordTab == 2 {
            if timelineType == 1 { component = .weekOfYear }
            else if timelineType == 2 { component = .month }
        }
        if let n = cal.date(byAdding: component, value: i, to: date), n <= Date() {
            withAnimation { date = n }
        }
    }

    func getHeaderTitle(isPhoneLandscape: Bool) -> String {
        // 如果是 iPhone 横屏，或者不在时间轴模式，显示具体日期
        if isPhoneLandscape || recordTab != 2 { return Formatters.mmDDEEEE.string(from: date) }
        
        // 时间轴模式下的特殊标题
        if timelineType == 0 { return Formatters.mmDDEEEE.string(from: date) }
        else if timelineType == 1 {
            var c = Calendar.current; c.firstWeekday = 2
            let wStart: Date
            if let w = c.date(from: c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) { wStart = w }
            else {
                let weekday = c.component(.weekday, from: date); let diff = (weekday + 5) % 7
                wStart = c.date(byAdding: .day, value: -diff, to: c.startOfDay(for: date))!
            }
            let wEnd = c.date(byAdding: .day, value: 6, to: wStart)!
            return "\(Formatters.mmDD.string(from: wStart)) - \(Formatters.mmDD.string(from: wEnd))"
        } else { return Formatters.yyyyMM.string(from: date) }
    }
}



  struct RecordTypeSwitcher: View {
      @Binding var selection: Int
      var body: some View { HStack(spacing: 0) { TypeIconBtn(icon: "list.bullet", index: 0, selection: $selection); TypeIconBtn(icon: "chart.pie.fill", index: 1, selection: $selection); TypeIconBtn(icon: "clock.fill", index: 2, selection: $selection) }.padding(4).background(Capsule().fill(.ultraThinMaterial).overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))).shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5) }
  }

  struct TypeIconBtn: View {
      let icon: String; let index: Int; @Binding var selection: Int; var isSelected: Bool { selection == index }
      var body: some View { Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = index } } label: { ZStack { if isSelected { Capsule().fill(Color.blue.opacity(0.8)).shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 0) } else { Capsule().fill(Color.clear) }; Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundColor(isSelected ? .white : .gray).scaleEffect(isSelected ? 1.1 : 1.0) }.frame(height: 36).frame(maxWidth: .infinity).contentShape(Capsule()) }.buttonStyle(.plain) }
  }

// MARK: - 记录列表视图 - v26 - 适配 macOS 震动反馈机制

struct ListRecordsView: View {
    @Binding var date: Date
    @EnvironmentObject var ts: TimeStore
    @State var edit: TimeRecord?
    @State var add = false
    @State var editCurrent = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var refresher = Date()
    
    // 【核心修改】：通过条件编译分离 iOS 与 macOS 的状态存储
    #if !os(macOS)
    let impact = UIImpactFeedbackGenerator(style: .medium)
    #endif
    
    var body: some View {
        let allRecs = ts.getRecordsForDisplay(for: date)
        
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            if isLandscape {
                HStack(spacing: 0) {
                    recordList(allRecs: allRecs).frame(maxWidth: .infinity)
                    VStack(spacing: 20) {
                        Spacer()
                        Button {
                            add = true
                            #if !os(macOS)
                            impact.impactOccurred()
                            #endif
                        } label: {
                            ZStack {
                                Circle().fill(LinearGradient(colors:[Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Image(systemName: "plus").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                            }.frame(width: 60, height: 60).shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }.buttonStyle(BouncyScaleButtonStyle())
                        
                        Button { if ts.canUndo() { ts.undo() } } label: { sideCircleBtn(icon: "arrow.uturn.backward", enabled: ts.canUndo()) }.disabled(!ts.canUndo()).buttonStyle(BouncyScaleButtonStyle())
                        Button { if ts.canRedo() { ts.redo() } } label: { sideCircleBtn(icon: "arrow.uturn.forward", enabled: ts.canRedo()) }.disabled(!ts.canRedo()).buttonStyle(BouncyScaleButtonStyle())
                        Spacer()
                    }.frame(width: 90).background(Color.black.opacity(0.2)).overlay(Rectangle().frame(width: 0.5).foregroundColor(Color.white.opacity(0.1)), alignment: .leading)
                }
            } else {
                ZStack(alignment: .bottom) {
                    recordList(allRecs: allRecs)
                    HStack(spacing: 12) {
                        Button { if ts.canUndo() { ts.undo() } } label: { bottomSquareBtn(icon: "arrow.uturn.backward", enabled: ts.canUndo()) }.disabled(!ts.canUndo()).buttonStyle(BouncyScaleButtonStyle())
                        Button { if ts.canRedo() { ts.redo() } } label: { bottomSquareBtn(icon: "arrow.uturn.forward", enabled: ts.canRedo()) }.disabled(!ts.canRedo()).buttonStyle(BouncyScaleButtonStyle())
                        
                        Button {
                            add = true
                            #if !os(macOS)
                            impact.impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus").font(.system(size: 20, weight: .black))
                                Text(NSLocalizedString("add_record", comment: "")).font(.headline).fontWeight(.heavy).tracking(1)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                            .background {
                                ZStack {
                                    Capsule().fill(LinearGradient(colors:[Color(red: 0.0, green: 0.8, blue: 1.0), Color(red: 0.0, green: 0.4, blue: 1.0), Color(red: 0.4, green: 0.0, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    Capsule().strokeBorder(LinearGradient(colors:[.white.opacity(0.6), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                                }
                            }
                            .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }.buttonStyle(BouncyScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 75)
                }
            }
        }
        .sheet(item: $edit) { r in
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                EditRecordView(record: r)
            }
        }
        .sheet(isPresented: $add) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                AddRecordView(targetDate: date)
            }
        }
        .sheet(isPresented: $editCurrent) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                EditCurrentRecordView()
            }
        }
        .onReceive(timer) { _ in refresher = Date() }
    }
    
    func recordList(allRecs: [TimeRecord]) -> some View {
        List {
            Color.clear.frame(height: 10).listRowBackground(Color.clear).listRowSeparator(.hidden)
            if allRecs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass").font(.largeTitle).foregroundColor(.gray.opacity(0.3))
                    Text(NSLocalizedString("no_records", comment: "")).font(.subheadline).foregroundColor(.gray.opacity(0.5))
                    Text(NSLocalizedString("swipe_hint", comment: "")).font(.caption).foregroundColor(.gray.opacity(0.3)).padding(.top, 4)
                }.frame(maxWidth: .infinity).padding(.vertical, 40).listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            ForEach(allRecs) { r in
                Button { if r.isOngoing { editCurrent = true } else { edit = r } } label: { RecordRow(record: r, isLive: r.isOngoing) }
                .buttonStyle(.plain)
                .contextMenu {
                    Section { Button { ts.eatPrevious(r) } label: { Label(NSLocalizedString("swallow_prev", comment: ""), systemImage: "arrow.up.circle") }; Button { ts.eatNext(r) } label: { Label(NSLocalizedString("swallow_next", comment: ""), systemImage: "arrow.down.circle") } }
                    Section { Button { ts.mergeIntoPrevious(r) } label: { Label(NSLocalizedString("merge_prev", comment: ""), systemImage: "arrow.merge") }; Button { ts.mergeIntoNext(r) } label: { Label(NSLocalizedString("merge_next", comment: ""), systemImage: "arrow.merge") } }
                    if !r.isOngoing { Section { Button { ts.extendOneHour(r) } label: { Label(NSLocalizedString("extend_1h", comment: ""), systemImage: "clock.arrow.circlepath") } } }
                    Section { Button(role: .destructive) { ts.deleteRecord(r) } label: { Label(r.isOngoing ? NSLocalizedString("stop_delete", comment: "") : NSLocalizedString("restore_gap", comment: ""), systemImage: "trash") } }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) { Button(role: .destructive) { withAnimation { ts.deleteRecord(r) } } label: { Label(NSLocalizedString("delete", comment: ""), systemImage: "trash.fill") } }
                .swipeActions(edge: .leading, allowsFullSwipe: false) { Button { ts.updateCategory(for: r, to: "工作") } label: { Label(I18n.cat("工作"), systemImage: "briefcase.fill") }.tint(getColor(for: "工作")); Button { ts.updateCategory(for: r, to: "生活") } label: { Label(I18n.cat("生活"), systemImage: "house.fill") }.tint(getColor(for: "生活")); Button { ts.updateCategory(for: r, to: "刚需") } label: { Label(I18n.cat("刚需"), systemImage: "bus.fill") }.tint(getColor(for: "刚需")); Button { ts.updateCategory(for: r, to: "监控") } label: { Label(I18n.cat("监控"), systemImage: "eye.fill") }.tint(getColor(for: "监控")) }
                .listRowBackground(Color.clear).listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            Color.clear.frame(height: 150).listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .listStyle(.plain).scrollContentBackground(.hidden).background(Color.clear)
        .gesture(DragGesture().onEnded { value in
            let threshold: CGFloat = 50
            if value.translation.width < -threshold { switchDate(offset: 1) }
            else if value.translation.width > threshold { switchDate(offset: -1) }
        })
    }
    
    func bottomSquareBtn(icon: String, enabled: Bool) -> some View { ZStack { RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(white: 0.15).opacity(0.9)); Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundColor(enabled ? .white : .gray.opacity(0.3)) }.frame(width: 56, height: 56).shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3) }
    func sideCircleBtn(icon: String, enabled: Bool) -> some View { ZStack { Circle().fill(Color(white: 0.15).opacity(0.9)); Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundColor(enabled ? .white : .gray.opacity(0.3)) }.frame(width: 50, height: 50).shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3) }
    func switchDate(offset: Int) { if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: date), newDate <= Date() { withAnimation(.easeInOut(duration: 0.3)) { date = newDate } } }
}

// MARK: - 记录行组件 - V35 - 开始00:00/结束24:00
//
// RecordRow
// (逻辑修正：开始时间保持标准 hhMM 显示 00:00，结束时间调用 formatEndTime 显示 24:00)

struct RecordRow: View {
    let record: TimeRecord
    var isLive: Bool = false
    var body: some View {
        let color = getColor(for: record.category)
        let duration = Int(record.duration)
        let h = duration / 3600
        let m = (duration % 3600) / 60
        let effectiveIsLive = isLive || record.isOngoing
        
        HStack(spacing: 0) {
            Capsule().fill(color).frame(width: 4, height: 18).shadow(color: color.opacity(effectiveIsLive ? 1.0 : 0.0), radius: effectiveIsLive ? 5 : 0).padding(.leading, 12).padding(.trailing, 10)
            
            // 【开始时间】：使用标准格式，确保显示 00:00
            Text(Formatters.hhMM.string(from: record.startTime)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
            
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                if h > 0 { Text("\(h)").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(color); Text("h").font(.system(size: 11, weight: .medium)).foregroundColor(color.opacity(0.7)).padding(.trailing, 4) }
                Text(String(format: "%02d", m)).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(color); Text("m").font(.system(size: 11, weight: .medium)).foregroundColor(color.opacity(0.7))
            }.frame(width: 80, alignment: .trailing)
            Spacer()
            
            if effectiveIsLive {
                Text("Now").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(color).padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(color.opacity(0.2))).padding(.trailing, 12)
            } else {
                // 【结束时间】：使用特殊格式，如果是0点则显示 24:00
                Text(Formatters.formatEndTime(record.endTime)).font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(.gray).padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .background { ZStack { RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.12).opacity(0.9)); RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [color.opacity(0.45), color.opacity(0.05), .clear], startPoint: .leading, endPoint: .trailing)) } }
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(LinearGradient(colors: [.white.opacity(0.2), color.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) }
    }
}



  struct PieChartView: View {
      let date: Date
      @EnvironmentObject var ts: TimeStore
      var body: some View {
          let recs = ts.getRecordsForDisplay(for: date)
          let sDay = Calendar.current.startOfDay(for: date)
          let eDay = Calendar.current.date(byAdding: .day, value: 1, to: sDay)!
          let now = Date()
          var dict: [String: Double] = [:]
          for r in recs {
              if r.category == "空" { continue }
              let s = max(r.startTime, sDay)
              let rawEnd = r.isOngoing ? now : r.endTime
              let e = min(rawEnd, eDay)
              let d = max(0, e.timeIntervalSince(s))
              if d > 0 { dict[r.category, default: 0] += d }
          }
          let total = dict.values.reduce(0, +)
          let sortedKeys = dict.keys.sorted()
          
          return VStack {
              if total > 0 {
                  Spacer()
                  ZStack {
                      Circle().stroke(Color.white.opacity(0.1), lineWidth: 40)
                      ForEach(Array(sortedKeys.enumerated()), id: \.offset) { _, cat in
                          PieSliceView(total: total, current: dict[cat]!, offset: getOffset(dict, sortedKeys: sortedKeys, currentCat: cat), color: getColor(for: cat))
                      }
                      VStack(spacing: 4) { Text("有效总计").font(.caption).foregroundColor(.gray); Text(formatDuration(total)).font(.title2).fontWeight(.bold).foregroundColor(.white) }
                  }.frame(width: 260, height: 260)
                  Spacer()
                  ScrollView {
                      VStack(spacing: 16) {
                          ForEach(sortedKeys, id: \.self) { cat in
                              HStack {
                                  Circle().fill(getColor(for: cat)).frame(width: 12, height: 12)
                                  Text(cat).font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                                  Spacer()
                                  Text(formatDuration(dict[cat]!)).font(.system(size: 14, design: .monospaced)).foregroundColor(.white.opacity(0.9))
                                  Text(String(format: "%.1f%%", dict[cat]! / total * 100)).font(.system(size: 12)).frame(width: 50, alignment: .trailing).foregroundColor(.gray)
                              }.padding(.horizontal, 40)
                          }
                      }
                  }.frame(maxHeight: 200).padding(.bottom, 20)
              } else {
                  Spacer()
                  VStack(spacing: 12) { Image(systemName: "chart.pie").font(.largeTitle).foregroundColor(.gray.opacity(0.3)); Text("无有效记录").foregroundColor(.gray.opacity(0.5)) }
                  Spacer()
              }
          }
      }
      
      func getOffset(_ d: [String: Double], sortedKeys: [String], currentCat: String) -> Double {
          var o: Double = 0
          for k in sortedKeys {
              if k == currentCat { break }
              o += d[k]!
          }
          return o
      }
  }

  struct PieSliceView: View { let total: Double; let current: Double; let offset: Double; let color: Color; var body: some View { Circle().trim(from: offset/total, to: (offset+current)/total).stroke(color, style: StrokeStyle(lineWidth: 40, lineCap: .butt)).rotationEffect(.degrees(-90)) } }

// MARK: - 基础视图包裹器 (TimelineView) - v2 - 适配 macOS 震动反馈机制

struct TimelineView: View {
    let date: Date
    @Binding var type: Int
    @EnvironmentObject var ts: TimeStore
    @State private var showAddSheet = false
    
    var weekStart: Date {
        var c = Calendar.current; c.firstWeekday = 2
        if let w = c.date(from: c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) { return w }
        let weekday = c.component(.weekday, from: date)
        let diff = (weekday + 5) % 7
        return c.date(byAdding: .day, value: -diff, to: c.startOfDay(for: date))!
    }
    
    var monthStart: Date { let c = Calendar.current; return c.date(from: c.dateComponents([.year, .month], from: date)) ?? date }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Picker("", selection: $type) { Text("日").tag(0); Text("周").tag(1); Text("月").tag(2) }.pickerStyle(.segmented).padding(.horizontal, 60).padding(.vertical, 10)
                GeometryReader { geo in
                    let availableHeight = geo.size.height
                    let availableWidth = geo.size.width
                    if type == 0 {
                        ScrollView {
                            VStack(spacing: 0) {
                                HStack { Spacer(); DayTimelineColumn(date: date, width: 240, showTime: true, enableDrag: true, enableEdit: true, hideGaps: true, customHeight: nil); Spacer() }
                                .padding(.top, 20).padding(.bottom, 100)
                            }
                        }.coordinateSpace(name: "timelineScroll")
                    } else if type == 1 {
                        let days = getWeekDays(from: weekStart)
                        let colWidth = (availableWidth - 50) / 7
                        HStack(alignment: .top, spacing: 0) {
                            TimeScale(step: 4, customHeight: availableHeight).frame(height: availableHeight)
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(days, id: \.self) { d in
                                    VStack(spacing: 0) {
                                        Text(wkDay(d)).font(.caption2).fontWeight(.bold).foregroundColor(Calendar.current.isDateInToday(d) ? .blue : .gray).frame(height: 20)
                                        DayTimelineColumn(date: d, width: colWidth, showTime: false, enableDrag: false, enableEdit: true, hideGaps: true, customHeight: availableHeight - 20)
                                    }.frame(width: colWidth)
                                }
                            }
                        }.frame(height: availableHeight)
                    } else {
                        let days = getMonthDays(from: monthStart)
                        let colWidth = (availableWidth - 50) / CGFloat(max(1, days.count))
                        HStack(alignment: .top, spacing: 0) {
                            TimeScale(step: 4, customHeight: availableHeight).frame(height: availableHeight)
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(days, id: \.self) { d in DayTimelineColumn(date: d, width: colWidth, showTime: false, enableDrag: false, enableEdit: true, hideGaps: true, customHeight: availableHeight) }
                            }
                        }.frame(height: availableHeight)
                    }
                }
            }
            if type == 0 {
                VStack(spacing: 12) {
                    Button { if ts.canUndo() { ts.undo() } } label: { FloatingIconBtn(icon: "arrow.uturn.backward", isDisabled: !ts.canUndo()) }.disabled(!ts.canUndo())
                    Button { if ts.canRedo() { ts.redo() } } label: { FloatingIconBtn(icon: "arrow.uturn.forward", isDisabled: !ts.canRedo()) }.disabled(!ts.canRedo())
                    Button {
                        #if !os(macOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        showAddSheet = true
                    } label: { FloatingIconBtn(icon: "plus", isDisabled: false, isPrimary: true) }
                }.padding(.trailing, 20).padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                AddRecordView(targetDate: date)
            }
        }
    }
    
    func getWeekDays(from start: Date) -> [Date] { var c = Calendar.current; c.firstWeekday = 2; return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: start) } }
    func getMonthDays(from start: Date) -> [Date] { let c = Calendar.current; guard let range = c.range(of: .day, in: .month, for: start) else { return[] }; return range.compactMap { c.date(byAdding: .day, value: $0 - 1, to: start) } }
    func wkDay(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "E"; f.locale = Locale(identifier: "zh_CN"); return f.string(from: d) }
    
    struct FloatingIconBtn: View {
        let icon: String; let isDisabled: Bool; var isPrimary: Bool = false
        var body: some View { ZStack { Circle().fill(Color.black.opacity(isDisabled ? 0.3 : 0.6)).background(.ultraThinMaterial, in: Circle()).frame(width: 44, height: 44).shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3); Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundColor(isDisabled ? .gray : (isPrimary ? .white : .white.opacity(0.9))) }.scaleEffect(isDisabled ? 0.9 : 1.0).animation(.spring(response: 0.3), value: isDisabled) }
    }
}

  struct TimeScale: View {
      let step: Int; var customHeight: CGFloat? = nil
      var body: some View {
          GeometryReader { geo in
              let totalH = customHeight ?? (CGFloat(24) * 60)
              let hourH = totalH / 24.0
              ZStack(alignment: .topTrailing) {
                  ForEach(0..<(24/step)+1, id: \.self) { i in Text("\(i*step):00").font(.system(size: 10, weight: .black, design: .rounded)).foregroundColor(.white).shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1).position(x: 25, y: CGFloat(i * step) * hourH).offset(y: 6) }
              }
          }.frame(width: 50)
      }
  }

// MARK: - 日历时间轴列组件 - v30 - 适配 macOS 震动反馈机制

struct DayTimelineColumn: View {
    let date: Date
    let width: CGFloat
    var showTime = true
    var enableDrag: Bool = true
    var enableEdit: Bool = true
    var hideGaps: Bool = false
    var customHeight: CGFloat? = nil
    
    @EnvironmentObject var ts: TimeStore
    @AppStorage("settings_magnetism_v25") var isMagnetismEnabled = true
    
    @State private var viewNow = Date()
    @State private var localRecords: [TimeRecord] = []
    
    @State private var draggingRecordID: UUID? = nil
    @State private var currentDragTime: Date? = nil
    @State private var lastSnappedMinute: Int? = nil
    
    @State private var recordToEdit: TimeRecord?
    
    private var totalHeight: CGFloat { customHeight ?? (24 * 60) }
    private var timeScaleFactor: CGFloat { totalHeight / (24 * 60) }
    
    private var contentCutoffHeight: CGFloat {
        let scale = timeScaleFactor
        var maxDate = Calendar.current.startOfDay(for: date)
        if let lastRec = localRecords.max(by: { $0.endTime < $1.endTime }) {
            let end = lastRec.isOngoing ? Date() : lastRec.endTime
            if end > maxDate { maxDate = end }
        }
        if let dragTime = currentDragTime, dragTime > maxDate { maxDate = dragTime }
        if Calendar.current.isDateInToday(date) { let now = Date(); if now > maxDate { maxDate = now } }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let minutes = maxDate.timeIntervalSince(startOfDay) / 60.0
        let paddedMinutes = minutes + 120
        let calculatedHeight = paddedMinutes * scale
        let minHeight = 4.0 * 60.0 * scale
        return max(minHeight, min(calculatedHeight, totalHeight))
    }
    
    var body: some View {
        let blockWidth = width - (showTime ? 50 : 0)
        HStack(alignment: .top, spacing: 0) {
            if showTime { TimeScale(step: 4, customHeight: totalHeight).frame(width: 50, height: totalHeight) }
            ZStack(alignment: .topLeading) {
                TimelineGridBackground(width: width, totalHeight: totalHeight)
                ForEach(localRecords) { record in
                    renderRecordItem(record: record, blockWidth: blockWidth)
                }
            }
            .frame(height: totalHeight)
            .overlay(alignment: .top) {
                if let time = currentDragTime {
                    GeometryReader { geo in
                        let frame = geo.frame(in: .named("timelineScroll"))
                        let stickyOffset = max(0, -frame.minY) + 20
                        HStack {
                            Spacer()
                            Text(Formatters.hhMM.string(from: time))
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(lastSnappedMinute != nil ? .yellow : .white)
                                .padding(.vertical, 10).padding(.horizontal, 20)
                                .background(Capsule().fill(Color(white: 0.15)).overlay(Capsule().stroke(lastSnappedMinute != nil ? Color.yellow.opacity(0.8) : Color.white.opacity(0.4), lineWidth: 1.5)).shadow(color: .black.opacity(0.8), radius: 10))
                                .scaleEffect(lastSnappedMinute != nil ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3), value: lastSnappedMinute)
                            Spacer()
                        }.offset(y: stickyOffset)
                    }.frame(height: 100).allowsHitTesting(false).zIndex(200)
                }
            }
        }
        .frame(height: contentCutoffHeight, alignment: .top).clipped()
        .onAppear { initializeView() }
        .onChange(of: date) { _, _ in initializeView() }
        .onReceive(ts.$records) { _ in if draggingRecordID == nil { syncLocalRecords() } }
        .sheet(item: $recordToEdit) { r in
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                EditRecordView(record: r).environmentObject(ts)
            }
        }
    }
    
    func initializeView() {
        viewNow = Date()
        syncLocalRecords()
        currentDragTime = nil
        lastSnappedMinute = nil
        draggingRecordID = nil
    }
    
    func syncLocalRecords() {
        let all = ts.getRecordsForDisplay(for: date)
        if hideGaps {
            localRecords = all.filter { $0.category != "空" }
        } else {
            localRecords = all
        }
    }
    
    @ViewBuilder func renderRecordItem(record: TimeRecord, blockWidth: CGFloat) -> some View {
        let isOngoing = record.isOngoing
        let isDragging = (draggingRecordID == record.id)
        let frame = calculateFrame(start: record.startTime, end: record.endTime, isOngoing: isOngoing)
        let isTiny = timeScaleFactor < 0.4
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let isFirstItem = abs(record.startTime.timeIntervalSince(dayStart)) < 1
        
        if frame.height > 0 || isDragging {
            Group {
                if frame.height > 2 {
                    TimelineBlock(record: record, height: frame.height, width: blockWidth, isLive: isOngoing, isHovered: isDragging, enableInteraction: enableEdit, onLongPress: {
                        if enableEdit { recordToEdit = record }
                    })
                    .offset(y: frame.top)
                    .zIndex(isDragging ? 100 : 10)
                }
                
                if enableDrag && !isTiny {
                    TopDragHandle(
                        yPos: frame.top,
                        totalWidth: width,
                        color: getColor(for: record.category),
                        timeString: Formatters.hhMM.string(from: record.startTime),
                        isOngoing: isOngoing,
                        isDragging: isDragging,
                        isFirst: isFirstItem,
                        onDragStart: {
                            #if !os(macOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            draggingRecordID = record.id
                            currentDragTime = record.startTime
                            lastSnappedMinute = nil
                        },
                        onDragChanged: { value in
                            handleDragChanged(value, for: record)
                        },
                        onDragEnded: {
                            commitChanges(for: record)
                        },
                        onUndo: {
                            #if !os(macOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            draggingRecordID = nil
                            currentDragTime = nil
                            lastSnappedMinute = nil
                            initializeView()
                        }
                    )
                    .zIndex(101)
                }
            }
        }
    }
    
    func handleDragChanged(_ value: DragGesture.Value, for record: TimeRecord) {
        if draggingRecordID == nil { return }
        guard let idx = localRecords.firstIndex(where: { $0.id == record.id }) else { return }
        
        let cal = Calendar.current
        let originMinutes = (CGFloat(cal.component(.hour, from: record.startTime) * 60 + cal.component(.minute, from: record.startTime)))
        let pixelOffset = value.translation.height
        let minuteOffset = pixelOffset / timeScaleFactor
        let rawTotalMinutes = Int(originMinutes + minuteOffset)
        
        if rawTotalMinutes <= 0 {
            commitZeroStart(for: record)
            return
        }
        
        let now = Date()
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let isToday = cal.isDateInToday(date)
        
        var targetMinutes = rawTotalMinutes
        if isToday && targetMinutes > nowMinutes { targetMinutes = nowMinutes }
        else if targetMinutes > 24*60 { targetMinutes = 24*60 }
        
        var finalMinutes = targetMinutes
        var didSnap = false
        
        if isMagnetismEnabled {
             let nearestHour = ((targetMinutes + 30) / 60) * 60
             if abs(targetMinutes - nearestHour) <= 15 {
                 finalMinutes = nearestHour; didSnap = true
                 if lastSnappedMinute != finalMinutes {
                     #if !os(macOS)
                     UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                     #endif
                     lastSnappedMinute = finalMinutes
                 }
             } else {
                 let nearestHalf = ((targetMinutes + 15) / 30) * 30
                 if abs(targetMinutes - nearestHalf) <= 10 {
                     finalMinutes = nearestHalf; didSnap = true
                     if lastSnappedMinute != finalMinutes {
                         #if !os(macOS)
                         UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                         #endif
                         lastSnappedMinute = finalMinutes
                     }
                 }
             }
        }
        
        if !didSnap { lastSnappedMinute = nil }
        
        let hour = finalMinutes / 60
        let minute = finalMinutes % 60
        guard let newStart = cal.date(bySettingHour: hour, minute: minute, second: 0, of: date) else { return }
        
        currentDragTime = newStart
        
        if idx > 0 {
            var prev = localRecords[idx - 1]
            prev.endTime = newStart
            if prev.startTime > prev.endTime { prev.startTime = prev.endTime }
            localRecords[idx - 1] = prev
        }
        
        for i in idx..<localRecords.count {
            var r = localRecords[i]
            if newStart >= r.endTime {
                if !r.isOngoing { r.startTime = newStart; r.endTime = newStart }
                else { r.startTime = newStart }
            } else if newStart > r.startTime {
                r.startTime = newStart
                localRecords[i] = r
                break
            } else {
                if i == idx { r.startTime = newStart }
                localRecords[i] = r
                break
            }
            localRecords[i] = r
        }
    }
    
    func commitChanges(for record: TimeRecord) {
        guard let idx = localRecords.firstIndex(where: { $0.id == record.id }) else {
            draggingRecordID = nil; currentDragTime = nil; return
        }
        guard let finalTime = currentDragTime else {
            draggingRecordID = nil; return
        }
        
        self.ts.performBatchUpdate {
            if record.isOngoing {
                let now = Date()
                if abs(finalTime.timeIntervalSince(now)) < 60 {
                    self.ts.mergePreviousIntoOngoing()
                } else {
                    self.ts.editOngoing(newStart: finalTime, newCategory: record.category)
                }
            } else if self.ts.currentRecord != nil || !record.isOngoing {
                 if idx > 0 {
                     let prevLocal = localRecords[idx - 1]
                     if let realPrev = self.ts.records.first(where: { $0.id == prevLocal.id }) {
                         self.ts.editRecord(original: realPrev, newCategory: prevLocal.category, newStart: prevLocal.startTime, newEnd: finalTime)
                     }
                 }
                if let realCurrent = self.ts.records.first(where: { $0.id == record.id }) {
                    self.ts.updateStartTime(for: realCurrent, newStartTime: finalTime)
                }
            }
        }
        
        draggingRecordID = nil
        currentDragTime = nil
        lastSnappedMinute = nil
        
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { syncLocalRecords() }
    }
    
    func commitZeroStart(for record: TimeRecord) {
        self.ts.performBatchUpdate {
            guard let idx = localRecords.firstIndex(where: { $0.id == record.id }) else { return }
            let modifiedCurrent = localRecords[idx]
            let dayStart = Calendar.current.startOfDay(for: date)
            
            if record.isOngoing {
                self.ts.editOngoing(newStart: dayStart, newCategory: record.category)
            } else if let realCurrent = self.ts.records.first(where: { $0.id == modifiedCurrent.id }) {
                self.ts.updateStartTime(for: realCurrent, newStartTime: dayStart)
            }
        }
        
        draggingRecordID = nil
        currentDragTime = nil
        lastSnappedMinute = nil
        
        #if !os(macOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { syncLocalRecords() }
    }
    
    struct RecordFrame { let top: CGFloat; let height: CGFloat }
    func calculateFrame(start: Date, end: Date, isOngoing: Bool) -> RecordFrame {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let effectiveStart = max(start, dayStart)
        let nextDay = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let realEnd = isOngoing ? viewNow : end
        let effectiveEnd = min(realEnd, nextDay)
        
        let startMinutes = CGFloat(cal.component(.hour, from: effectiveStart) * 60 + cal.component(.minute, from: effectiveStart))
        let durationMinutes = CGFloat(effectiveEnd.timeIntervalSince(effectiveStart) / 60)
        
        return RecordFrame(top: startMinutes * timeScaleFactor, height: max(0, durationMinutes * timeScaleFactor))
    }
}

// MARK: - 间隙手柄 - V1
struct GapHandleView: View {
  let yPos: CGFloat; let totalWidth: CGFloat; let buttonColor: Color; let timeString: String; let isDragging: Bool; var isLiveTarget: Bool = false; let onDragStart: () -> Void; let onDragChanged: (DragGesture.Value) -> Void; let onDragEnded: () -> Void
  var body: some View {
      ZStack(alignment: .trailing) {
          Rectangle().fill(Color.white.opacity(isDragging ? 0.8 : 0.3)).frame(width: totalWidth, height: isDragging ? 1.5 : 0.5)
          HStack(spacing: 0) {
              if isLiveTarget { VStack(spacing: 0) { Text("进行中").font(.system(size: 8, weight: .black)).foregroundColor(.red); Text(timeString).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(buttonColor) }.padding(.horizontal, 6).padding(.vertical, 2).opacity(isDragging ? 0 : 1) }
              else { Text(timeString).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(buttonColor).padding(.horizontal, 6).padding(.vertical, 3).opacity(isDragging ? 0 : 1) }
          }
          .background { Capsule().fill(Color(white: 0.15)).overlay(Capsule().stroke(buttonColor.opacity(0.5), lineWidth: 1)).shadow(color: isDragging ? .clear : .black.opacity(0.3), radius: 2) }
          .scaleEffect(isDragging ? 0.95 : 1.0).padding(.trailing, 4)
          Color.white.opacity(0.001).frame(width: totalWidth, height: 44).gesture(DragGesture(minimumDistance: 0).onChanged { value in if !isDragging { onDragStart() }; onDragChanged(value) }.onEnded { _ in onDragEnded() })
      }.offset(y: yPos).frame(height: 1).zIndex(100)
  }
}

// MARK: - 当前时间红线 - V1
struct CurrentTimeLine: View {
  let width: CGFloat
  var body: some View {
      let now = Date()
      let cal = Calendar.current
      let nowMinutes = CGFloat(cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now))
      HStack(spacing: 0) {
          Circle().fill(.red).frame(width: 6, height: 6).shadow(color: .red.opacity(0.8), radius: 2)
          Rectangle().fill(Color.red).frame(width: width + 20, height: 1)
      }.offset(x: -3, y: nowMinutes - 3).zIndex(50)
  }
}

// MARK: - 时间轴背景网格 - V1
struct TimelineGridBackground: View {
  let width: CGFloat
  let totalHeight: CGFloat
  var body: some View {
      ZStack(alignment: .topLeading) {
          Color.clear.frame(width: width, height: totalHeight)
          VStack(spacing: 0) {
              let hourHeight = totalHeight / 24.0
              ForEach(0..<24) { _ in
                  Divider().background(Color.white.opacity(0.1)).frame(height: 0.5)
                  Spacer().frame(height: hourHeight - 0.5)
              }
              Divider().background(Color.white.opacity(0.1)).frame(height: 0.5)
          }
      }.allowsHitTesting(false)
  }
}

// MARK: - 顶部拖拽手柄 - V1
struct TopDragHandle: View {
  let yPos: CGFloat
  let totalWidth: CGFloat
  let color: Color
  let timeString: String
  let isOngoing: Bool
  let isDragging: Bool
  let isFirst: Bool
  
  let onDragStart: () -> Void
  let onDragChanged: (DragGesture.Value) -> Void
  let onDragEnded: () -> Void
  let onUndo: () -> Void
  
  var body: some View {
      if isFirst { EmptyView() }
      else {
          ZStack(alignment: .trailing) {
              Rectangle().fill(isDragging ? color : Color.clear).frame(width: totalWidth, height: 1).shadow(color: isDragging ? color.opacity(0.5) : .clear, radius: 2)
              HStack(spacing: 0) {
                  VStack(alignment: .trailing, spacing: 2) {
                      HStack(spacing: 4) {
                          if isOngoing { Image(systemName: "play.fill").font(.system(size: 8, weight: .black)).foregroundColor(.white) }
                          Text(timeString).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                      }
                      .padding(.horizontal, 10).padding(.vertical, 6)
                      .frame(minWidth: isOngoing ? 75 : 60)
                      .background {
                          ZStack {
                              Capsule().fill(color)
                              if isOngoing { Capsule().fill(Color.white.opacity(0.2)); Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1) }
                          }.shadow(color: isOngoing ? color.opacity(0.6) : Color.black.opacity(0.2), radius: isOngoing ? 6 : 3, x: 0, y: isOngoing ? 0 : 2)
                      }
                      .scaleEffect(isDragging ? 1.15 : 1.0).animation(.spring(response: 0.3), value: isDragging)
                  }
              }.padding(.trailing, 4).offset(y: 0)
              Color.white.opacity(0.001).frame(width: totalWidth, height: 44).gesture(DragGesture(minimumDistance: 0).onChanged { value in if !isDragging { onDragStart() }; onDragChanged(value) }.onEnded { _ in onDragEnded() })
          }
          .offset(y: yPos).offset(y: -1).frame(height: 1)
      }
  }
}

// MARK: - 悬浮时间气泡 - V1
struct FloatingTimeBubble: View {
  let time: Date
  var body: some View { HStack(spacing: 4) { Image(systemName: "clock").font(.caption2); Text(Formatters.hhMM.string(from: time)).font(.system(size: 14, weight: .bold, design: .monospaced)) }.padding(.vertical, 6).padding(.horizontal, 10).background { Capsule().fill(Color(white: 0.2)).overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)).shadow(radius: 5) }.foregroundColor(.white) }
}

// MARK: - 时间块组件 - V1
struct TimelineBlock: View {
  let record: TimeRecord
  let height: CGFloat
  let width: CGFloat
  var isLive: Bool = false
  var isHovered: Bool = false
  var enableInteraction: Bool = true
  var onLongPress: () -> Void
  
  var body: some View {
      let isGap = record.category == "空"
      let baseColor: Color = isGap ? Color(white: 0.25) : getColor(for: record.category)
      let cornerRadius: CGFloat = 8
      
      ZStack {
          if isHovered || isLive {
              RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(baseColor.opacity(0.6)).blur(radius: 12).padding(-4)
          }
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(LinearGradient(colors: [baseColor.opacity(isGap ? 0.3 : 0.85), baseColor.opacity(isGap ? 0.1 : 0.55)], startPoint: .top, endPoint: .bottom))
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(LinearGradient(colors: [Color.white.opacity(isGap ? 0.05 : 0.2), Color.clear], startPoint: .top, endPoint: .bottom)).padding(.horizontal, 1)
          
          if isLive {
              VStack { Spacer(); HStack { Spacer(); Circle().fill(Color.white).frame(width: 4, height: 4).shadow(color: .white, radius: 2).padding(4) } }
          }
      }
      .frame(width: width, height: height)
      .contentShape(Rectangle())
      .onLongPressGesture(minimumDuration: 0.3) {
          if enableInteraction { let gen = UIImpactFeedbackGenerator(style: .heavy); gen.impactOccurred(); onLongPress() }
      }
  }
}

// MARK: - 快速添加按钮组 - V1
struct QuickAddButtons: View {
  let onAdd: (Int) -> Void; let times = [5, 10, 15, 20, 30, 60]
  var body: some View { VStack(spacing: 8) { HStack { Text("+").font(.headline).frame(width: 20); ForEach(times, id: \.self) { m in Button(String(format: "%02d", m)) { onAdd(m) }.buttonStyle(.bordered).frame(maxWidth: .infinity) } }; HStack { Text("-").font(.headline).frame(width: 20); ForEach(times, id: \.self) { m in Button(String(format: "%02d", m)) { onAdd(-m) }.buttonStyle(.bordered).frame(maxWidth: .infinity) } } }.padding(8).background(Color.white.opacity(0.05)).cornerRadius(10).padding(.vertical, 5) }
}

// MARK: - 补录记录视图 - v3 - 适配 macOS 震动反馈

struct AddRecordView: View {
    let targetDate: Date
    @EnvironmentObject var ts: TimeStore
    @Environment(\.dismiss) var dismiss
    
    @State var cat = "工作"
    @State var sDate: Date
    @State var sTime: Date
    @State var eDate: Date
    @State var eTime: Date
    
    @State private var showAlert = false
    
    init(targetDate: Date) {
        self.targetDate = targetDate
        _sDate = State(initialValue: targetDate)
        _sTime = State(initialValue: targetDate)
        _eDate = State(initialValue: targetDate)
        _eTime = State(initialValue: targetDate)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            getColor(for: cat).opacity(0.15).ignoresSafeArea().blur(radius: 60)
            
            VStack(spacing: 12) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4)) }
                    Spacer()
                    Text(NSLocalizedString("add_record_title", comment: "")).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "xmark.circle.fill").opacity(0)
                }.padding(.horizontal).padding(.top, 20).padding(.bottom, 5)
                
                HStack(spacing: 15) {
                    ForEach(allCategories.filter{$0 != "空"}, id: \.self) { c in
                        WidgetStyleCategoryBtn(title: c, isSelected: cat == c) { withAnimation { cat = c } }
                    }
                }.padding(.bottom, 5)
                
                VStack(spacing: 8) {
                    GlassInputContainer(title: NSLocalizedString("start_time", comment: "")) {
                        HStack(spacing: 8) {
                            DatePicker("", selection: $sDate, in: ...Date(), displayedComponents: .date).labelsHidden().colorScheme(.dark)
                            DatePicker("", selection: $sTime, in: ...Date(), displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            Spacer()
                            GlassActionBtn(icon: "", title: NSLocalizedString("equal_end", comment: "")) { sDate = eDate; sTime = eTime }
                            GlassActionBtn(icon: "", title: NSLocalizedString("connect_prev", comment: "")) {
                                if let newStart = ts.findAddRecordDefaultStartTime(for: targetDate) {
                                    updateStart(to: newStart)
                                }
                            }
                        }.frame(height: 36)
                    }
                    QuickActionGrid { minutes in modifyTime(isStart: true, minutes: minutes) }
                }
                
                VStack(spacing: 8) {
                    GlassInputContainer(title: NSLocalizedString("end_time_limit", comment: "")) {
                        HStack(spacing: 8) {
                            DatePicker("", selection: $eDate, in: ...Date(), displayedComponents: .date).labelsHidden().colorScheme(.dark)
                            DatePicker("", selection: $eTime, in: ...Date(), displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            Spacer()
                            GlassActionBtn(icon: "", title: NSLocalizedString("equal_start", comment: "")) { eDate = sDate; eTime = sTime }
                            GlassActionBtn(icon: "", title: NSLocalizedString("connect_next", comment: "")) {
                                let currentS = combineDates(sDate, sTime)
                                if let newEnd = ts.findAddRecordDefaultEndTime(for: targetDate, after: currentS) {
                                    updateEnd(to: newEnd)
                                }
                            }
                        }.frame(height: 36)
                    }
                    QuickActionGrid { minutes in modifyTime(isStart: false, minutes: minutes) }
                }
                
                Spacer()
                
                GradientMainButton(title: NSLocalizedString("save_record", comment: ""), icon: "checkmark") {
                    let fs = combineDates(sDate, sTime)
                    let fe = combineDates(eDate, eTime)
                    
                    if fs > fe {
                        showAlert = true
                        return
                    }
                    
                    let finalEnd = min(fe, Date())
                    ts.addRecord(category: cat, startTime: fs, endTime: finalEnd)
                    dismiss()
                }.padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            if let calculatedStart = ts.findAddRecordDefaultStartTime(for: targetDate) {
                updateStart(to: calculatedStart)
                if let calculatedEnd = ts.findAddRecordDefaultEndTime(for: targetDate, after: calculatedStart) {
                    updateEnd(to: calculatedEnd)
                }
            }
        }
        .presentationDetents([.fraction(0.85)])
        .alert("错误", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("开始时间不能晚于结束时间")
        }
    }
    
    func modifyTime(isStart: Bool, minutes: Int) {
        let base = isStart ? combineDates(sDate, sTime) : combineDates(eDate, eTime)
        if let new = Calendar.current.date(byAdding: .minute, value: minutes, to: base) {
            let now = Date()
            if isStart {
                if new > now { sDate = now; sTime = now } else { sDate = new; sTime = new }
            } else {
                if new > now {
                    eDate = now; eTime = now
                    #if !os(macOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                }
                else { eDate = new; eTime = new }
            }
        }
    }
    func updateStart(to date: Date) { sDate = date; sTime = date }
    func updateEnd(to date: Date) { let now = Date(); if date > now { eDate = now; eTime = now } else { eDate = date; eTime = date } }
}

// MARK: - UI样式组件 - V1
struct BouncyScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View { configuration.label.scaleEffect(configuration.isPressed ? 0.9 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed) }
}

struct GlassInputContainer<Content: View>: View {
  let title: String; let content: Content
  init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
  var body: some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(.caption2).foregroundColor(.white.opacity(0.5)).padding(.leading, 4); content.padding(.vertical, 6).padding(.horizontal, 10).background { ZStack { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial); RoundedRectangle(cornerRadius: 12).strokeBorder(LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) } } } }
}

struct GlassActionBtn: View {
  let icon: String; let title: String; let action: () -> Void
  var body: some View {
      Button(action: action) {
          HStack(spacing: 4) { if !icon.isEmpty { Image(systemName: icon).font(.caption2) }; Text(title).font(.system(size: 11, weight: .bold)) }
          .foregroundColor(.white.opacity(0.9)).padding(.horizontal, 12).frame(maxHeight: .infinity)
          .background { ZStack { Capsule().fill(Color.white.opacity(0.1)); Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 0.5) } }
      }.buttonStyle(BouncyScaleButtonStyle())
  }
}

struct WidgetStyleCategoryBtn: View {
  let title: String; let isSelected: Bool; let action: () -> Void
  var baseColor: Color { getColor(for: title) }
  var body: some View { Button(action: action) { VStack(spacing: 6) { ZStack { Circle().fill(isSelected ? AnyShapeStyle(baseColor) : AnyShapeStyle(baseColor.opacity(0.15))).frame(width: 44, height: 44).overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(isSelected ? 0.9 : 0.5), baseColor.opacity(isSelected ? 0.0 : 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: isSelected ? 1.5 : 1)).shadow(color: isSelected ? baseColor.opacity(0.6) : .clear, radius: 8); if isSelected { Circle().fill(.white).frame(width: 4, height: 4).shadow(color: .white, radius: 2) } }; Text(I18n.cat(title)).font(.system(size: 12, weight: isSelected ? .bold : .medium)).foregroundColor(isSelected ? .white : .gray) } }.buttonStyle(.plain) }
}

struct BubbleTimeBtn: View {
  let minutes: Int; var isNegative: Bool = false; let action: () -> Void
  var body: some View { Button(action: action) { ZStack { Circle().fill(isNegative ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)); Circle().strokeBorder(isNegative ? Color.red.opacity(0.2) : Color.blue.opacity(0.2), lineWidth: 1); Text(minutes > 0 ? "+\(minutes)" : "\(minutes)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(isNegative ? .red.opacity(0.8) : .blue.opacity(0.8)) }.frame(width: 36, height: 36) }.buttonStyle(BouncyScaleButtonStyle()) }
}

struct GradientMainButton: View {
  let title: String; let icon: String; let action: () -> Void
  var body: some View { Button(action: action) { HStack(spacing: 8) { Image(systemName: icon).font(.system(size: 16, weight: .bold)); Text(title).font(.headline).fontWeight(.bold) }.foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background { ZStack { Capsule().fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)); Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1) } }.shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5) }.buttonStyle(BouncyScaleButtonStyle()) }
}

struct DestructiveGlassBtn: View {
  let title: String; let icon: String; let action: () -> Void
  var body: some View { Button(action: action) { HStack(spacing: 8) { Image(systemName: icon).font(.system(size: 14, weight: .bold)); Text(title).font(.subheadline).fontWeight(.bold) }.foregroundColor(.red.opacity(0.9)).frame(maxWidth: .infinity).padding(.vertical, 12).background { ZStack { RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)); RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.3), lineWidth: 1) } } }.buttonStyle(BouncyScaleButtonStyle()) }
}

// MARK: - 编辑当前记录视图 - v2 - 适配新方法名
//
// EditCurrentRecordView
// (修改：将 findLastNonEmptyEndTime 更新为 findLastEndTime。)

struct EditCurrentRecordView: View {
    @EnvironmentObject var ts: TimeStore
    @Environment(\.dismiss) var dismiss
    @State var cat = ""; @State var sDate = Date(); @State var sTime = Date()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            getColor(for: cat).opacity(0.15).ignoresSafeArea().blur(radius: 60)
            
            VStack(spacing: 16) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.down.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4)) }
                    Spacer()
                    Text(NSLocalizedString("ongoing", comment: "")).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill").opacity(0)
                }.padding(.horizontal).padding(.top, 20)
                
                HStack(spacing: 15) {
                    ForEach(allCategories.filter{$0 != "空"}, id: \.self) { c in
                        WidgetStyleCategoryBtn(title: c, isSelected: cat == c) { withAnimation { cat = c } }
                    }
                }
                
                VStack(spacing: 8) {
                    GlassInputContainer(title: NSLocalizedString("start_time", comment: "")) {
                        HStack {
                            DatePicker("", selection: $sDate, displayedComponents: .date).labelsHidden().colorScheme(.dark)
                            DatePicker("", selection: $sTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            Spacer()
                            // 【修复】调用新方法名
                            GlassActionBtn(icon: "arrow.up.to.line", title: NSLocalizedString("connect_prev", comment: "")) {
                                if let p = ts.findLastEndTime() { sDate = p; sTime = p }
                            }
                            GlassActionBtn(icon: "clock", title: NSLocalizedString("now", comment: "")) {
                                let now = Date(); sDate = now; sTime = now
                            }
                        }.frame(height: 36)
                    }
                    QuickActionGrid { minutes in
                        let cur = combineDates(sDate, sTime)
                        if let newDate = Calendar.current.date(byAdding: .minute, value: minutes, to: cur) {
                            sDate = newDate; sTime = newDate
                        }
                    }
                }
                
                Spacer()
                
                GradientMainButton(title: NSLocalizedString("update_status", comment: ""), icon: "arrow.triangle.2.circlepath") {
                    let fs = combineDates(sDate, sTime)
                    ts.editOngoing(newStart: fs, newCategory: cat)
                    dismiss()
                }.padding(.bottom, 10)
            }.padding(.horizontal, 20)
        }
        .onAppear {
            if let c = ts.currentRecord {
                cat = c.category; sDate = c.startTime; sTime = c.startTime
            }
        }
        .presentationDetents([.height(520)])
    }
}
struct CategorySelector: View { @Binding var selected: String; var body: some View { HStack(spacing: 15) { ForEach(allCategories.filter{$0 != "空"}, id: \.self) { c in Button { selected = c } label: { Circle().fill(getColor(for: c)).frame(width: 40).overlay(selected == c ? Image(systemName: "checkmark").foregroundColor(.white) : nil) }.buttonStyle(.plain) } }.padding(.vertical) } }

struct QuickActionGrid: View {
  let onAction: (Int) -> Void
  let times = [1, 5, 10, 30, 60]
  var body: some View {
      VStack(spacing: 6) {
          HStack(spacing: 4) {
              ForEach(times, id: \.self) { m in BubbleTimeBtn(minutes: m) { onAction(m) }.frame(maxWidth: .infinity) }
          }
          HStack(spacing: 4) {
              ForEach(times, id: \.self) { m in BubbleTimeBtn(minutes: -m, isNegative: true) { onAction(-m) }.frame(maxWidth: .infinity) }
          }
      }.padding(.horizontal, 4)
  }
}



// MARK: - 数据管理视图 - v40 - 实现物理目录整箱回退还原

struct DataManagementView: View {
    @EnvironmentObject var ts: TimeStore
    @EnvironmentObject var es: EfficiencyStore
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var detailedCategoryStore: DetailedCategoryStore
    @Environment(\.dismiss) var dismiss
    
    @State private var snapshots: [BackupFile] = []
    @State private var showActionSheet = false
    @State private var selectedSnapshot: BackupFile?
    
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    @State private var showShare = false
    @State private var exportURL: URL?
    @State private var showFileImporter = false
    @State private var importAlertMessage = ""
    @State private var showImportResultAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Color.cyan.opacity(0.1).ignoresSafeArea().blur(radius: 60)
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.down.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4)) }
                    Spacer()
                    Text("数据管理 & 回滚").font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill").opacity(0)
                }
                .padding()
                .background(Color(white: 0.1))
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("外部备份 (存到文件App)").font(.caption).foregroundColor(.cyan).padding(.leading, 4)
                            HStack(spacing: 12) {
                                Button { exportAllData() } label: { Label("导出计时与效率数据", systemImage: "square.and.arrow.up.fill").font(.subheadline).bold().frame(maxWidth: .infinity).padding().background(Color.blue.opacity(0.2)).cornerRadius(12) }
                                Button { showFileImporter = true } label: { Label("从文件恢复", systemImage: "square.and.arrow.down.fill").font(.subheadline).bold().frame(maxWidth: .infinity).padding().background(Color.green.opacity(0.2)).cornerRadius(12) }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack { Text("最近自动还原点").font(.caption).foregroundColor(.orange); Spacer(); Text("保留最近30次").font(.caption2).foregroundColor(.gray) }.padding(.horizontal, 4)
                            if snapshots.isEmpty {
                                Text("暂无自动备份 (App进入后台时自动生成)").font(.caption).foregroundColor(.gray).padding()
                            } else {
                                ForEach(snapshots) { snap in
                                    Button { selectedSnapshot = snap; showActionSheet = true } label: {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise.circle.fill").font(.title2).foregroundColor(.orange)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(snap.date.formatted(date: .numeric, time: .standard)).font(.system(size: 15, weight: .medium, design: .monospaced)).foregroundColor(.white)
                                                Text(snap.url.hasDirectoryPath ? "旧版整箱备份" : "计时与效率备份").font(.caption2).foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                                        }
                                        .padding().background(Color(white: 0.12)).cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.1)).padding(.vertical, 10)
                        Button { alertMessage = "确定要清空所有数据吗？此操作不可逆！"; showAlert = true } label: { Label("清空所有数据", systemImage: "trash").foregroundColor(.red).frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).cornerRadius(12) }
                        
                    }.padding(20).padding(.bottom, 40)
                }
            }
        }
        .onAppear { refreshSnapshots() }
        .background(ShareSheet(isPresented: $showShare, items: exportURL != nil ? [exportURL!] : []))
        .confirmationDialog("确认回滚？", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("立即恢复至此状态", role: .destructive) { if let snap = selectedSnapshot { restoreFromSnapshot(snap) } }
            Button("取消", role: .cancel) {}
        } message: {
            Text("还原将替换当前数据。操作不可撤销。")
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.json]) { res in if case .success(let url) = res { restoreFromFile(url) } }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
            if alertMessage.contains("清空") {
                Button("确认清空", role: .destructive) { ts.clearAllData(); refreshSnapshots() }
            }
        } message: { Text(alertMessage) }
        .alert("处理结果", isPresented: $showImportResultAlert) { Button("确定", role: .cancel) { } } message: { Text(importAlertMessage) }
    }
    
    func refreshSnapshots() {
        snapshots = (BackupManager.shared.getSystemSnapshots() + BackupManager.shared.getPhysicalSnapshots())
            .sorted { $0.date > $1.date }
    }

    func exportAllData() {
        let backup = TimerBackupData(
            records: ts.records,
            efficiencyData: es.dailyData,
            targetHours: es.targetHours,
            targetEfficiency: es.targetEfficiency,
            appSettings: settingsStore.config,
            backupDate: Date()
        )
        
        if let data = try? JSONEncoder().encode(backup) {
            if let str = String(data: data, encoding: .utf8) {
                let fileName = "TimeTracker_Backup_\(Date().formatted(date: .numeric, time: .omitted)).json".replacingOccurrences(of: "/", with: "-")
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try? str.write(to: url, atomically: true, encoding: .utf8)
                self.exportURL = url
                self.showShare = true
            }
        }
    }
    
    // 【190号核心修改】：区分物理快照与旧版 JSON 快照
    func restoreFromSnapshot(_ file: BackupFile) {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: file.url.path, isDirectory: &isDir), isDir.boolValue {
            // 如果是文件夹，走整箱替换逻辑
            performPhysicalRestore(from: file.url)
        } else {
            // 兼容旧版 JSON 格式
            do {
                let data = try Data(contentsOf: file.url)
                try restoreTimerBackup(data)
            } catch {
                importAlertMessage = "快照格式不受支持: \(error.localizedDescription)"
                showImportResultAlert = true
            }
        }
    }

    // 【190号核心新增】：物理整箱替换逻辑
    private func performPhysicalRestore(from snapshotURL: URL) {
        let fm = FileManager.default
        // 目标：本地镜像根目录 (例如 Documents/李知本时间管理)
        let localMirrorRoot = CloudFileManager.shared.getLocalMirrorDir(.records).deletingLastPathComponent()
        
        DispatchQueue.main.async {
            do {
                // 1. 物理清场
                if fm.fileExists(atPath: localMirrorRoot.path) {
                    try fm.removeItem(at: localMirrorRoot)
                }
                
                // 2. 整箱拷贝
                try fm.copyItem(at: snapshotURL, to: localMirrorRoot)
                
                // 3. 内存重载：指挥所有组件立即重载硬盘新数据
                ts.load()
                es.load()
                detailedCategoryStore.load()
                
                // 4. 反馈
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                importAlertMessage = "✅ 还原成功：所有物理文件已整箱替换！"
                showImportResultAlert = true
                
                // 5. 提示云同步系统（本地已变，需要后续推送到云端）
                NotificationCenter.default.post(name: NSNotification.Name("CloudDataUpdated"), object: nil)
                
            } catch {
                importAlertMessage = "物理还原失败: \(error.localizedDescription)"
                showImportResultAlert = true
            }
        }
    }
    
    func restoreFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            try restoreTimerBackup(data)
        } catch {
            importAlertMessage = "外部文件损坏: \(error.localizedDescription)"
            showImportResultAlert = true
        }
    }
    
    private func restoreTimerBackup(_ data: Data) throws {
        performTimerRestore(try JSONDecoder().decode(TimerBackupData.self, from: data))
    }

    private func performTimerRestore(_ backup: TimerBackupData) {
        DispatchQueue.main.async {
            ts.records = backup.records; ts.save()
            es.importData(data: backup.efficiencyData, tH: backup.targetHours, tE: backup.targetEfficiency)
            settingsStore.config = backup.appSettings
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            importAlertMessage = "✅ 计时与效率数据已还原！"; showImportResultAlert = true
            NotificationCenter.default.post(name: NSNotification.Name("CloudDataUpdated"), object: nil)
        }
    }
}

                              struct GeneralHistoryView: View {
                                  let moduleName: String
                                  let title: String
                                  let onRestore: (BackupFile) -> Void
                                  @Environment(\.dismiss) var dismiss
                                  @State private var backups: [BackupFile] = []
                                  @State private var now = Date()
                                  
                                  var body: some View {
                                      NavigationStack {
                                          ZStack {
                                              Color(white: 0.05).ignoresSafeArea()
                                              if backups.isEmpty {
                                                  VStack(spacing: 20) {
                                                      Image(systemName: "memories").font(.system(size: 60)).foregroundColor(.gray.opacity(0.3))
                                                      VStack(spacing: 8) {
                                                          Text("暂无备份记录").font(.title3).fontWeight(.bold).foregroundColor(.white.opacity(0.7))
                                                          Text("产生新的时间记录或修改后\n这里会出现历史存档").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center)
                                                      }
                                                  }.padding()
                                              } else {
                                                  List {
                                                      ForEach(backups) { backup in
                                                          Button { onRestore(backup); dismiss() } label: {
                                                              HStack {
                                                                  VStack(alignment: .leading, spacing: 4) {
                                                                      Text(getTimeAgo(backup.date)).font(.headline).foregroundColor(.white)
                                                                      Text(backup.date.formatted(date: .numeric, time: .standard)).font(.caption2).foregroundColor(.gray)
                                                                  }
                                                                  Spacer()
                                                                  Text("恢复").font(.subheadline).fontWeight(.bold).foregroundColor(.orange).padding(.horizontal, 12).padding(.vertical, 6).background(Capsule().stroke(Color.orange, lineWidth: 1))
                                                              }.contentShape(Rectangle())
                                                          }.buttonStyle(.plain)
                                                      }
                                                  }.scrollContentBackground(.hidden)
                                              }
                                          }
                                          .navigationTitle(title).ttNavigationBarTitleDisplayMode(.inline).toolbar { Button("关闭") { dismiss() } }
                                          .onAppear { backups = BackupManager.shared.getHistory(module: moduleName) }
                                      }
                                  }
                                  
                                  func getTimeAgo(_ date: Date) -> String {
                                      let diff = Int(now.timeIntervalSince(date))
                                      if diff < 60 { return "刚刚" }
                                      if diff < 3600 { return "\(diff / 60) 分钟前" }
                                      if diff < 86400 { return "\(diff / 3600) 小时前" }
                                      return "\(diff / 86400) 天前"
                                  }
                              }

private func formatTimeAgo(_ date: Date, currentTime: Date) -> String {
  let diff = Int(currentTime.timeIntervalSince(date))
  if diff < 60 { return "刚刚" }
  else if diff < 3600 { return "\(diff / 60)分钟前" }
  else if diff < 86400 { return "\(diff / 3600)小时前" }
  else { return "\(diff / 86400)天前" }
}

// MARK: - 功能设置入口视图 - v4 - 适配补全后的 I18n

struct FunctionSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: GlobalSettingsStore
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Color.blue.opacity(0.1).ignoresSafeArea().blur(radius: 60)
                
                List {
                    Section {
                        NavigationLink(destination: TabConfigView()) {
                            Label("导航栏设置", systemImage: "slider.horizontal.below.rectangle")
                        }
                        
                        NavigationLink(destination: TimerStyleSelectionView()) {
                            Label(I18n.t(.set_style_select), systemImage: "timer")
                        }
                        
                        Toggle(isOn: $store.config.isMagnetismEnabled) {
                            Label(I18n.t(.set_timer_magnet), systemImage: "ruler.fill")
                        }.tint(.purple)
                        
                        Toggle(isOn: $store.config.calendarAutoSwitch) {
                            Label(I18n.t(.set_cal_auto), systemImage: "calendar.badge.clock")
                        }.tint(.orange)
                        
                        Toggle(isOn: $store.config.showCompletedTasks) {
                            Label(I18n.t(.set_show_completed), systemImage: "checkmark.circle")
                        }.tint(.blue)
                        
                        NavigationLink(destination: PomodoroSettingsView()) {
                            Label("番茄时间", systemImage: "timer.square")
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(I18n.t(.set_func_config))
            .ttNavigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(I18n.t(.done)) { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 番茄设置详情页 - v2 - 修复 Form 编译死锁

struct PomodoroSettingsView: View {
    @EnvironmentObject var store: GlobalSettingsStore
    
    var body: some View {
        Form {
            Section(header: Text(I18n.t(.set_pomo_config))) {
                Stepper(value: $store.config.pomoFocusDuration, in: 5...120, step: 5) {
                    HStack {
                        Text(I18n.t(.set_pomo_duration))
                        Spacer()
                        Text("\(store.config.pomoFocusDuration) min").foregroundColor(.orange).bold()
                    }
                }
                Stepper(value: $store.config.pomoSplitDuration, in: 5...store.config.pomoFocusDuration, step: 5) {
                    HStack {
                        Text(I18n.t(.set_pomo_split))
                        Spacer()
                        Text("\(store.config.pomoSplitDuration) min").foregroundColor(.gray)
                    }
                }
                Stepper(value: $store.config.pomoShortBreak, in: 1...30, step: 1) {
                    HStack {
                        Text(I18n.t(.set_pomo_short))
                        Spacer()
                        Text("\(store.config.pomoShortBreak) min").foregroundColor(.green)
                    }
                }
                Stepper(value: $store.config.pomoLongBreak, in: 5...60, step: 5) {
                    HStack {
                        Text(I18n.t(.set_pomo_long))
                        Spacer()
                        Text("\(store.config.pomoLongBreak) min").foregroundColor(.green)
                    }
                }
                Stepper(value: $store.config.pomoCyclesBeforeLong, in: 1...10, step: 1) {
                    HStack {
                        Text(I18n.t(.set_pomo_interval))
                        Spacer()
                        Text("\(store.config.pomoCyclesBeforeLong)").foregroundColor(.blue).bold()
                    }
                }
                Toggle(I18n.t(.set_pomo_auto), isOn: $store.config.pomoAutoStart).tint(.blue)
            }
            
            Section(header: Text(I18n.t(.set_pomo_sound))) {
                Toggle("专注结束铃声", isOn: $store.config.enableFocusEndSound).tint(.orange)
                if store.config.enableFocusEndSound {
                    Picker("选择铃声", selection: $store.config.focusEndSoundID) {
                        ForEach(availableSounds) { sound in Text(sound.name).tag(sound.id) }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: store.config.focusEndSoundID) { _, newID in
                        SoundManager.play(newID)
                    }
                }
                
                Toggle("休息结束铃声", isOn: $store.config.enableBreakEndSound).tint(.green)
                if store.config.enableBreakEndSound {
                    Picker("选择铃声", selection: $store.config.breakEndSoundID) {
                        ForEach(availableSounds) { sound in Text(sound.name).tag(sound.id) }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: store.config.breakEndSoundID) { _, newID in
                        SoundManager.play(newID)
                    }
                }
                Toggle("内部切分提醒", isOn: $store.config.enableSplitSound).tint(.gray)
            }
        }
        .navigationTitle("番茄设置")
        .ttNavigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 底部导航配置视图 - v7 - 适配原生 macOS 大屏判定

struct TabConfigView: View {
    @AppStorage("settings_tab_config_v251216") var tabConfigJSON: String = ""
    @AppStorage("settings_maxVisibleTabs_v25") var maxVisibleTabs: Int = 4
    
    @State private var tabItems:[CustomFloatingTabBar.TabConfigItem] = []
    
    var totalVisibleCount: Int { tabItems.filter { $0.isVisible }.count + 1 }
    var isPadOrMac: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                if !isPadOrMac {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("分页显示设置").font(.headline).foregroundColor(.white)
                        HStack {
                            Text("每页图标数").foregroundColor(.gray)
                            Spacer()
                            Stepper("", value: $maxVisibleTabs, in: 3...max(3, totalVisibleCount)).labelsHidden()
                            Text("\(maxVisibleTabs)").font(.system(.title3, design: .monospaced)).fontWeight(.bold).foregroundColor(.blue).frame(width: 40).background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
                        }
                        .padding().background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                    }.padding(20); Divider().background(Color.white.opacity(0.1))
                }
                
                List {
                    ForEach(Array(tabItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            if let meta = CustomFloatingTabBar.allTabs[item.id] {
                                HStack {
                                    Image(systemName: meta.icon).foregroundColor(meta.activeColor).frame(width: 24)
                                    Text(meta.title).foregroundColor(.white)
                                    Spacer()
                                    Toggle("", isOn: Binding(get: { tabItems[index].isVisible }, set: { tabItems[index].isVisible = $0 })).labelsHidden().tint(meta.activeColor)
                                }.padding(.vertical, 8)
                            }
                            if !isPadOrMac && shouldShowSplitter(after: index) { PageSplitterView(pageIndex: getPageIndex(after: index)) }
                        }.listRowBackground(Color(white: 0.1)).listRowSeparator(.hidden)
                    }.onMove(perform: moveTabs)
                    
                    HStack {
                        Image(systemName: "gearshape.fill").foregroundColor(.gray).frame(width: 24)
                        Text(I18n.t(.tab_settings)).foregroundColor(.gray)
                        Spacer(); Image(systemName: "lock.fill").font(.caption2).foregroundColor(.gray.opacity(0.5))
                    }.padding(.vertical, 8).listRowBackground(Color(white: 0.1)).listRowSeparator(.hidden)
                }.listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("导航栏配置").ttNavigationBarTitleDisplayMode(.inline).toolbar { EditButton() }
        .onAppear { loadTabConfig() }
        .onDisappear { saveTabConfig() }
    }
    
    func shouldShowSplitter(after arrayIndex: Int) -> Bool { let item = tabItems[arrayIndex]; guard item.isVisible else { return false }; let visibleCountUpToHere = tabItems.prefix(arrayIndex + 1).filter { $0.isVisible }.count; return visibleCountUpToHere % maxVisibleTabs == 0 }
    func getPageIndex(after arrayIndex: Int) -> Int { let visibleCountUpToHere = tabItems.prefix(arrayIndex + 1).filter { $0.isVisible }.count; return visibleCountUpToHere / maxVisibleTabs }
    func loadTabConfig() { self.tabItems = CustomFloatingTabBar.loadConfig() }
    func saveTabConfig() { if let data = try? JSONEncoder().encode(tabItems), let str = String(data: data, encoding: .utf8) { tabConfigJSON = str } }
    func moveTabs(from source: IndexSet, to destination: Int) { tabItems.move(fromOffsets: source, toOffset: destination) }
}

// MARK: - 分页分割线组件 - V1
struct PageSplitterView: View {
    let pageIndex: Int
    var body: some View {
      HStack {
          VStack { Divider().background(Color.blue) }
          Text("分页线 (第 \(pageIndex) 页)").font(.caption2).foregroundColor(.blue).padding(.horizontal, 4).padding(.vertical, 2).background(Capsule().fill(Color.blue.opacity(0.1)))
          VStack { Divider().background(Color.blue) }
      }.padding(.vertical, 8)
  }
}

// MARK: - 计时器样式选择视图 - v3 - 修复支付管理器环境缺失
// TimerStyleSelectionView
// (修改：1. 引入 purchaseManager 环境变量。2. 修正付费拦截弹窗的环境传递)

struct TimerStyleSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsStore: GlobalSettingsStore
    @EnvironmentObject var purchaseManager: PurchaseManager // 【新增】
    @AppStorage("settings_timerStyle_v25") var timerStyle = 0
    
    #if os(iOS)
    @State private var selectedItem: PhotosPickerItem? = nil
    #endif
    @State private var showPhotoSuccess = false
    @State private var showPaywall = false
    
    struct StyleOption: Identifiable { let id: Int; let name: String; let icon: String; let color: Color }
    let options: [StyleOption] = [
        StyleOption(id: 0, name: "流光彗星", icon: "star.fill", color: .yellow),
        StyleOption(id: 1, name: "禅意呼吸", icon: "wind", color: .mint),
        StyleOption(id: 2, name: "光之能量", icon: "bolt.fill", color: .blue),
        StyleOption(id: 3, name: "量子雷达", icon: "dot.radiowaves.left.and.right", color: .green),
        StyleOption(id: 4, name: "赛博故障", icon: "waveform.path.ecg", color: .pink),
        StyleOption(id: 5, name: "紫禁之巅", icon: "building.columns.fill", color: .red),
        StyleOption(id: 6, name: "精英特工", icon: "scope", color: .green),
        StyleOption(id: 7, name: "像素核心", icon: "square.grid.2x2.fill", color: .orange),
        StyleOption(id: 8, name: "上海之光", icon: "building.2.fill", color: .purple),
        StyleOption(id: 9, name: "自定义照片", icon: "photo.artframe", color: .white),
        StyleOption(id: 10, name: "青春(国漫)", icon: "face.smiling.fill", color: .yellow),
        StyleOption(id: 11, name: "原子模型", icon: "atom", color: .cyan)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                if timerStyle == 9 {
                    VStack(spacing: 10) {
                        #if os(iOS)
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            HStack { Image(systemName: "photo.badge.plus"); Text(showPhotoSuccess ? "已更换照片" : "点击选择照片") }
                                .fontWeight(.bold).foregroundColor(.black).padding().frame(maxWidth: .infinity).background(Capsule().fill(showPhotoSuccess ? Color.green : Color.white))
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            guard let item = newItem else { return }
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                    UserPhotoManager.shared.saveAndProcess(image: uiImage)
                                    withAnimation { showPhotoSuccess = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showPhotoSuccess = false }
                                }
                            }
                        }
                        #else
                        Button { pickPhotoOnMac() } label: {
                            HStack { Image(systemName: "photo.badge.plus"); Text(showPhotoSuccess ? "已更换照片" : "点击选择照片") }
                                .fontWeight(.bold).foregroundColor(.black).padding().frame(maxWidth: .infinity)
                                .background(Capsule().fill(showPhotoSuccess ? Color.green : Color.white))
                        }
                        .buttonStyle(.plain)
                        #endif
                        Text("照片将自动裁剪为圆形并添加呼吸效果").font(.caption).foregroundColor(.gray)
                    }.padding(20).background(Color(white: 0.1))
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(options) { option in
                            Button {
                                if !settingsStore.isProEffective && option.id != 0 {
                                    showPaywall = true
                                } else {
                                    withAnimation { timerStyle = option.id; if option.id != 9 { dismiss() } }
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(option.color.opacity(0.15)).frame(width: 60, height: 60)
                                        Image(systemName: option.icon).font(.title).foregroundColor(option.color)
                                        if !settingsStore.isProEffective && option.id != 0 {
                                            Image(systemName: "lock.fill").font(.caption2).foregroundColor(.white).padding(4).background(Circle().fill(Color.orange)).offset(x: 20, y: -20)
                                        }
                                    }
                                    Text(option.name).font(.subheadline).fontWeight(.medium).foregroundColor(timerStyle == option.id ? .white : .gray)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 20)
                                .background { RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)).overlay(RoundedRectangle(cornerRadius: 16).stroke(timerStyle == option.id ? option.color : Color.clear, lineWidth: 2)) }
                            }.buttonStyle(BouncyScaleButtonStyle())
                        }
                    }.padding(20)
                }
            }
        }
        .navigationTitle("选择样式")
        .ttNavigationBarTitleDisplayMode(.inline)
        // 【核心修复】显式传递环境对象
        .sheet(isPresented: $showPaywall) {
            TTModalSheetContainer(minWidth: 760, minHeight: 620) {
                PaywallView()
                    .environmentObject(settingsStore)
                    .environmentObject(purchaseManager)
            }
        }
    }
}

#if os(macOS)
extension TimerStyleSelectionView {
    private func pickPhotoOnMac() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let data = try? Data(contentsOf: url),
           let image = NSImage(data: data) {
            UserPhotoManager.shared.saveAndProcess(image: image)
            withAnimation { showPhotoSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showPhotoSuccess = false }
        }
    }
}
#endif

// MARK: - 设置页玻璃卡片 - V1 (修复泛白)
struct SettingsGlassCard: View {
    let title: String; let subtitle: String; let icon: String; let colors: [Color]; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 50, height: 50).opacity(0.2)
                    Image(systemName: icon).font(.system(size: 22)).foregroundStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background {
                ZStack {
                    // 修改：使用黑色半透明背景
                    RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))
                    RoundedRectangle(cornerRadius: 20).fill(LinearGradient(colors: [colors.first!.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    RoundedRectangle(cornerRadius: 20).strokeBorder(LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                }
            }
            .shadow(color: colors.first!.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(BouncyScaleButtonStyle())
    }
}

// MARK: - 全局分享/导出组件 - v5 - 适配 macOS
//
// ShareSheet
// (修改内容：iOS 端保持 UIActivityViewController，Mac 端引入 NSSharingServicePicker 实现原生分享)

import SwiftUI

#if !os(macOS)
struct ShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 确保 presentedViewController 为空才弹出，防止重复弹出
        if isPresented && uiViewController.presentedViewController == nil {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            // 监听关闭事件
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                isPresented = false
            }
            
            // 【iPad 适配】
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = uiViewController.view
                popover.sourceRect = CGRect(
                    x: uiViewController.view.bounds.midX,
                    y: uiViewController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            // 必须在主线程异步执行，确保视图层级稳定
            DispatchQueue.main.async {
                uiViewController.present(activityVC, animated: true)
            }
        }
    }
}
#else
import AppKit

struct ShareSheet: NSViewRepresentable {
    @Binding var isPresented: Bool
    var items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            DispatchQueue.main.async {
                if self.isPresented {
                    let picker = NSSharingServicePicker(items: self.items)
                    picker.show(relativeTo: nsView.bounds, of: nsView, preferredEdge: .minY)
                    // Mac 端的 picker 显示后即重置状态，防止阻塞线程或重复触发
                    self.isPresented = false
                }
            }
        }
    }
}
#endif

  // MARK: - 勋章组件 - v72 - 紫色勋章 (Timeline流体动画)
  //
  //  StMichaelMedal
  //  (外观：保持 v43 设计 (蛇矛尖变宽)。
  //   修复：使用 SwiftUI.TimelineView 驱动背景光束旋转，
  //   彻底消除 360 度重置时的卡顿，实现丝滑循环。)

  struct StMichaelMedal: View {
      var body: some View {
          // 使用系统时间轴驱动，避免自定义 TimelineView 冲突
          SwiftUI.TimelineView(.animation) { context in
              // 计算角度：360度 / 12秒 = 30度/秒
              let angle = context.date.timeIntervalSinceReferenceDate * 30
              
              ZStack {
                  // 1. 背景光束 (应用旋转)
                  ZStack {
                      ForEach(0..<10) { i in
                          Rectangle()
                              .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                              .frame(width: 4, height: 72)
                              .rotationEffect(.degrees(Double(i) * 36))
                      }
                      ForEach(0..<10) { i in
                          Rectangle()
                              .fill(LinearGradient(colors: [.white, Color(red: 1.0, green: 0.95, blue: 0.8)], startPoint: .top, endPoint: .bottom))
                              .frame(width: 2, height: 60)
                              .rotationEffect(.degrees(Double(i) * 36 + 18))
                      }
                  }
                  .rotationEffect(.degrees(angle)) // 绑定平滑角度
                  
                  // 2. 5个变宽后的紫色金边蛇矛尖组件 (保持静止布局)
                  ForEach(0..<5) { i in
                      ZStack {
                          // 白叶衬托 (宽度翻倍)
                          HStack(spacing: 6) {
                              DoubleTipShape(isLeft: true, fullShape: true)
                                  .fill(LinearGradient(colors: [.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                                  .frame(width: 5.0, height: 14)
                                  .rotationEffect(.degrees(-10))
                              
                              DoubleTipShape(isLeft: false, fullShape: true)
                                  .fill(LinearGradient(colors: [.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                                  .frame(width: 5.0, height: 14)
                                  .rotationEffect(.degrees(10))
                          }
                          .offset(y: 2)
                          
                          // 紫色主蛇矛尖 + 金色边框 (宽度翻倍)
                          ZStack {
                              // 填充层
                              HStack(spacing: 0) {
                                  DoubleTipShape(isLeft: true, fullShape: true)
                                      .fill(LinearGradient(colors: [Color(red: 0.6, green: 0.2, blue: 1.0), Color(red: 0.2, green: 0.0, blue: 0.5)], startPoint: .top, endPoint: .bottom))
                                      .frame(width: 7.0, height: 21)
                                  
                                  DoubleTipShape(isLeft: false, fullShape: true)
                                      .fill(LinearGradient(colors: [Color(red: 0.5, green: 0.1, blue: 0.9), Color(red: 0.15, green: 0.0, blue: 0.3)], startPoint: .top, endPoint: .bottom))
                                      .frame(width: 7.0, height: 21)
                              }
                              
                              // 金色描边层
                              HStack(spacing: 0) {
                                  DoubleTipShape(isLeft: true, fullShape: true)
                                      .stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
                                      .frame(width: 7.0, height: 21)
                                  
                                  DoubleTipShape(isLeft: false, fullShape: true)
                                      .stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
                                      .frame(width: 7.0, height: 21)
                              }
                          }
                      }
                      .offset(y: -18)
                      .rotationEffect(.degrees(Double(i) * 72))
                  }
                  
                  // 3. 中间核心 (保持不变)
                  Circle()
                      .fill(LinearGradient(colors: [Color.purple, Color(red: 0.3, green: 0.0, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      .frame(width: 24, height: 24)
                      .overlay(
                          Circle()
                              .strokeBorder(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4.5)
                      )
                      .shadow(color: .purple.opacity(0.5), radius: 2)
              }
              .shadow(color: .orange.opacity(0.5), radius: 4)
          }
      }
  }




  // MARK: - 勋章依赖组件 (必需) - V1

  struct RoyalRibbonBanner: View {
      var body: some View {
          ZStack {
              HStack(spacing: 50) {
                  RibbonTailShape(isLeft: true).fill(LinearGradient(colors: [Color(red: 0.4, green: 0.0, blue: 0.6), Color(red: 0.2, green: 0.0, blue: 0.4)], startPoint: .top, endPoint: .bottom)).frame(width: 20, height: 28).overlay(RibbonTailShape(isLeft: true).stroke(Color.yellow.opacity(0.8), lineWidth: 1))
                  RibbonTailShape(isLeft: false).fill(LinearGradient(colors: [Color(red: 0.4, green: 0.0, blue: 0.6), Color(red: 0.2, green: 0.0, blue: 0.4)], startPoint: .top, endPoint: .bottom)).frame(width: 20, height: 28).overlay(RibbonTailShape(isLeft: false).stroke(Color.yellow.opacity(0.8), lineWidth: 1))
              }.offset(y: 4)
              ZStack {
                  RibbonMainShape().fill(LinearGradient(colors: [Color(red: 0.6, green: 0.1, blue: 0.9), Color(red: 0.4, green: 0.0, blue: 0.7)], startPoint: .top, endPoint: .bottom)).frame(width: 90, height: 22).shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                  RibbonMainShape().stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5).frame(width: 90, height: 22)
                  Text("LEGEND").font(.system(size: 10, weight: .black, design: .serif)).foregroundColor(.yellow).kerning(1.5).shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1).offset(y: -1)
              }
          }
      }
  }


  // MARK: - 蛇矛尖组件 - V1
  struct PurpleTierSpike: View {
      let isMain: Bool
      var width: CGFloat { isMain ? 14.0 : 5.0 }
      var height: CGFloat { isMain ? 49.0 : 36.0 }
      var body: some View {
          ZStack {
              HStack(spacing: 0) {
                  DoubleTipShape(isLeft: true, fullShape: true).fill(LinearGradient(colors: isMain ? [Color(red: 1.0, green: 0.8, blue: 0.6), .orange] : [.white, .gray], startPoint: .top, endPoint: .bottom)).frame(width: width / 2 + 0.6, height: height + 0.6)
                  DoubleTipShape(isLeft: false, fullShape: true).fill(LinearGradient(colors: isMain ? [Color(red: 1.0, green: 0.8, blue: 0.6), .orange] : [.white, .gray], startPoint: .top, endPoint: .bottom)).frame(width: width / 2 + 0.6, height: height + 0.6)
              }
              HStack(spacing: 0) {
                  DoubleTipShape(isLeft: true, fullShape: false).fill(LinearGradient(colors: isMain ? [Color(red: 0.6, green: 0.2, blue: 1.0), Color(red: 0.2, green: 0.0, blue: 0.5)] : [Color(white: 0.95), Color(white: 0.7)], startPoint: .top, endPoint: .bottom)).frame(width: width / 2, height: height)
                  DoubleTipShape(isLeft: false, fullShape: false).fill(LinearGradient(colors: isMain ? [Color(red: 0.5, green: 0.1, blue: 0.9), Color(red: 0.15, green: 0.0, blue: 0.3)] : [Color(white: 0.85), Color(white: 0.6)], startPoint: .top, endPoint: .bottom)).frame(width: width / 2, height: height)
              }
              Circle().fill(LinearGradient(colors: [.white.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)).frame(width: width * 0.8, height: height * 0.3).scaleEffect(x: 1.0, y: 0.5).offset(y: -height * 0.35).blur(radius: 2)
          }.shadow(color: isMain ? Color.purple.opacity(0.5) : Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
      }
  }

  struct FiveFlatGradCluster: View {
      let itemWidth: CGFloat = 3.5; let spacingAngle: Double = 3.5; let h1: CGFloat = 54.0; let h2: CGFloat = 51.3; let h3: CGFloat = 48.7
      var body: some View {
          ZStack(alignment: .bottom) {
              Group { NarrowGoldSpike(height: h3, width: itemWidth).rotationEffect(.degrees(-spacingAngle * 2), anchor: .bottom); NarrowGoldSpike(height: h3, width: itemWidth).rotationEffect(.degrees(spacingAngle * 2), anchor: .bottom) }
              Group { NarrowGoldSpike(height: h2, width: itemWidth).rotationEffect(.degrees(-spacingAngle), anchor: .bottom); NarrowGoldSpike(height: h2, width: itemWidth).rotationEffect(.degrees(spacingAngle), anchor: .bottom) }
              NarrowGoldSpike(height: h1, width: itemWidth).zIndex(1)
          }
      }
  }

  struct NarrowGoldSpike: View {
      let height: CGFloat; let width: CGFloat; let tipHeight: CGFloat = 2.5
      var body: some View {
          ZStack(alignment: .top) {
              HStack(spacing: 0) {
                  LowTipHalfShape(isLeft: true, tipHeight: tipHeight).fill(LinearGradient(colors: [.yellow, Color(red: 1.0, green: 0.8, blue: 0.0)], startPoint: .top, endPoint: .bottom)).frame(width: width / 2, height: height)
                  LowTipHalfShape(isLeft: false, tipHeight: tipHeight).fill(LinearGradient(colors: [Color(red: 0.9, green: 0.6, blue: 0.0), Color(red: 0.7, green: 0.4, blue: 0.0)], startPoint: .top, endPoint: .bottom)).frame(width: width / 2, height: height)
              }
              VStack(spacing: 3) { ForEach(0..<3) { _ in DiamondGem(size: 1.5) } }.padding(.top, 2)
          }
      }
  }

  struct DiamondGem: View {
      let size: CGFloat
      var body: some View { Circle().fill(RadialGradient(colors: [Color.white, Color(red: 0.8, green: 0.9, blue: 1.0)], center: .center, startRadius: 0.1, endRadius: size)).frame(width: size, height: size).overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 0.2)).shadow(color: .white.opacity(0.6), radius: 0.5, x: 0, y: 0) }
  }

  struct DoubleTipShape: Shape {
      let isLeft: Bool; let fullShape: Bool
      func path(in rect: CGRect) -> Path {
          var path = Path(); let w = rect.width; let h = rect.height; let dipY = h * 0.15
          if isLeft { path.move(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: w * 0.6, y: h)); path.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: w * 0.6, y: h * 0.7), control2: CGPoint(x: 0, y: h * 0.4)); path.addLine(to: CGPoint(x: w, y: dipY)); path.addLine(to: CGPoint(x: w, y: h)) }
          else { path.move(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: w * 0.4, y: h)); path.addCurve(to: CGPoint(x: w, y: 0), control1: CGPoint(x: w * 0.4, y: h * 0.7), control2: CGPoint(x: w, y: h * 0.4)); path.addLine(to: CGPoint(x: 0, y: dipY)); path.addLine(to: CGPoint(x: 0, y: h)) }
          path.closeSubpath(); return path
      }
  }

  struct RibbonMainShape: Shape {
      func path(in rect: CGRect) -> Path { var path = Path(); let w = rect.width; let h = rect.height; let curve: CGFloat = 3.0; path.move(to: CGPoint(x: 0, y: curve)); path.addQuadCurve(to: CGPoint(x: w, y: curve), control: CGPoint(x: w/2, y: -curve)); path.addLine(to: CGPoint(x: w - 2, y: h)); path.addQuadCurve(to: CGPoint(x: 2, y: h), control: CGPoint(x: w/2, y: h - curve*2)); path.closeSubpath(); return path }
  }

  struct RibbonTailShape: Shape {
      let isLeft: Bool
      func path(in rect: CGRect) -> Path { var path = Path(); let w = rect.width; let h = rect.height
          if isLeft { path.move(to: CGPoint(x: w, y: 0)); path.addLine(to: CGPoint(x: 0, y: 5)); path.addLine(to: CGPoint(x: 5, y: h/2 + 2.5)); path.addLine(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: w, y: h - 5)) }
          else { path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: w, y: 5)); path.addLine(to: CGPoint(x: w - 5, y: h/2 + 2.5)); path.addLine(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: 0, y: h - 5)) }
          path.closeSubpath(); return path
      }
  }

  struct LowTipHalfShape: Shape {
      let isLeft: Bool; let tipHeight: CGFloat
      func path(in rect: CGRect) -> Path { var path = Path(); let w = rect.width; let h = rect.height; let bodyTop = tipHeight
          if isLeft { path.move(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: 0, y: bodyTop)); path.addLine(to: CGPoint(x: w, y: 0)); path.addLine(to: CGPoint(x: w, y: h)) }
          else { path.move(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: w, y: bodyTop)); path.addLine(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: 0, y: h)) }
          path.closeSubpath(); return path
      }
  }








                              struct RibbonShape: Shape {
                                  func path(in rect: CGRect) -> Path { var path = Path(); let w = rect.width; let h = rect.height; path.move(to: CGPoint(x: 0, y: 0)); path.addQuadCurve(to: CGPoint(x: w, y: 0), control: CGPoint(x: w/2, y: h * 0.2)); path.addLine(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: w - 10, y: h/2)); path.addQuadCurve(to: CGPoint(x: 10, y: h/2), control: CGPoint(x: w/2, y: h * 0.7)); path.addLine(to: CGPoint(x: 0, y: h)); path.closeSubpath(); return path }
                              }

                              struct LegendaryRays: View {
                                  var body: some View { ZStack { AngularGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear, .purple.opacity(0.2), .clear, .white.opacity(0.3), .clear]), center: .center).mask(Image(systemName: "seal.fill").resizable().frame(width: 120, height: 120)) } }
                              }



  // MARK: - 勋章组件 - v71 - 金色勋章 (Fix冲突)
  //
  //  FreedomMedal
  //  (修复报错：显式调用 SwiftUI.TimelineView(.animation)。
  //   外观保持 v50 放大版设计。)

  struct FreedomMedal: View {
      var body: some View {
          SwiftUI.TimelineView(.animation) { context in
              let angle = context.date.timeIntervalSinceReferenceDate * 30
              
              ZStack {
                  // 1. 背景光束 (旋转层)
                  ZStack {
                      ForEach(0..<10) { i in
                          Rectangle()
                              .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                              .frame(width: 4, height: 72)
                              .rotationEffect(.degrees(Double(i) * 36))
                      }
                      ForEach(0..<10) { i in
                          Rectangle()
                              .fill(LinearGradient(colors: [.white, Color(red: 1.0, green: 0.95, blue: 0.8)], startPoint: .top, endPoint: .bottom))
                              .frame(width: 2, height: 60)
                              .rotationEffect(.degrees(Double(i) * 36 + 18))
                      }
                  }
                  .rotationEffect(.degrees(angle))
                  
                  // 2. 核心大五角星 (静止)
                  Image(systemName: "star.fill")
                      .resizable()
                      .frame(width: 58, height: 56)
                      .foregroundStyle(LinearGradient(colors: [Color.yellow, Color(red: 0.8, green: 0.5, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      .shadow(color: .black.opacity(0.4), radius: 3)
                  
                  // 3. 内部红底金环 (静止)
                  Circle()
                      .strokeBorder(Color.yellow, lineWidth: 2)
                      .background(Circle().fill(Color(red: 0.8, green: 0.1, blue: 0.1)))
                      .frame(width: 20, height: 20)
                  
                  // 4. 中心微星 (静止)
                  Image(systemName: "star.fill")
                      .font(.system(size: 9))
                      .foregroundColor(.white)
              }
              .shadow(color: .orange.opacity(0.5), radius: 5)
          }
      }
  }



// MARK: - 勋章组件 - v71 - 修复版
struct PatrioticWarMedal: View {
    @State private var isRotating = false
    var body: some View {
        ZStack {
            // 将复杂的层级拆分为独立视图
            PatrioticBackgroundLayer(isRotating: isRotating)
            PatrioticGoldLayer()
            PatrioticBlueLayer()
            PatrioticCenterLayer()
            PatrioticInnerStarLayer()
        }
        .scaleEffect(0.95)
        .onAppear { isRotating = true }
    }
}

// 子视图 1：旋转背景层
struct PatrioticBackgroundLayer: View {
    let isRotating: Bool
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                FiveFlatGradCluster()
                    .offset(y: -13)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .rotationEffect(.degrees(isRotating ? 360 : 0))
        .animation(.linear(duration: 12).repeatForever(autoreverses: false), value: isRotating)
    }
}

// 子视图 2：金色矛尖层
struct PatrioticGoldLayer: View {
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                TrueDoubleTipSpike(isBlue: false)
                    .offset(y: -15)
                    .rotationEffect(.degrees(Double(i) * 60 + 30))
            }
        }
    }
}

// 子视图 3：蓝色矛尖层
struct PatrioticBlueLayer: View {
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                TrueDoubleTipSpike(isBlue: true)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
    }
}

// 子视图 4：中心徽章底层
struct PatrioticCenterLayer: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.yellow, .orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.4), radius: 3)
            
            Circle()
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.6), Color(red: 0.8, green: 0.6, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color(red: 0.0, green: 0.1, blue: 0.4))
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 1))
            
            ForEach(0..<12) { i in
                Circle()
                    .fill(Color(red: 1.0, green: 0.95, blue: 0.7))
                    .frame(width: 2.5, height: 2.5)
                    .offset(y: -16.5)
                    .rotationEffect(.degrees(Double(i) * 30))
                    .shadow(color: .orange, radius: 0.5)
            }
        }
    }
}

// 子视图 5：中心五角星和光晕
struct PatrioticInnerStarLayer: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.3, green: 0.6, blue: 1.0), Color(red: 0.0, green: 0.1, blue: 0.6)], center: .topLeading, startRadius: 1, endRadius: 12))
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 6, height: 4)
                .rotationEffect(.degrees(-45))
                .offset(x: -3.5, y: -3.5)
                .blur(radius: 1.5)
        }
    }
}

// (辅助结构体 TrueDoubleTipSpike 保持不变，无需修改)



                      struct TrueDoubleTipSpike: View {
                          let isBlue: Bool
                          var width: CGFloat { isBlue ? 14.0 : 5.0 }
                          var height: CGFloat { isBlue ? 49.0 : 36.0 }
                          var body: some View {
                              ZStack {
                                  HStack(spacing: 0) {
                                      DoubleTipShape(isLeft: true, fullShape: true)
                                          .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                          .frame(width: width / 2 + 0.6, height: height + 0.6)
                                      DoubleTipShape(isLeft: false, fullShape: true)
                                          .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                          .frame(width: width / 2 + 0.6, height: height + 0.6)
                                  }
                                  
                                  HStack(spacing: 0) {
                                      DoubleTipShape(isLeft: true, fullShape: false)
                                          .fill(LinearGradient(colors: isBlue ? [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.0, green: 0.1, blue: 0.4)] : [Color.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                                          .frame(width: width / 2, height: height)
                                      DoubleTipShape(isLeft: false, fullShape: false)
                                          .fill(LinearGradient(colors: isBlue ? [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.0, green: 0.1, blue: 0.4)] : [Color.white, Color(white: 0.8)], startPoint: .top, endPoint: .bottom))
                                          .frame(width: width / 2, height: height)
                                  }
                                  
                                  Circle()
                                      .fill(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
                                      .frame(width: width * 0.8, height: height * 0.3)
                                      .scaleEffect(x: 1.0, y: 0.5)
                                      .offset(y: -height * 0.35)
                                      .blur(radius: 2)
                              }
                              .shadow(color: isBlue ? Color.blue.opacity(0.3) : Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                          }
                      }










  // MARK: - 勋章组件 - v71 - 绿色勋章 (Fix冲突)
  //
  //  GreenBanyanMedal
  //  (修复报错：显式调用 SwiftUI.TimelineView(.animation)。
  //   外观保持 v66 去蓝化设计。)

  struct GreenBanyanMedal: View {
      var body: some View {
          SwiftUI.TimelineView(.animation) { context in
              let angle = context.date.timeIntervalSinceReferenceDate * 30
              
              ZStack {
                  // A. 旋转层
                  ZStack {
                      // 1. 6组金色插入簇 (5杆加宽版)
                      ForEach(0..<6) { i in
                          GoldInsertCluster()
                              .offset(y: -22)
                              .rotationEffect(.degrees(Double(i) * 60 + 30))
                      }
                      
                      // 2. 6组绿色金边蛇矛簇 (变窄版)
                      ForEach(0..<6) { i in
                          GreenSpikeCluster()
                              .offset(y: -24)
                              .rotationEffect(.degrees(Double(i) * 60))
                      }
                  }
                  .rotationEffect(.degrees(angle))
                  
                  // B. 静止核心 (绿圆 + 金框)
                  ZStack {
                      Circle()
                          .fill(LinearGradient(colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.0, green: 0.5, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      
                      Circle()
                          .strokeBorder(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom), lineWidth: 3)
                      
                      Circle()
                          .stroke(Color.white.opacity(0.3), lineWidth: 1)
                          .padding(4)
                  }
                  .frame(width: 28, height: 28)
                  .shadow(color: .black.opacity(0.4), radius: 3)
              }
              .shadow(color: .green.opacity(0.4), radius: 4)
          }
      }
  }

  // MARK: - 绿色勋章子组件 - V1

  // 1. 绿色金边蛇矛簇 (保持不变)
  struct GreenSpikeCluster: View {
      var body: some View {
          HStack(alignment: .bottom, spacing: -1.5) {
              SingleGreenSpike(width: 2.6, height: 18).rotationEffect(.degrees(-15), anchor: .bottom)
              SingleGreenSpike(width: 3.4, height: 21).rotationEffect(.degrees(-8), anchor: .bottom)
              SingleGreenSpike(width: 4.5, height: 24).zIndex(1)
              SingleGreenSpike(width: 3.4, height: 21).rotationEffect(.degrees(8), anchor: .bottom)
              SingleGreenSpike(width: 2.6, height: 18).rotationEffect(.degrees(15), anchor: .bottom)
          }
      }
  }

  // 单个绿色金边蛇矛
  struct SingleGreenSpike: View {
      let width: CGFloat; let height: CGFloat
      var body: some View {
          ZStack {
              DoubleTipShape(isLeft: true, fullShape: true).fill(LinearGradient(colors: [.green, Color(red: 0.0, green: 0.4, blue: 0.1)], startPoint: .top, endPoint: .bottom)).frame(width: width, height: height)
              DoubleTipShape(isLeft: false, fullShape: true).fill(LinearGradient(colors: [.green, Color(red: 0.0, green: 0.4, blue: 0.1)], startPoint: .top, endPoint: .bottom)).frame(width: width, height: height)
          }.overlay(HStack(spacing: 0) {
              DoubleTipShape(isLeft: true, fullShape: true).stroke(Color.yellow, lineWidth: 0.5)
              DoubleTipShape(isLeft: false, fullShape: true).stroke(Color.yellow, lineWidth: 0.5)
          })
      }
  }

  // 2. 金色插入簇 (加宽、描边、分叉更大)
  struct GoldInsertCluster: View {
      var body: some View {
          // 使用 ZStack 模拟扇形，比 HStack 更容易控制根部聚拢尖端发散
          ZStack(alignment: .bottom) {
              // 最左 (H=12)
              GoldRod(height: 12)
                  .rotationEffect(.degrees(-24), anchor: .bottom) // 角度拉大
              
              // 左中 (H=15)
              GoldRod(height: 15)
                  .rotationEffect(.degrees(-12), anchor: .bottom)
              
              // 中心 (H=18)
              GoldRod(height: 18)
                  .zIndex(1)
              
              // 右中 (H=15)
              GoldRod(height: 15)
                  .rotationEffect(.degrees(12), anchor: .bottom)
              
              // 最右 (H=12)
              GoldRod(height: 12)
                  .rotationEffect(.degrees(24), anchor: .bottom)
          }
      }
  }

  // 辅助：金色杆子组件 (加宽 + 描边)
  struct GoldRod: View {
      let height: CGFloat
      // 宽度固定为 3
      let width: CGFloat = 3.0
      
      var body: some View {
          Rectangle()
              .fill(LinearGradient(colors: [.white, .yellow, .orange], startPoint: .top, endPoint: .bottom))
              .frame(width: width, height: height)
              .clipShape(Capsule())
              // 关键：增加描边，让它们重叠时也能看清界限
              .overlay(Capsule().stroke(Color.orange.opacity(0.6), lineWidth: 0.5))
      }
  }



  // MARK: - 勋章组件 - v71 - 灰色勋章 (Fix冲突)
  //
  //  SilverCloudMedal
  //  (修复报错：显式调用 SwiftUI.TimelineView(.animation)。
  //   外观保持 v65 八方白边设计，转速较慢。)

  struct SilverCloudMedal: View {
      var body: some View {
          SwiftUI.TimelineView(.animation) { context in
              // 速度：15度/秒
              let angle = context.date.timeIntervalSinceReferenceDate * 15
              
              ZStack {
                  // 1. 边缘旋转层 (8个簇)
                  ZStack {
                      ForEach(0..<8) { i in
                          GreyFullCluster()
                              .offset(y: -30)
                              .rotationEffect(.degrees(Double(i) * 45))
                      }
                  }
                  .rotationEffect(.degrees(angle))
                  
                  // 2. 静止核心
                  ZStack {
                      Circle()
                          .fill(LinearGradient(colors: [Color(white: 0.95), Color(white: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      
                      Circle()
                          .strokeBorder(Color(white: 0.3), lineWidth: 2)
                      
                      Text("加油")
                          .font(.system(size: 13, weight: .heavy, design: .rounded))
                          .foregroundColor(.black)
                  }
                  .frame(width: 48, height: 48)
                  .shadow(color: .black.opacity(0.15), radius: 3)
              }
              .shadow(color: .gray.opacity(0.3), radius: 4)
          }
      }
  }





  // MARK: - 灰色勋章子组件 - V1

  // 完整的5尖灰色簇
  struct GreyFullCluster: View {
      var body: some View {
          HStack(alignment: .bottom, spacing: -1) {
              // 1. 最左 (小)
              SingleGreySpike(height: 10, widthScale: 0.49)
                  .rotationEffect(.degrees(-15), anchor: .bottom)
              
              // 2. 左中 (中)
              SingleGreySpike(height: 20, widthScale: 0.7)
                  .rotationEffect(.degrees(-8), anchor: .bottom)
              
              // 3. 中间 (主)
              SingleGreySpike(height: 30, widthScale: 1.0)
                  .zIndex(1)
              
              // 4. 右中 (中)
              SingleGreySpike(height: 20, widthScale: 0.7)
                  .rotationEffect(.degrees(8), anchor: .bottom)
              
              // 5. 最右 (小)
              SingleGreySpike(height: 10, widthScale: 0.49)
                  .rotationEffect(.degrees(15), anchor: .bottom)
          }
      }
  }

  // 单个灰色白边蛇矛尖
  struct SingleGreySpike: View {
      let height: CGFloat
      let widthScale: CGFloat
      
      let baseWidth: CGFloat = 8
      
      var body: some View {
          let currentWidth = baseWidth * widthScale
          
          ZStack {
              // 填充层
              HStack(spacing: 0) {
                  DoubleTipShape(isLeft: true, fullShape: true)
                      .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                      .frame(width: currentWidth / 2, height: height)
                  
                  DoubleTipShape(isLeft: false, fullShape: true)
                      .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                      .frame(width: currentWidth / 2, height: height)
              }
              
              // 描边层：改为纯白
              HStack(spacing: 0) {
                  DoubleTipShape(isLeft: true, fullShape: true)
                      .stroke(Color.white, lineWidth: 0.8) // Pure White
                      .frame(width: currentWidth / 2, height: height)
                  
                  DoubleTipShape(isLeft: false, fullShape: true)
                      .stroke(Color.white, lineWidth: 0.8) // Pure White
                      .frame(width: currentWidth / 2, height: height)
              }
          }
      }
  }
