import SwiftUI
#if os(macOS)
import AppKit
#endif
import Combine
import CoreGraphics

enum TabBarMode: String, CaseIterable, Identifiable {
    case iconsOnly
    case textOnly
    case iconsAndText

    var id: String { rawValue }

    var label: String {
        switch self {
        case .iconsOnly:   return "Icons"
        case .textOnly:    return "Text"
        case .iconsAndText:return "Icons & Text"
        }
    }

    var systemImageName: String {
        switch self {
        case .iconsOnly:   return "square.grid.2x2"
        case .textOnly:    return "textformat"
        case .iconsAndText:return "square.grid.2x2.and.square"
        }
    }
}

typealias IconLabelMode = TabBarMode

extension IconLabelMode {
    var description: String { label }
}

enum InterfaceStyle: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    case auto

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Follow macOS"
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Automatic at Night"
        }
    }
}

// Legacy alias for compatibility with older views
typealias AppSettings = AppSettingsModel

enum SidebarBehavior: String, CaseIterable, Identifiable {
    case automatic
    case expanded
    case compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return "Auto-collapse"
        case .expanded:  return "Always expanded"
        case .compact:   return "Favor compact mode"
        }
    }
}

enum CardRadius: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    var value: Double {
        switch self {
        case .small:  return 12
        case .medium: return 18
        case .large:  return 26
        }
    }
}

enum TypographyMode: String, CaseIterable, Identifiable {
    case system
    case dos
    case rounded

    var id: String { rawValue }
}

enum AssignmentSwipeAction: String, CaseIterable, Identifiable, Codable {
    case complete
    case edit
    case delete
    case openDetail

    var id: String { rawValue }

    var label: String {
        switch self {
        case .complete: return "Complete / Undo"
        case .edit: return "Edit"
        case .delete: return "Delete"
        case .openDetail: return "Open Details"
        }
    }

    var systemImage: String {
        switch self {
        case .complete: return "checkmark.circle"
        case .edit: return "pencil"
        case .delete: return "trash"
        case .openDetail: return "info.circle"
        }
    }
}

struct AppTypography {
    enum TextStyle {
        case headline, title2, body
    }

    static func font(for style: TextStyle, mode: TypographyMode) -> Font {
        switch mode {
        case .system:
            switch style {
            case .headline: return .system(size: 24, weight: .semibold)
            case .title2: return .system(size: 20, weight: .semibold)
            case .body: return .system(size: 16, weight: .regular)
            }
        case .dos:
            switch style {
            case .headline: return .custom("Menlo", size: 24).monospacedDigit()
            case .title2: return .custom("Menlo", size: 20).monospacedDigit()
            case .body: return .custom("Menlo", size: 16).monospacedDigit()
            }
        case .rounded:
            switch style {
            case .headline: return .system(size: 24, weight: .semibold, design: .rounded)
            case .title2: return .system(size: 20, weight: .semibold, design: .rounded)
            case .body: return .system(size: 16, weight: .regular, design: .rounded)
            }
        }
    }
}

struct GlassStrength: Equatable {
    var light: Double
    var dark: Double
}

enum AppAccentColor: String, CaseIterable, Identifiable {
    case multicolor
    case graphite
    case aqua
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green

    var id: String { rawValue }

    var label: String {
        switch self {
        case .multicolor: return "Multicolor (Default)"
        case .graphite: return "Graphite"
        case .aqua: return "Aqua"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        }
    }

    fileprivate var nsColor: NSColor {
        switch self {
        case .multicolor: return NSColor.controlAccentColor
        case .graphite: return NSColor.systemGray
        case .aqua: return NSColor.systemTeal
        case .blue: return NSColor.systemBlue
        case .purple: return NSColor.systemPurple
        case .pink: return NSColor.systemPink
        case .red: return NSColor.systemRed
        case .orange: return NSColor.systemOrange
        case .yellow: return NSColor.systemYellow
        case .green: return NSColor.systemGreen
        }
    }

    var color: Color {
        Color(nsColor: nsColor)
    }
}

final class AppSettingsModel: ObservableObject, Codable {
    /// Shared singleton used across the app. Loaded from persisted storage when available.
    static let shared: AppSettingsModel = {
        return AppSettingsModel.load()
    }()

    // MARK: - Codable keys
    enum CodingKeys: String, CodingKey {
        case accentColorRaw, customAccentEnabledStorage, customAccentRed, customAccentGreen, customAccentBlue, customAccentAlpha
        case interfaceStyleRaw, glassLightStrength, glassDarkStrength, sidebarBehaviorRaw, wiggleOnHoverStorage
        case tabBarModeRaw, visibleTabsRaw, tabOrderRaw, quickActionsRaw, enableGlassEffectsStorage
        case cardRadiusRaw, animationSoftnessStorage, typographyModeRaw
        case devModeEnabledStorage, devModeUILoggingStorage, devModeDataLoggingStorage, devModeSchedulerLoggingStorage, devModePerformanceStorage
        case enableICloudSyncStorage
        case enableAIPlannerStorage
        case plannerHorizonStorage
        case enableFlashcardsStorage
        case assignmentSwipeLeadingRaw
        case assignmentSwipeTrailingRaw
    }


    private static func components(from color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        guard let cgColor = color.cgColor else { return nil }
        guard let srgbSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let converted = cgColor.converted(to: srgbSpace, intent: .defaultIntent, options: nil)
        let target = converted ?? cgColor
        guard let comps = target.components else { return nil }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if comps.count >= 4 {
            red = Double(comps[0])
            green = Double(comps[1])
            blue = Double(comps[2])
            alpha = Double(comps[3])
        } else if comps.count == 2 {
            red = Double(comps[0])
            green = Double(comps[0])
            blue = Double(comps[0])
            alpha = Double(comps[1])
        } else {
            return nil
        }

        return (red, green, blue, alpha)
    }

    private enum Keys {
        static let accentColor = "roots.settings.accentColor"
        static let customAccentEnabled = "roots.settings.customAccentEnabled"
        static let customAccentRed = "roots.settings.customAccent.red"
        static let customAccentGreen = "roots.settings.customAccent.green"
        static let customAccentBlue = "roots.settings.customAccent.blue"
        static let customAccentAlpha = "roots.settings.customAccent.alpha"
        static let interfaceStyle = "roots.settings.interfaceStyle"
        static let glassLightStrength = "roots.settings.glass.light"
        static let glassDarkStrength = "roots.settings.glass.dark"
        static let sidebarBehavior = "roots.settings.sidebarBehavior"
        static let wiggleOnHover = "roots.settings.wiggleOnHover"
        static let tabBarMode = "roots.settings.tabBarMode"
        static let visibleTabs = "roots.settings.visibleTabs"
        static let tabOrder = "roots.settings.tabOrder"
        static let quickActions = "roots.settings.quickActions"
        static let enableGlassEffects = "roots.settings.enableGlassEffects"
        static let cardRadius = "roots.settings.cardRadius"
        static let animationSoftness = "roots.settings.animationSoftness"
        static let typographyMode = "roots.settings.typographyMode"
        static let devModeEnabled = "devMode.enabled"
        static let devModeUILogging = "devMode.uiLogging"
        static let devModeDataLogging = "devMode.dataLogging"
        static let devModeSchedulerLogging = "devMode.schedulerLogging"
        static let devModePerformance = "devMode.performance"

        // New keys for global settings
        static let use24HourTime = "roots.settings.use24HourTime"
        static let workdayStartHour = "roots.settings.workday.start.hour"
        static let workdayStartMinute = "roots.settings.workday.start.minute"
        static let workdayEndHour = "roots.settings.workday.end.hour"
        static let workdayEndMinute = "roots.settings.workday.end.minute"
        static let showEnergyPanel = "roots.settings.showEnergyPanel"
        static let highContrastMode = "roots.settings.highContrastMode"
        static let enableAIPlanner = "roots.settings.enableAIPlanner"
        static let plannerHorizon = "roots.settings.plannerHorizon"
    }

    // Backing storage - migrate to UserDefaults-backed values to persist across launches
    nonisolated var accentColorRaw: String = AppAccentColor.multicolor.rawValue
    nonisolated var customAccentEnabledStorage: Bool = false
    nonisolated var customAccentRed: Double = 0
    nonisolated var customAccentGreen: Double = 122 / 255
    nonisolated var customAccentBlue: Double = 1
    nonisolated var customAccentAlpha: Double = 1
    nonisolated var interfaceStyleRaw: String = InterfaceStyle.system.rawValue
    nonisolated var glassLightStrength: Double = 0.33
    nonisolated var glassDarkStrength: Double = 0.17
    nonisolated var sidebarBehaviorRaw: String = SidebarBehavior.automatic.rawValue
    nonisolated var wiggleOnHoverStorage: Bool = true
    nonisolated var tabBarModeRaw: String = TabBarMode.iconsAndText.rawValue
    nonisolated var visibleTabsRaw: String = "dashboard,calendar,planner,assignments,courses,grades,timer,decks"
    nonisolated var tabOrderRaw: String = "dashboard,calendar,planner,assignments,courses,grades,timer,decks"
    nonisolated var quickActionsRaw: String = "add_assignment,add_course,quick_note"
    nonisolated var enableGlassEffectsStorage: Bool = true
    nonisolated var cardRadiusRaw: String = CardRadius.medium.rawValue
    nonisolated var animationSoftnessStorage: Double = 0.42
    nonisolated var typographyModeRaw: String = TypographyMode.system.rawValue
    nonisolated var devModeEnabledStorage: Bool = false
    nonisolated var devModeUILoggingStorage: Bool = false
    nonisolated var devModeDataLoggingStorage: Bool = false
    nonisolated var devModeSchedulerLoggingStorage: Bool = false
    nonisolated var devModePerformanceStorage: Bool = false
    nonisolated var enableICloudSyncStorage: Bool = false

    // New UserDefaults-backed properties
    nonisolated var use24HourTimeStorage: Bool = false
    nonisolated var workdayStartHourStorage: Int = 8
    nonisolated var workdayStartMinuteStorage: Int = 0
    nonisolated var workdayEndHourStorage: Int = 22
    nonisolated var workdayEndMinuteStorage: Int = 0
    nonisolated var showEnergyPanelStorage: Bool = true
    nonisolated var highContrastModeStorage: Bool = false
    nonisolated var enableAIPlannerStorage: Bool = false
    nonisolated var plannerHorizonStorage: String = "1w"
    nonisolated var enableFlashcardsStorage: Bool = true
    nonisolated var assignmentSwipeLeadingRaw: String = AssignmentSwipeAction.complete.rawValue
    nonisolated var assignmentSwipeTrailingRaw: String = AssignmentSwipeAction.delete.rawValue

    // General Settings
    nonisolated var userNameStorage: String? = nil
    nonisolated var startOfWeekStorage: String? = "Sunday"
    nonisolated var defaultViewStorage: String? = "Dashboard"

    // Interface Settings
    nonisolated var reduceMotionStorage: Bool = false
    nonisolated var increaseTransparencyStorage: Bool = false
    nonisolated var glassIntensityStorage: Double? = 0.5
    nonisolated var accentColorNameStorage: String? = "Blue"
    nonisolated var showSidebarByDefaultStorage: Bool = true
    nonisolated var compactModeStorage: Bool = false
    nonisolated var showAnimationsStorage: Bool = true
    nonisolated var enableHapticsStorage: Bool = true
    nonisolated var showTooltipsStorage: Bool = true

    // Profile/Study Coach Settings
    nonisolated var defaultFocusDurationStorage: Int? = 25
    nonisolated var defaultBreakDurationStorage: Int? = 5
    nonisolated var defaultEnergyLevelStorage: String? = "Medium"
    nonisolated var enableStudyCoachStorage: Bool = true
    nonisolated var smartNotificationsStorage: Bool = true
    nonisolated var autoScheduleBreaksStorage: Bool = true
    nonisolated var trackStudyHoursStorage: Bool = true
    nonisolated var showProductivityInsightsStorage: Bool = true
    nonisolated var weeklySummaryNotificationsStorage: Bool = false
    nonisolated var preferMorningSessionsStorage: Bool = false
    nonisolated var preferEveningSessionsStorage: Bool = false
    nonisolated var enableDeepWorkModeStorage: Bool = false

    // Pomodoro defaults (migrated here)
    nonisolated var pomodoroFocusStorage: Int = 25
    nonisolated var pomodoroShortBreakStorage: Int = 5
    nonisolated var pomodoroLongBreakStorage: Int = 15

    // Event load thresholds (persisted)
    nonisolated var loadLowThresholdStorage: Int = 1
    nonisolated var loadMediumThresholdStorage: Int = 3
    nonisolated var loadHighThresholdStorage: Int = 5

    // Category effort profiles (user-tunable)
    struct CategoryEffortProfileStorage: Codable, Equatable {
        var baseMinutes: Int
        var minSessions: Int
        var spreadDaysBeforeDue: Int
        var sessionBiasRaw: String
    }

    nonisolated var categoryEffortProfilesStorage: [String: CategoryEffortProfileStorage] = [:]

    // MARK: - Manual Codable conformance will map to these keys

    var accentColorChoice: AppAccentColor {
        get { AppAccentColor(rawValue: accentColorRaw) ?? .multicolor }
        set { accentColorRaw = newValue.rawValue }
    }

    var isCustomAccentEnabled: Bool {
        get { customAccentEnabledStorage }
        set { customAccentEnabledStorage = newValue }
    }

    var customAccentColor: Color {
        get {
            Color(red: customAccentRed, green: customAccentGreen, blue: customAccentBlue, opacity: customAccentAlpha)
        }
        set {
            guard let components = Self.components(from: newValue) else { return }
            customAccentRed = components.red
            customAccentGreen = components.green
            customAccentBlue = components.blue
            customAccentAlpha = components.alpha
        }
    }

    var activeAccentColor: Color {
        isCustomAccentEnabled ? customAccentColor : accentColorChoice.color
    }

    var interfaceStyle: InterfaceStyle {
        get { InterfaceStyle(rawValue: interfaceStyleRaw) ?? .system }
        set { interfaceStyleRaw = newValue.rawValue }
    }

    var glassStrength: GlassStrength {
        get { GlassStrength(light: glassLightStrength, dark: glassDarkStrength) }
        set {
            glassLightStrength = newValue.light
            glassDarkStrength = newValue.dark
        }
    }

    var sidebarBehavior: SidebarBehavior {
        get { SidebarBehavior(rawValue: sidebarBehaviorRaw) ?? .automatic }
        set { sidebarBehaviorRaw = newValue.rawValue }
    }

    var wiggleOnHover: Bool {
        get { wiggleOnHoverStorage }
        set { wiggleOnHoverStorage = newValue }
    }

    var tabBarMode: TabBarMode {
        get { TabBarMode(rawValue: tabBarModeRaw) ?? .iconsAndText }
        set { tabBarModeRaw = newValue.rawValue }
    }

    // Visible tabs management (comma-separated raw values)
    var visibleTabs: [RootTab] {
        get {
            visibleTabsRaw.split(separator: ",").compactMap { RootTab(rawValue: String($0)) }
        }
        set { visibleTabsRaw = newValue.map { $0.rawValue }.joined(separator: ",") }
    }

    // Planner-related settings
    var enableAIPlanner: Bool {
        get { enableAIPlannerStorage }
        set { enableAIPlannerStorage = newValue }
    }

    var plannerHorizon: String {
        get { plannerHorizonStorage }
        set { plannerHorizonStorage = newValue }
    }

    var enableFlashcards: Bool {
        get { enableFlashcardsStorage }
        set { enableFlashcardsStorage = newValue }
    }

    /// Derived convenience: visible tabs minus flashcards if disabled
    var effectiveVisibleTabs: [RootTab] {
        var tabs = visibleTabs
        if enableFlashcards {
            if !tabs.contains(.decks) { tabs.append(.decks) }
        } else {
            tabs.removeAll { $0 == .decks }
        }
        return tabs
    }

    var tabOrder: [RootTab] {
        get {
            var order = tabOrderRaw.split(separator: ",").compactMap { RootTab(rawValue: String($0)) }
            if enableFlashcards {
                if !order.contains(.decks) { order.append(.decks) }
            } else {
                order.removeAll { $0 == .decks }
            }
            return order
        }
        set { tabOrderRaw = newValue.map { $0.rawValue }.joined(separator: ",") }
    }

    var iconLabelMode: TabBarMode {
        get { tabBarMode }
        set { tabBarMode = newValue }
    }

    // Quick Actions
    var quickActions: [QuickAction] {
        get { quickActionsRaw.split(separator: ",").compactMap { QuickAction(rawValue: String($0)) } }
        set { quickActionsRaw = newValue.map { $0.rawValue }.joined(separator: ",") }
    }

    var enableGlassEffects: Bool {
        get { enableGlassEffectsStorage }
        set { enableGlassEffectsStorage = newValue }
    }

    var cardRadius: CardRadius {
        get { CardRadius(rawValue: cardRadiusRaw) ?? .medium }
        set { cardRadiusRaw = newValue.rawValue }
    }

    var cardCornerRadius: Double { cardRadius.value }

    var animationSoftness: Double {
        get { animationSoftnessStorage }
        set { animationSoftnessStorage = newValue }
    }

    var typographyMode: TypographyMode {
        get { TypographyMode(rawValue: typographyModeRaw) ?? .system }
        set { typographyModeRaw = newValue.rawValue }
    }

    var assignmentSwipeLeading: AssignmentSwipeAction {
        get { AssignmentSwipeAction(rawValue: assignmentSwipeLeadingRaw) ?? .complete }
        set { assignmentSwipeLeadingRaw = newValue.rawValue }
    }

    var assignmentSwipeTrailing: AssignmentSwipeAction {
        get { AssignmentSwipeAction(rawValue: assignmentSwipeTrailingRaw) ?? .delete }
        set { assignmentSwipeTrailingRaw = newValue.rawValue }
    }

    var devModeEnabled: Bool {
        get { devModeEnabledStorage }
        set { devModeEnabledStorage = newValue }
    }

    var devModeUILogging: Bool {
        get { devModeUILoggingStorage }
        set { devModeUILoggingStorage = newValue }
    }

    var devModeDataLogging: Bool {
        get { devModeDataLoggingStorage }
        set { devModeDataLoggingStorage = newValue }
    }

    var devModeSchedulerLogging: Bool {
        get { devModeSchedulerLoggingStorage }
        set { devModeSchedulerLoggingStorage = newValue }
    }

    var devModePerformance: Bool {
        get { devModePerformanceStorage }
        set { devModePerformanceStorage = newValue }
    }

    var enableICloudSync: Bool {
        get { enableICloudSyncStorage }
        set { enableICloudSyncStorage = newValue }
    }

    // New computed settings exposed to views
    var use24HourTime: Bool {
        get { use24HourTimeStorage }
        set { use24HourTimeStorage = newValue }
    }

    // Pomodoro values exposed to views
    var pomodoroFocusMinutes: Int {
        get { pomodoroFocusStorage }
        set { pomodoroFocusStorage = newValue }
    }

    var pomodoroShortBreakMinutes: Int {
        get { pomodoroShortBreakStorage }
        set { pomodoroShortBreakStorage = newValue }
    }

    var pomodoroLongBreakMinutes: Int {
        get { pomodoroLongBreakStorage }
        set { pomodoroLongBreakStorage = newValue }
    }

    // Event load thresholds exposed to views
    var loadLowThreshold: Int {
        get { loadLowThresholdStorage }
        set { loadLowThresholdStorage = newValue }
    }

    var loadMediumThreshold: Int {
        get { loadMediumThresholdStorage }
        set { loadMediumThresholdStorage = newValue }
    }

    var loadHighThreshold: Int {
        get { loadHighThresholdStorage }
        set { loadHighThresholdStorage = newValue }
    }

    var defaultWorkdayStart: DateComponents {
        get { DateComponents(hour: workdayStartHourStorage, minute: workdayStartMinuteStorage) }
        set {
            if let h = newValue.hour { workdayStartHourStorage = h }
            if let m = newValue.minute { workdayStartMinuteStorage = m }
        }
    }

    var defaultWorkdayEnd: DateComponents {
        get { DateComponents(hour: workdayEndHourStorage, minute: workdayEndMinuteStorage) }
        set {
            if let h = newValue.hour { workdayEndHourStorage = h }
            if let m = newValue.minute { workdayEndMinuteStorage = m }
        }
    }

    var showEnergyPanel: Bool {
        get { showEnergyPanelStorage }
        set { showEnergyPanelStorage = newValue }
    }

    var highContrastMode: Bool {
        get { highContrastModeStorage }
        set { highContrastModeStorage = newValue }
    }

    // General Settings
    var userName: String? {
        get { userNameStorage }
        set { userNameStorage = newValue }
    }

    var startOfWeek: String? {
        get { startOfWeekStorage }
        set { startOfWeekStorage = newValue }
    }

    var defaultView: String? {
        get { defaultViewStorage }
        set { defaultViewStorage = newValue }
    }

    // Interface Settings
    var reduceMotion: Bool {
        get { reduceMotionStorage }
        set { reduceMotionStorage = newValue }
    }

    var increaseTransparency: Bool {
        get { increaseTransparencyStorage }
        set { increaseTransparencyStorage = newValue }
    }

    var glassIntensity: Double? {
        get { glassIntensityStorage }
        set { glassIntensityStorage = newValue }
    }

    var accentColorName: String? {
        get { accentColorNameStorage }
        set { accentColorNameStorage = newValue }
    }

    var showSidebarByDefault: Bool {
        get { showSidebarByDefaultStorage }
        set { showSidebarByDefaultStorage = newValue }
    }

    var compactMode: Bool {
        get { compactModeStorage }
        set { compactModeStorage = newValue }
    }

    var showAnimations: Bool {
        get { showAnimationsStorage }
        set { showAnimationsStorage = newValue }
    }

    var enableHaptics: Bool {
        get { enableHapticsStorage }
        set { enableHapticsStorage = newValue }
    }

    var showTooltips: Bool {
        get { showTooltipsStorage }
        set { showTooltipsStorage = newValue }
    }

    // Profile/Study Coach Settings
    var defaultFocusDuration: Int? {
        get { defaultFocusDurationStorage }
        set { defaultFocusDurationStorage = newValue }
    }

    var defaultBreakDuration: Int? {
        get { defaultBreakDurationStorage }
        set { defaultBreakDurationStorage = newValue }
    }

    var defaultEnergyLevel: String? {
        get { defaultEnergyLevelStorage }
        set { defaultEnergyLevelStorage = newValue }
    }

    var enableStudyCoach: Bool {
        get { enableStudyCoachStorage }
        set { enableStudyCoachStorage = newValue }
    }

    var smartNotifications: Bool {
        get { smartNotificationsStorage }
        set { smartNotificationsStorage = newValue }
    }

    var autoScheduleBreaks: Bool {
        get { autoScheduleBreaksStorage }
        set { autoScheduleBreaksStorage = newValue }
    }

    var trackStudyHours: Bool {
        get { trackStudyHoursStorage }
        set { trackStudyHoursStorage = newValue }
    }

    var showProductivityInsights: Bool {
        get { showProductivityInsightsStorage }
        set { showProductivityInsightsStorage = newValue }
    }

    var weeklySummaryNotifications: Bool {
        get { weeklySummaryNotificationsStorage }
        set { weeklySummaryNotificationsStorage = newValue }
    }

    var preferMorningSessions: Bool {
        get { preferMorningSessionsStorage }
        set { preferMorningSessionsStorage = newValue }
    }

    var preferEveningSessions: Bool {
        get { preferEveningSessionsStorage }
        set { preferEveningSessionsStorage = newValue }
    }

    var enableDeepWorkMode: Bool {
        get { enableDeepWorkModeStorage }
        set { enableDeepWorkModeStorage = newValue }
    }

    // Convenience helpers to convert components to Date and back for bindings
    func date(from components: DateComponents) -> Date {
        Calendar.current.date(from: components) ?? Date()
    }

    func components(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: date)
    }

    func font(for style: AppTypography.TextStyle) -> Font {
        AppTypography.font(for: style, mode: typographyMode)
    }

    // Time formatting helpers that respect use24HourTime
    func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        // Use locale that uses 24-hour if requested
        if use24HourTime { f.locale = Locale(identifier: "en_GB") }
        return f.string(from: date)
    }

    func formattedTimeRange(start: Date, end: Date) -> String {
        "\(formattedTime(start)) - \(formattedTime(end))"
    }

    func glassOpacity(for scheme: ColorScheme) -> Double {
        guard enableGlassEffects else { return 0 }
        return scheme == .dark ? glassStrength.dark : glassStrength.light
    }

    // MARK: - Persistence helpers
    static func load() -> AppSettingsModel {
        let key = "roots.settings.appsettings"
        if let data = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(AppSettingsModel.self, from: data) {
                return decoded
            }
        }
        return AppSettingsModel()
    }

    func save() {
        let key = "roots.settings.appsettings"
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // Codable
    init() {}

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accentColorRaw, forKey: .accentColorRaw)
        try container.encode(customAccentEnabledStorage, forKey: .customAccentEnabledStorage)
        try container.encode(customAccentRed, forKey: .customAccentRed)
        try container.encode(customAccentGreen, forKey: .customAccentGreen)
        try container.encode(customAccentBlue, forKey: .customAccentBlue)
        try container.encode(customAccentAlpha, forKey: .customAccentAlpha)
        try container.encode(interfaceStyleRaw, forKey: .interfaceStyleRaw)
        try container.encode(glassLightStrength, forKey: .glassLightStrength)
        try container.encode(glassDarkStrength, forKey: .glassDarkStrength)
        try container.encode(sidebarBehaviorRaw, forKey: .sidebarBehaviorRaw)
        try container.encode(wiggleOnHoverStorage, forKey: .wiggleOnHoverStorage)
        try container.encode(tabBarModeRaw, forKey: .tabBarModeRaw)
        try container.encode(visibleTabsRaw, forKey: .visibleTabsRaw)
        try container.encode(tabOrderRaw, forKey: .tabOrderRaw)
        try container.encode(quickActionsRaw, forKey: .quickActionsRaw)
        try container.encode(enableGlassEffectsStorage, forKey: .enableGlassEffectsStorage)
        try container.encode(cardRadiusRaw, forKey: .cardRadiusRaw)
        try container.encode(animationSoftnessStorage, forKey: .animationSoftnessStorage)
        try container.encode(typographyModeRaw, forKey: .typographyModeRaw)
        try container.encode(devModeEnabledStorage, forKey: .devModeEnabledStorage)
        try container.encode(devModeUILoggingStorage, forKey: .devModeUILoggingStorage)
        try container.encode(devModeDataLoggingStorage, forKey: .devModeDataLoggingStorage)
        try container.encode(devModeSchedulerLoggingStorage, forKey: .devModeSchedulerLoggingStorage)
        try container.encode(devModePerformanceStorage, forKey: .devModePerformanceStorage)
        try container.encode(enableICloudSyncStorage, forKey: .enableICloudSyncStorage)
        try container.encode(enableAIPlannerStorage, forKey: .enableAIPlannerStorage)
        try container.encode(plannerHorizonStorage, forKey: .plannerHorizonStorage)
        try container.encode(enableFlashcardsStorage, forKey: .enableFlashcardsStorage)
        try container.encode(assignmentSwipeLeadingRaw, forKey: .assignmentSwipeLeadingRaw)
        try container.encode(assignmentSwipeTrailingRaw, forKey: .assignmentSwipeTrailingRaw)
    }

    required nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accentColorRaw = try container.decodeIfPresent(String.self, forKey: .accentColorRaw) ?? AppAccentColor.multicolor.rawValue
        customAccentEnabledStorage = try container.decodeIfPresent(Bool.self, forKey: .customAccentEnabledStorage) ?? false
        customAccentRed = try container.decodeIfPresent(Double.self, forKey: .customAccentRed) ?? 0
        customAccentGreen = try container.decodeIfPresent(Double.self, forKey: .customAccentGreen) ?? 122 / 255
        customAccentBlue = try container.decodeIfPresent(Double.self, forKey: .customAccentBlue) ?? 1
        customAccentAlpha = try container.decodeIfPresent(Double.self, forKey: .customAccentAlpha) ?? 1
        interfaceStyleRaw = try container.decodeIfPresent(String.self, forKey: .interfaceStyleRaw) ?? InterfaceStyle.system.rawValue
        glassLightStrength = try container.decodeIfPresent(Double.self, forKey: .glassLightStrength) ?? 0.33
        glassDarkStrength = try container.decodeIfPresent(Double.self, forKey: .glassDarkStrength) ?? 0.17
        sidebarBehaviorRaw = try container.decodeIfPresent(String.self, forKey: .sidebarBehaviorRaw) ?? SidebarBehavior.automatic.rawValue
        wiggleOnHoverStorage = try container.decodeIfPresent(Bool.self, forKey: .wiggleOnHoverStorage) ?? true
        tabBarModeRaw = try container.decodeIfPresent(String.self, forKey: .tabBarModeRaw) ?? TabBarMode.iconsAndText.rawValue
        visibleTabsRaw = try container.decodeIfPresent(String.self, forKey: .visibleTabsRaw) ?? "dashboard,calendar,planner,assignments,courses,grades,timer,decks"
        tabOrderRaw = try container.decodeIfPresent(String.self, forKey: .tabOrderRaw) ?? "dashboard,calendar,planner,assignments,courses,grades,timer,decks"
        quickActionsRaw = try container.decodeIfPresent(String.self, forKey: .quickActionsRaw) ?? "add_assignment,add_course,quick_note"
        enableGlassEffectsStorage = try container.decodeIfPresent(Bool.self, forKey: .enableGlassEffectsStorage) ?? true
        cardRadiusRaw = try container.decodeIfPresent(String.self, forKey: .cardRadiusRaw) ?? CardRadius.medium.rawValue
        animationSoftnessStorage = try container.decodeIfPresent(Double.self, forKey: .animationSoftnessStorage) ?? 0.42
        typographyModeRaw = try container.decodeIfPresent(String.self, forKey: .typographyModeRaw) ?? TypographyMode.system.rawValue
        devModeEnabledStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeEnabledStorage) ?? false
        devModeUILoggingStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeUILoggingStorage) ?? false
        devModeDataLoggingStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeDataLoggingStorage) ?? false
        devModeSchedulerLoggingStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeSchedulerLoggingStorage) ?? false
        devModePerformanceStorage = try container.decodeIfPresent(Bool.self, forKey: .devModePerformanceStorage) ?? false
        enableICloudSyncStorage = try container.decodeIfPresent(Bool.self, forKey: .enableICloudSyncStorage) ?? false
        enableFlashcardsStorage = try container.decodeIfPresent(Bool.self, forKey: .enableFlashcardsStorage) ?? true
        assignmentSwipeLeadingRaw = try container.decodeIfPresent(String.self, forKey: .assignmentSwipeLeadingRaw) ?? AssignmentSwipeAction.complete.rawValue
        assignmentSwipeTrailingRaw = try container.decodeIfPresent(String.self, forKey: .assignmentSwipeTrailingRaw) ?? AssignmentSwipeAction.delete.rawValue
    }

    func resetUserDefaults() {
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
        UserDefaults.standard.synchronize()
    }
}
