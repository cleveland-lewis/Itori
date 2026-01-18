import OSLog
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
        case .iconsOnly: "Icons"
        case .textOnly: "Text"
        case .iconsAndText: "Icons & Text"
        }
    }

    var systemImageName: String {
        switch self {
        case .iconsOnly: "square.grid.2x2"
        case .textOnly: "textformat"
        case .iconsAndText: "square.grid.2x2.and.square"
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
        #if os(macOS)
            case .system: return "Follow macOS"
        #else
            case .system: return "System"
        #endif
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
        case .automatic: "Auto-collapse"
        case .expanded: "Always expanded"
        case .compact: "Favor compact mode"
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
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var value: Double {
        switch self {
        case .small: 12
        case .medium: 18
        case .large: 26
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
        case .complete: "Complete / Undo"
        case .edit: "Edit"
        case .delete: "Delete"
        case .openDetail: "Open Details"
        }
    }

    var systemImage: String {
        switch self {
        case .complete: "checkmark.circle"
        case .edit: "pencil"
        case .delete: "trash"
        case .openDetail: "info.circle"
        }
    }
}

enum AppTypography {
    enum TextStyle {
        case headline, title2, body
    }

    static func font(for style: TextStyle, mode: TypographyMode) -> Font {
        switch mode {
        case .system:
            switch style {
            case .headline: .system(size: 24, weight: .semibold)
            case .title2: .system(size: 20, weight: .semibold)
            case .body: .system(size: 16, weight: .regular)
            }
        case .dos:
            switch style {
            case .headline: .custom("Menlo", size: 24).monospacedDigit()
            case .title2: .custom("Menlo", size: 20).monospacedDigit()
            case .body: .custom("Menlo", size: 16).monospacedDigit()
            }
        case .rounded:
            switch style {
            case .headline: .system(size: 24, weight: .semibold, design: .rounded)
            case .title2: .system(size: 20, weight: .semibold, design: .rounded)
            case .body: .system(size: 16, weight: .regular, design: .rounded)
            }
        }
    }
}

struct GlassStrength: Equatable {
    var light: Double
    var dark: Double
}

enum GradeScale: String, CaseIterable, Identifiable {
    case fourPoint = "4.0"
    case letter = "Letter"
    case percentage = "Percentage"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fourPoint: "4.0 Scale"
        case .letter: "Letter Grades (A-F)"
        case .percentage: "Percentage (%)"
        }
    }

    var description: String {
        switch self {
        case .fourPoint: "Display grades on a 4.0 GPA scale"
        case .letter: "Display grades as letter grades (A, B, C, etc.)"
        case .percentage: "Display grades as percentages"
        }
    }
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
        case .multicolor: "Multicolor (Default)"
        case .graphite: "Graphite"
        case .aqua: "Aqua"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        }
    }

    fileprivate var nsColor: NSColor {
        switch self {
        case .multicolor: NSColor.controlAccentColor
        case .graphite: NSColor.systemGray
        case .aqua: NSColor.systemTeal
        case .blue: NSColor.systemBlue
        case .purple: NSColor.systemPurple
        case .pink: NSColor.systemPink
        case .red: NSColor.systemRed
        case .orange: NSColor.systemOrange
        case .yellow: NSColor.systemYellow
        case .green: NSColor.systemGreen
        }
    }

    var color: Color {
        Color(nsColor: nsColor)
    }
}

final class AppSettingsModel: ObservableObject, Codable {
    /// Shared singleton used across the app. Loaded from persisted storage when available.
    private nonisolated(unsafe) static var _shared: AppSettingsModel?
    private static let lock = NSLock()

    nonisolated(unsafe) static var shared: AppSettingsModel {
        if let existing = _shared {
            return existing
        }
        lock.lock()
        defer { lock.unlock() }
        if let existing = _shared {
            return existing
        }
        let model = AppSettingsModel.load()
        print("[AppSettings] ✅ Singleton initialized successfully")
        _shared = model
        return model
    }

    // MARK: - Performance optimization

    private var saveDebouncer: Task<Void, Never>?

    // MARK: - Codable keys

    enum CodingKeys: String, CodingKey {
        case accentColorRaw, customAccentEnabledStorage, customAccentRed, customAccentGreen, customAccentBlue,
             customAccentAlpha
        case interfaceStyleRaw, glassLightStrength, glassDarkStrength, sidebarBehaviorRaw, wiggleOnHoverStorage
        case tabBarModeRaw, visibleTabsRaw, tabOrderRaw, quickActionsRaw, enableGlassEffectsStorage
        case cardRadiusRaw, animationSoftnessStorage, typographyModeRaw
        case devModeEnabledStorage, devModeUILoggingStorage, devModeDataLoggingStorage, devModeSchedulerLoggingStorage,
             devModePerformanceStorage
        case enableICloudSyncStorage
        case enableCoreDataSyncStorage
        case suppressICloudRestoreStorage
        case enableSpotlightIndexingStorage
        case enableRaycastIntegrationStorage
        case enableAIPlannerStorage
        case plannerHorizonStorage
        case enableFlashcardsStorage
        case assignmentSwipeLeadingRaw
        case assignmentSwipeTrailingRaw
        case pomodoroFocusStorage
        case pomodoroShortBreakStorage
        case pomodoroLongBreakStorage
        case pomodoroIterationsStorage
        case timerDurationStorage
        case longBreakCadenceStorage
        case notificationsEnabledStorage
        case assignmentRemindersEnabledStorage
        case dailyOverviewEnabledStorage
        case affirmationsEnabledStorage
        case timerAlertsEnabledStorage
        case pomodoroAlertsEnabledStorage
        case alarmKitTimersEnabledStorage
        case assignmentLeadTimeStorage
        case dailyOverviewTimeStorage
        case dailyOverviewIncludeTasksStorage
        case dailyOverviewIncludeEventsStorage
        case dailyOverviewIncludeYesterdayCompletedStorage
        case dailyOverviewIncludeYesterdayStudyTimeStorage
        case dailyOverviewIncludeMotivationStorage
        case practiceTestTimeMultiplierStorage
        case showOnlySchoolCalendarStorage
        case lockCalendarPickerToSchoolStorage
        case selectedSchoolCalendarID
        case starredTabsRaw
        case aiModeRaw
        case byoProviderConfigData
        case localBackendTypeRaw
        case localModelDownloadedMacOS
        case localModelDownloadediOS
        // aiEnabledStorage now uses @AppStorage, removed from Codable
        case onboardingStateData
        case compactModeStorage
        case largeTapTargetsStorage
        case showSidebarByDefaultStorage
        case reduceMotionStorage
        case increaseContrastStorage
        case reduceTransparencyStorage
        case glassIntensityStorage
        case accentColorNameStorage
        case showAnimationsStorage
        case enableHapticsStorage
        case showTooltipsStorage
        case showSampleDataStorage
        case defaultEnergyLevelStorage
        case energySelectionConfirmedStorage
        case workdayWeekdaysStorage
        case gradeScaleRaw
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
        static let accentColor = "Itori.settings.accentColor"
        static let customAccentEnabled = "Itori.settings.customAccentEnabled"
        static let customAccentRed = "Itori.settings.customAccent.red"
        static let customAccentGreen = "Itori.settings.customAccent.green"
        static let customAccentBlue = "Itori.settings.customAccent.blue"
        static let customAccentAlpha = "Itori.settings.customAccent.alpha"
        static let interfaceStyle = "Itori.settings.interfaceStyle"
        static let glassLightStrength = "Itori.settings.glass.light"
        static let glassDarkStrength = "Itori.settings.glass.dark"
        static let sidebarBehavior = "Itori.settings.sidebarBehavior"
        static let wiggleOnHover = "Itori.settings.wiggleOnHover"
        static let tabBarMode = "Itori.settings.tabBarMode"
        static let visibleTabs = "Itori.settings.visibleTabs"
        static let tabOrder = "Itori.settings.tabOrder"
        static let quickActions = "Itori.settings.quickActions"
        static let enableGlassEffects = "Itori.settings.enableGlassEffects"
        static let cardRadius = "Itori.settings.cardRadius"
        static let animationSoftness = "Itori.settings.animationSoftness"
        static let typographyMode = "Itori.settings.typographyMode"
        static let devModeEnabled = "devMode.enabled"
        static let devModeUILogging = "devMode.uiLogging"
        static let devModeDataLogging = "devMode.dataLogging"
        static let devModeSchedulerLogging = "devMode.schedulerLogging"
        static let devModePerformance = "devMode.performance"

        // New keys for global settings
        static let use24HourTime = "Itori.settings.use24HourTime"
        static let workdayStartHour = "Itori.settings.workday.start.hour"
        static let workdayStartMinute = "Itori.settings.workday.start.minute"
        static let workdayEndHour = "Itori.settings.workday.end.hour"
        static let workdayEndMinute = "Itori.settings.workday.end.minute"
        static let workdayWeekdays = "Itori.settings.workday.weekdays"
        static let showEnergyPanel = "Itori.settings.showEnergyPanel"
        static let highContrastMode = "Itori.settings.highContrastMode"
        static let enableAIPlanner = "Itori.settings.enableAIPlanner"
        static let plannerHorizon = "Itori.settings.plannerHorizon"
        static let hideGPAOnDashboard = "Itori.settings.hideGPAOnDashboard"
    }

    // Backing storage - migrate to UserDefaults-backed values to persist across launches
    var accentColorRaw: String = AppAccentColor.blue.rawValue
    var customAccentEnabledStorage: Bool = false
    var customAccentRed: Double = 0
    var customAccentGreen: Double = 122 / 255
    var customAccentBlue: Double = 1
    var customAccentAlpha: Double = 1
    var interfaceStyleRaw: String = InterfaceStyle.system.rawValue
    var glassLightStrength: Double = 0.33
    var glassDarkStrength: Double = 0.17
    var sidebarBehaviorRaw: String = SidebarBehavior.automatic.rawValue
    var wiggleOnHoverStorage: Bool = true
    var tabBarModeRaw: String = TabBarMode.iconsAndText.rawValue
    var visibleTabsRaw: String = "dashboard,planner,assignments,courses,grades,calendar"
    var tabOrderRaw: String = "dashboard,planner,assignments,courses,grades,calendar"
    var quickActionsRaw: String = "add_assignment,add_course,quick_note"
    var enableGlassEffectsStorage: Bool = true
    var gradeScaleRaw: String = GradeScale.fourPoint.rawValue
    var cardRadiusRaw: String = CardRadius.medium.rawValue
    var animationSoftnessStorage: Double = 0.42
    var typographyModeRaw: String = TypographyMode.system.rawValue
    @AppStorage(Keys.devModeEnabled) var devModeEnabledStorage: Bool = false
    @AppStorage(Keys.devModeUILogging) var devModeUILoggingStorage: Bool = true
    @AppStorage(Keys.devModeDataLogging) var devModeDataLoggingStorage: Bool = true
    @AppStorage(Keys.devModeSchedulerLogging) var devModeSchedulerLoggingStorage: Bool = true
    @AppStorage(Keys.devModePerformance) var devModePerformanceStorage: Bool = true
    var enableICloudSyncStorage: Bool = true
    var enableCoreDataSyncStorage: Bool = false
    @AppStorage("Itori.settings.suppressICloudRestore") var suppressICloudRestoreStorage: Bool = false
    var enableSpotlightIndexingStorage: Bool = false
    var enableRaycastIntegrationStorage: Bool = false

    // Layout preferences (iOS/iPad)
    @AppStorage("Itori.settings.compactMode") var compactModeStorage: Bool = false
    @AppStorage("Itori.settings.largeTapTargets") var largeTapTargetsStorage: Bool = false
    @AppStorage("Itori.settings.showSidebarByDefault") var showSidebarByDefaultStorage: Bool = true

    // New UserDefaults-backed properties
    @AppStorage(Keys.use24HourTime) var use24HourTimeStorage: Bool = false
    @AppStorage(Keys.workdayStartHour) var workdayStartHourStorage: Int = 8
    @AppStorage(Keys.workdayStartMinute) var workdayStartMinuteStorage: Int = 0
    @AppStorage(Keys.workdayEndHour) var workdayEndHourStorage: Int = 22
    @AppStorage(Keys.workdayEndMinute) var workdayEndMinuteStorage: Int = 0
    @AppStorage(Keys.workdayWeekdays) var workdayWeekdaysStorage: String = "2,3,4,5,6"
    @AppStorage(Keys.showEnergyPanel) var showEnergyPanelStorage: Bool = true
    @AppStorage(Keys.highContrastMode) var highContrastModeStorage: Bool = false
    @AppStorage(Keys.enableAIPlanner) var enableAIPlannerStorage: Bool = false
    @AppStorage(Keys.plannerHorizon) var plannerHorizonStorage: String = "2w"
    @AppStorage("Itori.settings.enableFlashcards") var enableFlashcardsStorage: Bool = true
    @AppStorage("Itori.settings.assignmentSwipeLeading") var assignmentSwipeLeadingRaw: String = AssignmentSwipeAction
        .complete.rawValue
    @AppStorage("Itori.settings.assignmentSwipeTrailing") var assignmentSwipeTrailingRaw: String = AssignmentSwipeAction
        .delete.rawValue

    // General Settings
    @AppStorage("Itori.settings.startOfWeek") var startOfWeekStorage: String = "Sunday"
    @AppStorage("Itori.settings.defaultView") var defaultViewStorage: String = "Dashboard"
    @AppStorage("Itori.settings.isSchoolMode") var isSchoolModeStorage: Bool =
        true // true = School Mode, false = Self-Study Mode

    // Learning Data
    @AppStorage("Itori.learning.categoryDurations") var categoryDurationsData: Data = .init()

    // Interface Settings
    @AppStorage("Itori.settings.reduceMotion") var reduceMotionStorage: Bool = false
    @AppStorage("Itori.settings.increaseTransparency") var increaseTransparencyStorage: Bool = false
    @AppStorage("Itori.settings.increaseContrast") var increaseContrastStorage: Bool = false
    @AppStorage("Itori.settings.reduceTransparency") var reduceTransparencyStorage: Bool = false
    @AppStorage("Itori.settings.glassIntensity") var glassIntensityStorage: Double = 0.5
    @AppStorage("Itori.settings.accentColorName") var accentColorNameStorage: String = "Blue"
    @AppStorage("Itori.settings.showAnimations") var showAnimationsStorage: Bool = true
    @AppStorage("Itori.settings.enableHaptics") var enableHapticsStorage: Bool = true
    @AppStorage("Itori.settings.showTooltips") var showTooltipsStorage: Bool = true
    @AppStorage(Keys.hideGPAOnDashboard) var hideGPAOnDashboardStorage: Bool = false
    @AppStorage("Itori.settings.showSampleData") var showSampleDataStorage: Bool = false

    // Profile/Study Coach Settings
    @AppStorage("Itori.settings.defaultFocusDuration") var defaultFocusDurationStorage: Int = 25
    @AppStorage("Itori.settings.defaultBreakDuration") var defaultBreakDurationStorage: Int = 5
    @AppStorage("Itori.settings.defaultEnergyLevel") var defaultEnergyLevelStorage: String = "Medium"
    @AppStorage("Itori.settings.energySelectionConfirmed") var energySelectionConfirmedStorage: Bool = false
    @AppStorage(
        "Itori.settings.energySelectionResetDateTimestamp"
    ) private var energySelectionResetDateTimestamp: Double =
        Date.distantPast.timeIntervalSince1970

    var energySelectionResetDate: Date {
        get { Date(timeIntervalSince1970: energySelectionResetDateTimestamp) }
        set { energySelectionResetDateTimestamp = newValue.timeIntervalSince1970 }
    }

    @AppStorage("Itori.settings.enableStudyCoach") var enableStudyCoachStorage: Bool = true
    @AppStorage("Itori.settings.smartNotifications") var smartNotificationsStorage: Bool = true
    @AppStorage("Itori.settings.autoScheduleBreaks") var autoScheduleBreaksStorage: Bool = true
    @AppStorage("Itori.settings.trackStudyHours") var trackStudyHoursStorage: Bool = true
    @AppStorage("Itori.settings.showProductivityInsights") var showProductivityInsightsStorage: Bool = true
    @AppStorage("Itori.settings.weeklySummaryNotifications") var weeklySummaryNotificationsStorage: Bool = false
    @AppStorage("Itori.settings.preferMorningSessions") var preferMorningSessionsStorage: Bool = false
    @AppStorage("Itori.settings.preferEveningSessions") var preferEveningSessionsStorage: Bool = false
    @AppStorage("Itori.settings.enableDeepWorkMode") var enableDeepWorkModeStorage: Bool = false

    // Pomodoro defaults (migrated here)
    @AppStorage("Itori.settings.pomodoroFocus") var pomodoroFocusStorage: Int = 25
    @AppStorage("Itori.settings.pomodoroShortBreak") var pomodoroShortBreakStorage: Int = 5
    @AppStorage("Itori.settings.pomodoroLongBreak") var pomodoroLongBreakStorage: Int = 15
    @AppStorage("Itori.settings.pomodoroIterations") var pomodoroIterationsStorage: Int = 4
    @AppStorage("Itori.settings.timerDurationMinutes") var timerDurationStorage: Int = 30
    @AppStorage("Itori.settings.longBreakCadence") var longBreakCadenceStorage: Int = 4
    @AppStorage("Itori.settings.timerAppearance") var timerAppearanceStorage: String = "analog"

    // Auto-reschedule settings
    @AppStorage("Itori.settings.enableAutoReschedule") var enableAutoReschedule: Bool = true
    @AppStorage("Itori.settings.autoRescheduleCheckInterval") var autoRescheduleCheckInterval: Int = 5 // minutes
    @AppStorage("Itori.settings.autoReschedulePushLowerPriority") var autoReschedulePushLowerPriority: Bool = true
    @AppStorage("Itori.settings.autoRescheduleMaxPushCount") var autoRescheduleMaxPushCount: Int = 2

    // Notification settings
    @AppStorage("Itori.settings.notificationsEnabled") var notificationsEnabledStorage: Bool = false
    @AppStorage("Itori.settings.assignmentRemindersEnabled") var assignmentRemindersEnabledStorage: Bool = true
    @AppStorage("Itori.settings.dailyOverviewEnabled") var dailyOverviewEnabledStorage: Bool = false
    @AppStorage("Itori.settings.affirmationsEnabled") var affirmationsEnabledStorage: Bool = false
    @AppStorage("Itori.settings.timerAlertsEnabled") var timerAlertsEnabledStorage: Bool = true
    @AppStorage("Itori.settings.pomodoroAlertsEnabled") var pomodoroAlertsEnabledStorage: Bool = true
    @AppStorage("Itori.settings.alarmKitTimersEnabled") var alarmKitTimersEnabledStorage: Bool = true
    @AppStorage("Itori.settings.assignmentLeadTime") var assignmentLeadTimeStorage: Double = 3600 // 1 hour in seconds

    // Daily overview content toggles
    @AppStorage("Itori.settings.dailyOverviewIncludeTasks") var dailyOverviewIncludeTasksStorage: Bool = true
    @AppStorage("Itori.settings.dailyOverviewIncludeEvents") var dailyOverviewIncludeEventsStorage: Bool = true
    @AppStorage(
        "Itori.settings.dailyOverviewIncludeYesterdayCompleted"
    ) var dailyOverviewIncludeYesterdayCompletedStorage: Bool =
        true
    @AppStorage(
        "Itori.settings.dailyOverviewIncludeYesterdayStudyTime"
    ) var dailyOverviewIncludeYesterdayStudyTimeStorage: Bool =
        true
    @AppStorage("Itori.settings.dailyOverviewIncludeMotivation") var dailyOverviewIncludeMotivationStorage: Bool = true
    @AppStorage("Itori.settings.practiceTestTimeMultiplier") var practiceTestTimeMultiplierStorage: Double = 1.0

    // Calendar UI filter setting
    @AppStorage("Itori.settings.showOnlySchoolCalendar") var showOnlySchoolCalendarStorage: Bool = true

    // Calendar picker admin-lock setting
    @AppStorage("Itori.settings.lockCalendarPickerToSchool") var lockCalendarPickerToSchoolStorage: Bool = false

    // Selected school calendar identifier
    @AppStorage("Itori.settings.selectedSchoolCalendarID") var selectedSchoolCalendarID: String = ""

    // Calendar access granted
    @AppStorage("Itori.settings.calendarAccessGranted") var calendarAccessGranted: Bool = true

    // Starred tabs for iOS (max 5) - stored as comma-separated string
    @AppStorage("Itori.settings.starredTabsString") private var starredTabsString: String = "dashboard,courses,assignments,calendar,grades"

    var starredTabsRaw: [String] {
        get {
            starredTabsString.split(separator: ",").map(String.init)
        }
        set {
            starredTabsString = newValue.joined(separator: ",")
        }
    }

    // Daily overview time (stored as seconds since midnight)
    @AppStorage("Itori.settings.dailyOverviewTimeSeconds") private var dailyOverviewTimeSecondsStorage: Int =
        28800 // 8:00 AM

    var dailyOverviewTimeStorage: Date {
        get {
            let seconds = dailyOverviewTimeSecondsStorage
            let hour = seconds / 3600
            let minute = (seconds % 3600) / 60
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            let hour = components.hour ?? 8
            let minute = components.minute ?? 0
            dailyOverviewTimeSecondsStorage = hour * 3600 + minute * 60
        }
    }

    // AI Settings
    @AppStorage("Itori.settings.aiEnabled") var aiEnabledStorage: Bool =
        false // Global AI kill switch - DISABLED BY DEFAULT per Issue #175.H
    var aiModeRaw: String = "auto"
    var byoProviderConfigData: Data? = nil
    var localBackendTypeRaw: String = "mlx" // Default to MLX for macOS
    var localModelDownloadedMacOS: Bool = false
    var localModelDownloadediOS: Bool = false

    // Onboarding state (Issue #208)
    var onboardingStateData: Data? = nil

    // Event load thresholds (persisted)
    var loadLowThresholdStorage: Int = 1
    var loadMediumThresholdStorage: Int = 3
    var loadHighThresholdStorage: Int = 5

    // Category effort profiles (user-tunable)
    struct CategoryEffortProfileStorage: Codable, Equatable {
        var baseMinutes: Int
        var minSessions: Int
        var spreadDaysBeforeDue: Int
        var sessionBiasRaw: String
    }

    var categoryEffortProfilesStorage: [String: CategoryEffortProfileStorage] = [:]

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

    var gradeScale: GradeScale {
        get { GradeScale(rawValue: gradeScaleRaw) ?? .fourPoint }
        set {
            gradeScaleRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var interfaceStyle: InterfaceStyle {
        get { InterfaceStyle(rawValue: interfaceStyleRaw) ?? .system }
        set {
            interfaceStyleRaw = newValue.rawValue
            objectWillChange.send()
        }
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
        set { visibleTabsRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }

    // Planner-related settings
    var enableAIPlanner: Bool {
        get { enableAIPlannerStorage }
        set { enableAIPlannerStorage = newValue }
    }

    var plannerHorizon: String {
        get { plannerHorizonStorage }
        set {
            plannerHorizonStorage = newValue
            // Notify that scheduler should update
            NotificationCenter.default.post(name: .plannerHorizonDidChange, object: nil)
        }
    }

    var enableFlashcards: Bool {
        get { enableFlashcardsStorage }
        set {
            enableFlashcardsStorage = newValue
            if !newValue {
                var tabs = starredTabsRaw
                tabs.removeAll { $0 == RootTab.flashcards.rawValue }
                starredTabsRaw = tabs
            }
        }
    }

    var practiceTestTimeMultiplier: Double {
        get { practiceTestTimeMultiplierStorage }
        set { practiceTestTimeMultiplierStorage = newValue }
    }

    /// Derived convenience: visible tabs filtered by registry
    var effectiveVisibleTabs: [RootTab] {
        visibleTabs.filter { TabRegistry.definition(for: $0) != nil }
    }

    var tabOrder: [RootTab] {
        get {
            let order = tabOrderRaw.split(separator: ",").compactMap { RootTab(rawValue: String($0)) }
            return order.filter { TabRegistry.definition(for: $0) != nil }
        }
        set { tabOrderRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }

    var iconLabelMode: TabBarMode {
        get { tabBarMode }
        set { tabBarMode = newValue }
    }

    // Quick Actions
    var quickActions: [QuickAction] {
        get { quickActionsRaw.split(separator: ",").compactMap { QuickAction(rawValue: String($0)) } }
        set { quickActionsRaw = newValue.map(\.rawValue).joined(separator: ",") }
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
        set {
            let wasEnabled = enableICloudSyncStorage
            enableICloudSyncStorage = newValue
            if newValue && !wasEnabled && suppressICloudRestoreStorage {
                suppressICloudRestoreStorage = false
            }
        }
    }

    var enableCoreDataSync: Bool {
        get { enableCoreDataSyncStorage }
        set {
            enableCoreDataSyncStorage = newValue
            NotificationCenter.default.post(name: .coreDataSyncSettingChanged, object: newValue)
        }
    }

    var suppressICloudRestore: Bool {
        get { suppressICloudRestoreStorage }
        set { suppressICloudRestoreStorage = newValue }
    }

    var enableSpotlightIndexing: Bool {
        get { enableSpotlightIndexingStorage }
        set { enableSpotlightIndexingStorage = newValue }
    }

    var enableRaycastIntegration: Bool {
        get { enableRaycastIntegrationStorage }
        set { enableRaycastIntegrationStorage = newValue }
    }

    // Layout settings (iOS/iPad)
    var compactMode: Bool {
        get { compactModeStorage }
        set { compactModeStorage = newValue }
    }

    var largeTapTargets: Bool {
        get { largeTapTargetsStorage }
        set { largeTapTargetsStorage = newValue }
    }

    var showSidebarByDefault: Bool {
        get { showSidebarByDefaultStorage }
        set { showSidebarByDefaultStorage = newValue }
    }

    // Starred tabs (iOS tab bar, max 5)
    var starredTabs: [RootTab] {
        get {
            var tabs = starredTabsRaw.compactMap { RootTab(rawValue: $0) }
            tabs = tabs.filter { TabRegistry.definition(for: $0) != nil }
            // Limit to 5
            return Array(tabs.prefix(5))
        }
        set {
            var tabs = newValue
            tabs = tabs.filter { TabRegistry.definition(for: $0) != nil }
            // Limit to 5
            tabs = Array(tabs.prefix(5))
            starredTabsRaw = tabs.map(\.rawValue)
        }
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

    var pomodoroIterations: Int {
        get { pomodoroIterationsStorage }
        set {
            objectWillChange.send()
            pomodoroIterationsStorage = newValue
        }
    }

    var timerDurationMinutes: Int {
        get { timerDurationStorage }
        set { timerDurationStorage = newValue }
    }

    var timerAppearance: String {
        get { timerAppearanceStorage }
        set { timerAppearanceStorage = newValue }
    }

    var isTimerAnalog: Bool {
        timerAppearance == "analog"
    }

    var longBreakCadence: Int {
        get { longBreakCadenceStorage }
        set { longBreakCadenceStorage = newValue }
    }

    // Notification settings exposed to views
    var notificationsEnabled: Bool {
        get { notificationsEnabledStorage }
        set { notificationsEnabledStorage = newValue }
    }

    var assignmentRemindersEnabled: Bool {
        get { assignmentRemindersEnabledStorage }
        set { assignmentRemindersEnabledStorage = newValue }
    }

    var dailyOverviewEnabled: Bool {
        get { dailyOverviewEnabledStorage }
        set { dailyOverviewEnabledStorage = newValue }
    }

    var affirmationsEnabled: Bool {
        get { affirmationsEnabledStorage }
        set { affirmationsEnabledStorage = newValue }
    }

    var timerAlertsEnabled: Bool {
        get { timerAlertsEnabledStorage }
        set { timerAlertsEnabledStorage = newValue }
    }

    var pomodoroAlertsEnabled: Bool {
        get { pomodoroAlertsEnabledStorage }
        set { pomodoroAlertsEnabledStorage = newValue }
    }

    var alarmKitTimersEnabled: Bool {
        get { alarmKitTimersEnabledStorage }
        set { alarmKitTimersEnabledStorage = newValue }
    }

    var assignmentLeadTime: TimeInterval {
        get { assignmentLeadTimeStorage }
        set { assignmentLeadTimeStorage = newValue }
    }

    var dailyOverviewTime: Date {
        get { dailyOverviewTimeStorage }
        set { dailyOverviewTimeStorage = newValue }
    }

    var dailyOverviewIncludeTasks: Bool {
        get { dailyOverviewIncludeTasksStorage }
        set { dailyOverviewIncludeTasksStorage = newValue }
    }

    var dailyOverviewIncludeEvents: Bool {
        get { dailyOverviewIncludeEventsStorage }
        set { dailyOverviewIncludeEventsStorage = newValue }
    }

    var dailyOverviewIncludeYesterdayCompleted: Bool {
        get { dailyOverviewIncludeYesterdayCompletedStorage }
        set { dailyOverviewIncludeYesterdayCompletedStorage = newValue }
    }

    var dailyOverviewIncludeYesterdayStudyTime: Bool {
        get { dailyOverviewIncludeYesterdayStudyTimeStorage }
        set { dailyOverviewIncludeYesterdayStudyTimeStorage = newValue }
    }

    var dailyOverviewIncludeMotivation: Bool {
        get { dailyOverviewIncludeMotivationStorage }
        set { dailyOverviewIncludeMotivationStorage = newValue }
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

    // Calendar UI filter setting exposed to views
    var showOnlySchoolCalendar: Bool {
        get { showOnlySchoolCalendarStorage }
        set { showOnlySchoolCalendarStorage = newValue }
    }

    // Calendar picker admin-lock setting exposed to views
    var lockCalendarPickerToSchool: Bool {
        get { lockCalendarPickerToSchoolStorage }
        set { lockCalendarPickerToSchoolStorage = newValue }
    }

    var defaultWorkdayStart: DateComponents {
        get {
            // Try to get from iCloud first if sync is enabled
            if enableICloudSync {
                if let hourCloud = NSUbiquitousKeyValueStore.default
                    .object(forKey: "Itori.settings.workday.startHour") as? Int,
                    let minuteCloud = NSUbiquitousKeyValueStore.default
                    .object(forKey: "Itori.settings.workday.startMinute") as? Int
                {
                    return DateComponents(hour: hourCloud, minute: minuteCloud)
                }
            }
            return DateComponents(hour: workdayStartHourStorage, minute: workdayStartMinuteStorage)
        }
        set {
            if let h = newValue.hour {
                workdayStartHourStorage = h
                if enableICloudSync {
                    NSUbiquitousKeyValueStore.default.set(h, forKey: "Itori.settings.workday.startHour")
                }
            }
            if let m = newValue.minute {
                workdayStartMinuteStorage = m
                if enableICloudSync {
                    NSUbiquitousKeyValueStore.default.set(m, forKey: "Itori.settings.workday.startMinute")
                }
            }
            if enableICloudSync {
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }

    var defaultWorkdayEnd: DateComponents {
        get {
            // Try to get from iCloud first if sync is enabled
            if enableICloudSync {
                if let hourCloud = NSUbiquitousKeyValueStore.default
                    .object(forKey: "Itori.settings.workday.endHour") as? Int,
                    let minuteCloud = NSUbiquitousKeyValueStore.default
                    .object(forKey: "Itori.settings.workday.endMinute") as? Int
                {
                    return DateComponents(hour: hourCloud, minute: minuteCloud)
                }
            }
            return DateComponents(hour: workdayEndHourStorage, minute: workdayEndMinuteStorage)
        }
        set {
            if let h = newValue.hour {
                workdayEndHourStorage = h
                if enableICloudSync {
                    NSUbiquitousKeyValueStore.default.set(h, forKey: "Itori.settings.workday.endHour")
                }
            }
            if let m = newValue.minute {
                workdayEndMinuteStorage = m
                if enableICloudSync {
                    NSUbiquitousKeyValueStore.default.set(m, forKey: "Itori.settings.workday.endMinute")
                }
            }
            if enableICloudSync {
                NSUbiquitousKeyValueStore.default.synchronize()
            }
        }
    }

    var workdayWeekdays: [Int] {
        get {
            // Try to get from iCloud first if sync is enabled
            if enableICloudSync {
                if let cloudValue = NSUbiquitousKeyValueStore.default
                    .string(forKey: "Itori.settings.workday.weekdays")
                {
                    let parsed = cloudValue
                        .split(separator: ",")
                        .compactMap { Int($0) }
                        .filter { (1 ... 7).contains($0) }
                    let unique = Array(Set(parsed)).sorted()
                    if !unique.isEmpty {
                        return unique
                    }
                }
            }

            let parsed = workdayWeekdaysStorage
                .split(separator: ",")
                .compactMap { Int($0) }
                .filter { (1 ... 7).contains($0) }
            let unique = Array(Set(parsed)).sorted()
            return unique.isEmpty ? [2, 3, 4, 5, 6] : unique
        }
        set {
            let sanitized = Array(Set(newValue.filter { (1 ... 7).contains($0) })).sorted()
            let value = (sanitized.isEmpty ? [2, 3, 4, 5, 6] : sanitized)
                .map(String.init)
                .joined(separator: ",")
            workdayWeekdaysStorage = value

            // Sync to iCloud if enabled
            if enableICloudSync {
                NSUbiquitousKeyValueStore.default.set(value, forKey: "Itori.settings.workday.weekdays")
                NSUbiquitousKeyValueStore.default.synchronize()
            }
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

    var startOfWeek: String {
        get { startOfWeekStorage }
        set { startOfWeekStorage = newValue }
    }

    var defaultView: String {
        get { defaultViewStorage }
        set { defaultViewStorage = newValue }
    }

    var isSchoolMode: Bool {
        get { isSchoolModeStorage }
        set { isSchoolModeStorage = newValue }
    }

    // Learning Data
    var categoryLearningData: [String: CategoryLearningData] {
        get {
            guard let decoded = try? JSONDecoder().decode(
                [String: CategoryLearningData].self,
                from: categoryDurationsData
            ) else { return [:] }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                categoryDurationsData = encoded
            }
        }
    }

    func recordTaskCompletion(courseId: UUID, category: AssignmentCategory, actualMinutes: Int) {
        let key = DurationEstimator.learningKey(courseId: courseId, category: category)
        var data = categoryLearningData
        var learning = data[key] ?? CategoryLearningData(
            courseId: courseId,
            category: category
        )

        learning.record(actualMinutes: actualMinutes)
        data[key] = learning
        categoryLearningData = data
    }

    // Interface Settings
    var reduceMotion: Bool {
        get { reduceMotionStorage }
        set { reduceMotionStorage = newValue }
    }

    var increaseContrast: Bool {
        get { increaseContrastStorage }
        set { increaseContrastStorage = newValue }
    }

    var reduceTransparency: Bool {
        get { reduceTransparencyStorage }
        set { reduceTransparencyStorage = newValue }
    }

    var increaseTransparency: Bool {
        get { increaseTransparencyStorage }
        set { increaseTransparencyStorage = newValue }
    }

    var glassIntensity: Double {
        get { glassIntensityStorage }
        set { glassIntensityStorage = newValue }
    }

    var accentColorName: String {
        get { accentColorNameStorage }
        set { accentColorNameStorage = newValue }
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

    var hideGPAOnDashboard: Bool {
        get { hideGPAOnDashboardStorage }
        set { hideGPAOnDashboardStorage = newValue }
    }

    var showSampleData: Bool {
        get { showSampleDataStorage }
        set { showSampleDataStorage = newValue }
    }

    // Profile/Study Coach Settings
    var defaultFocusDuration: Int {
        get { defaultFocusDurationStorage }
        set { defaultFocusDurationStorage = newValue }
    }

    var defaultBreakDuration: Int {
        get { defaultBreakDurationStorage }
        set { defaultBreakDurationStorage = newValue }
    }

    var defaultEnergyLevel: String {
        get {
            // Try to get from iCloud first if sync is enabled
            if enableICloudSync {
                let cloudValue = NSUbiquitousKeyValueStore.default.string(forKey: "Itori.settings.defaultEnergyLevel")
                if let cloudValue, !cloudValue.isEmpty {
                    LOG_DEV(
                        .debug,
                        "EnergySync",
                        "Reading energy from iCloud",
                        metadata: ["cloudValue": cloudValue, "localValue": defaultEnergyLevelStorage]
                    )
                    // Update local if different
                    if cloudValue != defaultEnergyLevelStorage {
                        LOG_DEV(
                            .info,
                            "EnergySync",
                            "Syncing iCloud value to local storage",
                            metadata: ["from": defaultEnergyLevelStorage, "to": cloudValue]
                        )
                        defaultEnergyLevelStorage = cloudValue
                    }
                    return cloudValue
                }
                LOG_DEV(
                    .debug,
                    "EnergySync",
                    "No iCloud value found, using local",
                    metadata: ["localValue": defaultEnergyLevelStorage]
                )
            } else {
                LOG_DEV(
                    .debug,
                    "EnergySync",
                    "iCloud sync disabled, using local only",
                    metadata: ["localValue": defaultEnergyLevelStorage]
                )
            }
            return defaultEnergyLevelStorage
        }
        set {
            LOG_DEV(
                .info,
                "EnergySync",
                "Setting energy level",
                metadata: [
                    "oldValue": defaultEnergyLevelStorage,
                    "newValue": newValue,
                    "iCloudEnabled": "\(enableICloudSync)"
                ]
            )
            defaultEnergyLevelStorage = newValue
            // Sync to iCloud if enabled
            if enableICloudSync {
                LOG_DEV(.debug, "EnergySync", "Writing energy to iCloud", metadata: ["value": newValue])
                NSUbiquitousKeyValueStore.default.set(newValue, forKey: "Itori.settings.defaultEnergyLevel")
                let syncResult = NSUbiquitousKeyValueStore.default.synchronize()
                LOG_DEV(.debug, "EnergySync", "iCloud synchronize() called", metadata: ["success": "\(syncResult)"])
            } else {
                LOG_DEV(.debug, "EnergySync", "Skipped iCloud write (sync disabled)")
            }
            NotificationCenter.default.post(name: .energySettingsDidChange, object: nil)
        }
    }

    var energySelectionConfirmed: Bool {
        get {
            // Try to get from iCloud first if sync is enabled
            if enableICloudSync {
                let cloudValue = NSUbiquitousKeyValueStore.default
                    .object(forKey: "Itori.settings.energySelectionConfirmed") as? Bool
                if let cloudValue {
                    LOG_DEV(
                        .debug,
                        "EnergySync",
                        "Reading energySelectionConfirmed from iCloud",
                        metadata: ["cloudValue": "\(cloudValue)", "localValue": "\(energySelectionConfirmedStorage)"]
                    )
                    // Update local if different
                    if cloudValue != energySelectionConfirmedStorage {
                        LOG_DEV(
                            .info,
                            "EnergySync",
                            "Syncing energySelectionConfirmed to local",
                            metadata: ["from": "\(energySelectionConfirmedStorage)", "to": "\(cloudValue)"]
                        )
                        energySelectionConfirmedStorage = cloudValue
                    }
                    return cloudValue
                }
                LOG_DEV(
                    .debug,
                    "EnergySync",
                    "No iCloud energySelectionConfirmed, using local",
                    metadata: ["localValue": "\(energySelectionConfirmedStorage)"]
                )
            }
            return energySelectionConfirmedStorage
        }
        set {
            LOG_DEV(
                .info,
                "EnergySync",
                "Setting energySelectionConfirmed",
                metadata: [
                    "oldValue": "\(energySelectionConfirmedStorage)",
                    "newValue": "\(newValue)",
                    "iCloudEnabled": "\(enableICloudSync)"
                ]
            )
            energySelectionConfirmedStorage = newValue
            // Sync to iCloud if enabled
            if enableICloudSync {
                LOG_DEV(
                    .debug,
                    "EnergySync",
                    "Writing energySelectionConfirmed to iCloud",
                    metadata: ["value": "\(newValue)"]
                )
                NSUbiquitousKeyValueStore.default.set(newValue, forKey: "Itori.settings.energySelectionConfirmed")
                let syncResult = NSUbiquitousKeyValueStore.default.synchronize()
                LOG_DEV(.debug, "EnergySync", "iCloud synchronize() called", metadata: ["success": "\(syncResult)"])
            }
            NotificationCenter.default.post(name: .energySettingsDidChange, object: nil)
        }
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

    // AI Settings computed properties
    var aiMode: AIMode {
        get { AIMode(rawValue: aiModeRaw) ?? .auto }
        set { aiModeRaw = newValue.rawValue }
    }

    var localBackendType: LLMBackendType {
        get { LLMBackendType(rawValue: localBackendTypeRaw) ?? .mlx }
        set { localBackendTypeRaw = newValue.rawValue }
    }

    /*
     var byoProviderConfig: BYOProviderConfig {
         get {
             guard let data = byoProviderConfigData,
                   let config = try? JSONDecoder().decode(BYOProviderConfig.self, from: data) else {
                 return .default
             }
             return config
         }
         set {
             byoProviderConfigData = try? JSONEncoder().encode(newValue)
         }
     }
     */

    var aiEnabled: Bool {
        get { aiEnabledStorage }
        set { aiEnabledStorage = newValue }
    }

    var enableLLMAssistance: Bool {
        get { aiEnabledStorage }
        set { aiEnabledStorage = newValue }
    }

    var onboardingState: OnboardingState {
        get {
            guard let data = onboardingStateData else {
                return .neverSeen
            }
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(OnboardingState.self, from: data)
            } catch {
                LOG_SETTINGS(
                    .error,
                    "OnboardingStateLoad",
                    "Failed to decode onboarding state",
                    metadata: ["error": "\(error)"]
                )
                return .neverSeen
            }
        }
        set {
            do {
                let encoder = JSONEncoder()
                onboardingStateData = try encoder.encode(newValue)
                LOG_SETTINGS(
                    .info,
                    "OnboardingStateUpdate",
                    "Onboarding state updated",
                    metadata: ["state": newValue.debugDescription]
                )
            } catch {
                LOG_SETTINGS(
                    .error,
                    "OnboardingStateSave",
                    "Failed to encode onboarding state",
                    metadata: ["error": "\(error)"]
                )
            }
        }
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

    // Version tracking for settings schema
    private static let settingsSchemaVersion = 3 // Increment when adding/removing properties
    private static let schemaVersionKey = "Itori.settings.schemaVersion"

    static func load() -> AppSettingsModel {
        // Note: Can't use LOG_SETTINGS here as it accesses AppSettingsModel.shared which may not be initialized
        let devMode = UserDefaults.standard.bool(forKey: Keys.devModeEnabled)
        if devMode {
            print("[AppSettings] Starting load...")
        }

        // Check schema version
        let savedVersion = UserDefaults.standard.integer(forKey: schemaVersionKey)
        if savedVersion != 0 && savedVersion != settingsSchemaVersion {
            print(
                "[AppSettings] Schema version changed (\(savedVersion) → \(settingsSchemaVersion)), clearing old settings"
            )
            UserDefaults.standard.removeObject(forKey: "Itori.settings.appsettings")
            UserDefaults.standard.set(settingsSchemaVersion, forKey: schemaVersionKey)
            return AppSettingsModel()
        }

        // Set current version if not set
        if savedVersion == 0 {
            UserDefaults.standard.set(settingsSchemaVersion, forKey: schemaVersionKey)
        }

        let key = "Itori.settings.appsettings"

        guard let data = UserDefaults.standard.data(forKey: key) else {
            if devMode {
                print("[AppSettings] No saved data found, creating new instance")
            }
            return AppSettingsModel()
        }

        if devMode {
            print("[AppSettings] Found saved data (\(data.count) bytes), attempting to decode...")
        }
        let decoder = JSONDecoder()

        // Decode synchronously during static initialization to avoid dispatch deadlock
        do {
            if devMode {
                print("[AppSettings] About to call decoder.decode()...")
            }
            let decoded = try decoder.decode(AppSettingsModel.self, from: data)
            if devMode {
                print("[AppSettings] Successfully decoded from UserDefaults")
            }
            return decoded
        } catch {
            if let decodingError = error as? DecodingError {
                print("[AppSettings] ⚠️ DecodingError: \(decodingError)")
                if devMode {
                    switch decodingError {
                    case let .keyNotFound(key, context):
                        print("  - Missing key: \(key.stringValue) at \(context.codingPath)")
                    case let .typeMismatch(type, context):
                        print("  - Type mismatch for \(type) at \(context.codingPath)")
                    case let .valueNotFound(type, context):
                        print("  - Value not found for \(type) at \(context.codingPath)")
                    case let .dataCorrupted(context):
                        print("  - Data corrupted at \(context.codingPath)")
                    @unknown default:
                        print("  - Unknown decoding error")
                    }
                }
            } else {
                print("[AppSettings] ⚠️ Unexpected error: \(error)")
            }

            // Decode failed - clear and create fresh
            print("[AppSettings] Clearing incompatible/corrupted data and creating fresh instance")
            UserDefaults.standard.removeObject(forKey: key)
            return AppSettingsModel()
        }
    }

    func save() {
        // Debounce rapid saves to improve toggle performance
        saveDebouncer?.cancel()
        saveDebouncer = Task { @MainActor [weak self] in
            do {
                // Wait 300ms before saving - batches rapid changes
                try await Task.sleep(nanoseconds: 300_000_000)
                guard let self else { return }

                let key = "Itori.settings.appsettings"
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(self) {
                    UserDefaults.standard.set(data, forKey: key)
                }
            } catch is CancellationError {
                // Task was cancelled (user toggled again), ignore
            } catch {
                // Should not happen, but handle gracefully
            }
        }
    }

    // Codable
    init() {
        print("[AppSettings] init() started")
        // TEMP: Disabled iCloud observer setup to isolate recursive lock issue
        // setupICloudObserver()
        print("[AppSettings] init() completed (iCloud observer disabled for debugging)")
    }

    private func setupICloudObserver() {
        let devMode = UserDefaults.standard.bool(forKey: Keys.devModeEnabled)
        if devMode {
            print("[AppSettings] setupICloudObserver() started")
        }
        // Observe iCloud changes for energy settings
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }

            // TEMP: LOG_DEV disabled to prevent recursive MainActor lock during app init
            // LOG_DEV accesses Diagnostics.shared which has @MainActor properties
            print("[EnergySync] 🔔 Received iCloud change notification at \(Date())")

            // Get change reason
            if let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int {
                let reasonString = switch reason {
                case NSUbiquitousKeyValueStoreServerChange:
                    "ServerChange (another device modified)"
                case NSUbiquitousKeyValueStoreInitialSyncChange:
                    "InitialSyncChange (first sync)"
                case NSUbiquitousKeyValueStoreQuotaViolationChange:
                    "QuotaViolation (storage limit exceeded)"
                case NSUbiquitousKeyValueStoreAccountChange:
                    "AccountChange (iCloud account changed)"
                default:
                    "Unknown (\(reason))"
                }
                print("[EnergySync] Change reason: \(reasonString)")
            }

            // Get changed keys
            if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                print("[EnergySync] Changed keys from iCloud: \(changedKeys.joined(separator: ", "))")

                for key in changedKeys {
                    switch key {
                    case "Itori.settings.defaultEnergyLevel":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.string(forKey: key) {
                            let oldValue = self.defaultEnergyLevelStorage
                            if cloudValue != oldValue {
                                print(
                                    "[EnergySync] ⚡️ Energy level changed from another device: \(oldValue) → \(cloudValue)"
                                )
                                self.defaultEnergyLevelStorage = cloudValue
                                self.objectWillChange.send()

                                print("[EnergySync] Triggering planner recompute due to energy change")
                            } else {
                                print("[EnergySync] Energy level unchanged: \(cloudValue)")
                            }
                        } else {
                            print("[EnergySync] Energy level key changed but no value in iCloud")
                        }

                    case "Itori.settings.energySelectionConfirmed":
                        let cloudValue = NSUbiquitousKeyValueStore.default.bool(forKey: key)
                        let oldValue = self.energySelectionConfirmedStorage
                        if cloudValue != oldValue {
                            print(
                                "[EnergySync] Energy selection confirmed changed from another device: \(oldValue) → \(cloudValue)"
                            )
                            self.energySelectionConfirmedStorage = cloudValue
                            self.objectWillChange.send()
                        } else {
                            print("[EnergySync] Energy selection confirmed unchanged: \(cloudValue)")
                        }

                    case "Itori.settings.workday.startHour":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Int {
                            let oldValue = self.workdayStartHourStorage
                            if cloudValue != oldValue {
                                print(
                                    "[WorkdaySync] Start hour changed from another device: \(oldValue) → \(cloudValue)"
                                )
                                self.workdayStartHourStorage = cloudValue
                                self.objectWillChange.send()
                                NotificationCenter.default.post(name: .plannerNeedsRecompute, object: nil)
                            }
                        }

                    case "Itori.settings.workday.startMinute":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Int {
                            let oldValue = self.workdayStartMinuteStorage
                            if cloudValue != oldValue {
                                print(
                                    "[WorkdaySync] Start minute changed from another device: \(oldValue) → \(cloudValue)"
                                )
                                self.workdayStartMinuteStorage = cloudValue
                                self.objectWillChange.send()
                                NotificationCenter.default.post(name: .plannerNeedsRecompute, object: nil)
                            }
                        }

                    case "Itori.settings.workday.endHour":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Int {
                            let oldValue = self.workdayEndHourStorage
                            if cloudValue != oldValue {
                                print("[WorkdaySync] End hour changed from another device: \(oldValue) → \(cloudValue)")
                                self.workdayEndHourStorage = cloudValue
                                self.objectWillChange.send()
                                NotificationCenter.default.post(name: .plannerNeedsRecompute, object: nil)
                            }
                        }

                    case "Itori.settings.workday.endMinute":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Int {
                            let oldValue = self.workdayEndMinuteStorage
                            if cloudValue != oldValue {
                                print(
                                    "[WorkdaySync] End minute changed from another device: \(oldValue) → \(cloudValue)"
                                )
                                self.workdayEndMinuteStorage = cloudValue
                                self.objectWillChange.send()
                                NotificationCenter.default.post(name: .plannerNeedsRecompute, object: nil)
                            }
                        }

                    case "Itori.settings.workday.weekdays":
                        if let cloudValue = NSUbiquitousKeyValueStore.default.string(forKey: key) {
                            let oldValue = self.workdayWeekdaysStorage
                            if cloudValue != oldValue {
                                print("[WorkdaySync] Weekdays changed from another device: \(oldValue) → \(cloudValue)")
                                self.workdayWeekdaysStorage = cloudValue
                                self.objectWillChange.send()
                                NotificationCenter.default.post(name: .plannerNeedsRecompute, object: nil)
                            }
                        }

                    default:
                        print("[EnergySync] Ignoring non-energy key change: \(key)")
                    }
                }
            } else {
                print("[EnergySync] No changed keys in notification userInfo")
            }
        }

        let devModeAfterObserver = UserDefaults.standard.bool(forKey: Keys.devModeEnabled)
        if devModeAfterObserver {
            print("[AppSettings] setupICloudObserver() completed successfully")
        }
    }

    func encode(to encoder: Encoder) throws {
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
        try container.encode(enableCoreDataSyncStorage, forKey: .enableCoreDataSyncStorage)
        try container.encode(suppressICloudRestoreStorage, forKey: .suppressICloudRestoreStorage)
        try container.encode(enableAIPlannerStorage, forKey: .enableAIPlannerStorage)
        try container.encode(plannerHorizonStorage, forKey: .plannerHorizonStorage)
        try container.encode(enableFlashcardsStorage, forKey: .enableFlashcardsStorage)
        try container.encode(assignmentSwipeLeadingRaw, forKey: .assignmentSwipeLeadingRaw)
        try container.encode(assignmentSwipeTrailingRaw, forKey: .assignmentSwipeTrailingRaw)
        try container.encode(pomodoroFocusStorage, forKey: .pomodoroFocusStorage)
        try container.encode(pomodoroShortBreakStorage, forKey: .pomodoroShortBreakStorage)
        try container.encode(pomodoroLongBreakStorage, forKey: .pomodoroLongBreakStorage)
        try container.encode(pomodoroIterationsStorage, forKey: .pomodoroIterationsStorage)
        try container.encode(timerDurationStorage, forKey: .timerDurationStorage)
        try container.encode(longBreakCadenceStorage, forKey: .longBreakCadenceStorage)
        try container.encode(notificationsEnabledStorage, forKey: .notificationsEnabledStorage)
        try container.encode(assignmentRemindersEnabledStorage, forKey: .assignmentRemindersEnabledStorage)
        try container.encode(dailyOverviewEnabledStorage, forKey: .dailyOverviewEnabledStorage)
        try container.encode(affirmationsEnabledStorage, forKey: .affirmationsEnabledStorage)
        try container.encode(timerAlertsEnabledStorage, forKey: .timerAlertsEnabledStorage)
        try container.encode(pomodoroAlertsEnabledStorage, forKey: .pomodoroAlertsEnabledStorage)
        try container.encode(alarmKitTimersEnabledStorage, forKey: .alarmKitTimersEnabledStorage)
        try container.encode(assignmentLeadTimeStorage, forKey: .assignmentLeadTimeStorage)
        try container.encode(dailyOverviewTimeStorage, forKey: .dailyOverviewTimeStorage)
        try container.encode(dailyOverviewIncludeTasksStorage, forKey: .dailyOverviewIncludeTasksStorage)
        try container.encode(dailyOverviewIncludeEventsStorage, forKey: .dailyOverviewIncludeEventsStorage)
        try container.encode(
            dailyOverviewIncludeYesterdayCompletedStorage,
            forKey: .dailyOverviewIncludeYesterdayCompletedStorage
        )
        try container.encode(
            dailyOverviewIncludeYesterdayStudyTimeStorage,
            forKey: .dailyOverviewIncludeYesterdayStudyTimeStorage
        )
        try container.encode(dailyOverviewIncludeMotivationStorage, forKey: .dailyOverviewIncludeMotivationStorage)
        try container.encode(practiceTestTimeMultiplierStorage, forKey: .practiceTestTimeMultiplierStorage)
        try container.encode(showOnlySchoolCalendarStorage, forKey: .showOnlySchoolCalendarStorage)
        try container.encode(lockCalendarPickerToSchoolStorage, forKey: .lockCalendarPickerToSchoolStorage)
        try container.encodeIfPresent(selectedSchoolCalendarID, forKey: .selectedSchoolCalendarID)
        try container.encode(starredTabsRaw, forKey: .starredTabsRaw)
        try container.encode(compactModeStorage, forKey: .compactModeStorage)
        try container.encode(largeTapTargetsStorage, forKey: .largeTapTargetsStorage)
        try container.encode(showSidebarByDefaultStorage, forKey: .showSidebarByDefaultStorage)
        try container.encode(reduceMotionStorage, forKey: .reduceMotionStorage)
        try container.encode(increaseContrastStorage, forKey: .increaseContrastStorage)
        try container.encode(reduceTransparencyStorage, forKey: .reduceTransparencyStorage)
        try container.encode(glassIntensityStorage, forKey: .glassIntensityStorage)
        try container.encode(accentColorNameStorage, forKey: .accentColorNameStorage)
        try container.encode(showAnimationsStorage, forKey: .showAnimationsStorage)
        try container.encode(enableHapticsStorage, forKey: .enableHapticsStorage)
        try container.encode(showTooltipsStorage, forKey: .showTooltipsStorage)
        try container.encode(showSampleDataStorage, forKey: .showSampleDataStorage)
        try container.encode(defaultEnergyLevelStorage, forKey: .defaultEnergyLevelStorage)
        try container.encode(energySelectionConfirmedStorage, forKey: .energySelectionConfirmedStorage)
        try container.encode(workdayWeekdaysStorage, forKey: .workdayWeekdaysStorage)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Wrap all decoding in a do-catch to prevent crashes from incompatible data
        do {
            accentColorRaw = try container.decodeIfPresent(String.self, forKey: .accentColorRaw) ?? AppAccentColor.blue
                .rawValue
        } catch {
            // Only log in developer mode - this is not a critical error
            if UserDefaults.standard.bool(forKey: Keys.devModeEnabled) {
                print("[AppSettings] Failed to decode accentColorRaw, using default")
            }
            accentColorRaw = AppAccentColor.blue.rawValue
        }

        customAccentEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .customAccentEnabledStorage) ?? false
        customAccentRed = try container.decodeIfPresent(Double.self, forKey: .customAccentRed) ?? 0
        customAccentGreen = try container.decodeIfPresent(Double.self, forKey: .customAccentGreen) ?? 122 / 255
        customAccentBlue = try container.decodeIfPresent(Double.self, forKey: .customAccentBlue) ?? 1
        customAccentAlpha = try container.decodeIfPresent(Double.self, forKey: .customAccentAlpha) ?? 1
        interfaceStyleRaw = try container.decodeIfPresent(String.self, forKey: .interfaceStyleRaw) ?? InterfaceStyle
            .system.rawValue
        glassLightStrength = try container.decodeIfPresent(Double.self, forKey: .glassLightStrength) ?? 0.33
        glassDarkStrength = try container.decodeIfPresent(Double.self, forKey: .glassDarkStrength) ?? 0.17
        sidebarBehaviorRaw = try container.decodeIfPresent(String.self, forKey: .sidebarBehaviorRaw) ?? SidebarBehavior
            .automatic.rawValue
        wiggleOnHoverStorage = try container.decodeIfPresent(Bool.self, forKey: .wiggleOnHoverStorage) ?? true
        tabBarModeRaw = try container.decodeIfPresent(String.self, forKey: .tabBarModeRaw) ?? TabBarMode.iconsAndText
            .rawValue
        visibleTabsRaw = try container.decodeIfPresent(String.self, forKey: .visibleTabsRaw) ?? "dashboard,planner,assignments,courses,grades,calendar"
        tabOrderRaw = try container.decodeIfPresent(String.self, forKey: .tabOrderRaw) ?? "dashboard,planner,assignments,courses,grades,calendar"
        quickActionsRaw = try container.decodeIfPresent(String.self, forKey: .quickActionsRaw) ?? "add_assignment,add_course,quick_note"
        enableGlassEffectsStorage = try container.decodeIfPresent(Bool.self, forKey: .enableGlassEffectsStorage) ?? true
        cardRadiusRaw = try container.decodeIfPresent(String.self, forKey: .cardRadiusRaw) ?? CardRadius.medium.rawValue
        animationSoftnessStorage = try container.decodeIfPresent(Double.self, forKey: .animationSoftnessStorage) ?? 0.42
        typographyModeRaw = try container.decodeIfPresent(String.self, forKey: .typographyModeRaw) ?? TypographyMode
            .system.rawValue
        devModeEnabledStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeEnabledStorage) ?? false
        devModeUILoggingStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeUILoggingStorage) ?? true
        devModeDataLoggingStorage = try container.decodeIfPresent(Bool.self, forKey: .devModeDataLoggingStorage) ?? true
        devModeSchedulerLoggingStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .devModeSchedulerLoggingStorage
        ) ?? true
        devModePerformanceStorage = try container.decodeIfPresent(Bool.self, forKey: .devModePerformanceStorage) ?? true
        enableICloudSyncStorage = try container.decodeIfPresent(Bool.self, forKey: .enableICloudSyncStorage) ?? true
        enableCoreDataSyncStorage = try container
            .decodeIfPresent(Bool.self, forKey: .enableCoreDataSyncStorage) ?? false
        suppressICloudRestoreStorage = try container
            .decodeIfPresent(Bool.self, forKey: .suppressICloudRestoreStorage) ?? false
        enableFlashcardsStorage = try container.decodeIfPresent(Bool.self, forKey: .enableFlashcardsStorage) ?? true
        assignmentSwipeLeadingRaw = try container
            .decodeIfPresent(String.self, forKey: .assignmentSwipeLeadingRaw) ?? AssignmentSwipeAction.complete.rawValue
        assignmentSwipeTrailingRaw = try container
            .decodeIfPresent(String.self, forKey: .assignmentSwipeTrailingRaw) ?? AssignmentSwipeAction.delete.rawValue
        pomodoroFocusStorage = try container.decodeIfPresent(Int.self, forKey: .pomodoroFocusStorage) ?? 25
        pomodoroShortBreakStorage = try container.decodeIfPresent(Int.self, forKey: .pomodoroShortBreakStorage) ?? 5
        pomodoroLongBreakStorage = try container.decodeIfPresent(Int.self, forKey: .pomodoroLongBreakStorage) ?? 15
        pomodoroIterationsStorage = try container.decodeIfPresent(Int.self, forKey: .pomodoroIterationsStorage) ?? 4
        timerDurationStorage = try container.decodeIfPresent(Int.self, forKey: .timerDurationStorage) ?? 30
        longBreakCadenceStorage = try container.decodeIfPresent(Int.self, forKey: .longBreakCadenceStorage) ?? 4
        notificationsEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .notificationsEnabledStorage) ?? false
        assignmentRemindersEnabledStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .assignmentRemindersEnabledStorage
        ) ?? true
        dailyOverviewEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .dailyOverviewEnabledStorage) ?? false
        affirmationsEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .affirmationsEnabledStorage) ?? false
        timerAlertsEnabledStorage = try container.decodeIfPresent(Bool.self, forKey: .timerAlertsEnabledStorage) ?? true
        pomodoroAlertsEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .pomodoroAlertsEnabledStorage) ?? true
        alarmKitTimersEnabledStorage = try container
            .decodeIfPresent(Bool.self, forKey: .alarmKitTimersEnabledStorage) ?? true
        assignmentLeadTimeStorage = try container
            .decodeIfPresent(Double.self, forKey: .assignmentLeadTimeStorage) ?? 3600
        dailyOverviewTimeStorage = try container.decodeIfPresent(Date.self, forKey: .dailyOverviewTimeStorage) ?? {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        dailyOverviewIncludeTasksStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .dailyOverviewIncludeTasksStorage
        ) ?? true
        dailyOverviewIncludeEventsStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .dailyOverviewIncludeEventsStorage
        ) ?? true
        dailyOverviewIncludeYesterdayCompletedStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .dailyOverviewIncludeYesterdayCompletedStorage
        ) ?? true
        dailyOverviewIncludeYesterdayStudyTimeStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .dailyOverviewIncludeYesterdayStudyTimeStorage
        ) ?? true
        dailyOverviewIncludeMotivationStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .dailyOverviewIncludeMotivationStorage
        ) ?? true
        practiceTestTimeMultiplierStorage = try container.decodeIfPresent(
            Double.self,
            forKey: .practiceTestTimeMultiplierStorage
        ) ?? 1.0
        showOnlySchoolCalendarStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .showOnlySchoolCalendarStorage
        ) ?? true
        lockCalendarPickerToSchoolStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .lockCalendarPickerToSchoolStorage
        ) ?? false
        selectedSchoolCalendarID = try container.decodeIfPresent(String.self, forKey: .selectedSchoolCalendarID) ?? ""
        let decodedTabs = try container.decodeIfPresent([String].self, forKey: .starredTabsRaw) ?? [
            "dashboard",
            "courses",
            "assignments",
            "calendar",
            "grades"
        ]
        starredTabsString = decodedTabs.joined(separator: ",")
        compactModeStorage = try container.decodeIfPresent(Bool.self, forKey: .compactModeStorage) ?? false
        largeTapTargetsStorage = try container.decodeIfPresent(Bool.self, forKey: .largeTapTargetsStorage) ?? false
        showSidebarByDefaultStorage = try container
            .decodeIfPresent(Bool.self, forKey: .showSidebarByDefaultStorage) ?? true
        reduceMotionStorage = try container.decodeIfPresent(Bool.self, forKey: .reduceMotionStorage) ?? false
        increaseContrastStorage = try container.decodeIfPresent(Bool.self, forKey: .increaseContrastStorage) ?? false
        reduceTransparencyStorage = try container
            .decodeIfPresent(Bool.self, forKey: .reduceTransparencyStorage) ?? false
        glassIntensityStorage = try container.decodeIfPresent(Double.self, forKey: .glassIntensityStorage) ?? 0.5
        accentColorNameStorage = try container.decodeIfPresent(String.self, forKey: .accentColorNameStorage) ?? "Blue"
        showAnimationsStorage = try container.decodeIfPresent(Bool.self, forKey: .showAnimationsStorage) ?? true
        enableHapticsStorage = try container.decodeIfPresent(Bool.self, forKey: .enableHapticsStorage) ?? true
        showTooltipsStorage = try container.decodeIfPresent(Bool.self, forKey: .showTooltipsStorage) ?? true
        showSampleDataStorage = try container.decodeIfPresent(Bool.self, forKey: .showSampleDataStorage) ?? false
        defaultEnergyLevelStorage = try container.decodeIfPresent(String.self, forKey: .defaultEnergyLevelStorage) ?? "Medium"
        energySelectionConfirmedStorage = try container.decodeIfPresent(
            Bool.self,
            forKey: .energySelectionConfirmedStorage
        ) ?? false
        workdayWeekdaysStorage = try container.decodeIfPresent(
            String.self,
            forKey: .workdayWeekdaysStorage
        ) ?? "2,3,4,5,6"
    }

    func resetUserDefaults() {
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
        UserDefaults.standard.synchronize()
    }

    func resetToDefaults(preservingICloudSuppression: Bool, preservingICloudSyncSetting: Bool = false) {
        let keepSuppression = preservingICloudSuppression ? suppressICloudRestoreStorage : false
        let keepICloudSync = preservingICloudSyncSetting ? enableICloudSyncStorage : nil
        resetUserDefaults()
        let fresh = AppSettingsModel()

        accentColorRaw = fresh.accentColorRaw
        customAccentEnabledStorage = fresh.customAccentEnabledStorage
        customAccentRed = fresh.customAccentRed
        customAccentGreen = fresh.customAccentGreen
        customAccentBlue = fresh.customAccentBlue
        customAccentAlpha = fresh.customAccentAlpha
        interfaceStyleRaw = fresh.interfaceStyleRaw
        glassLightStrength = fresh.glassLightStrength
        glassDarkStrength = fresh.glassDarkStrength
        sidebarBehaviorRaw = fresh.sidebarBehaviorRaw
        wiggleOnHoverStorage = fresh.wiggleOnHoverStorage
        tabBarModeRaw = fresh.tabBarModeRaw
        visibleTabsRaw = fresh.visibleTabsRaw
        tabOrderRaw = fresh.tabOrderRaw
        quickActionsRaw = fresh.quickActionsRaw
        enableGlassEffectsStorage = fresh.enableGlassEffectsStorage
        cardRadiusRaw = fresh.cardRadiusRaw
        animationSoftnessStorage = fresh.animationSoftnessStorage
        typographyModeRaw = fresh.typographyModeRaw
        devModeEnabledStorage = fresh.devModeEnabledStorage
        devModeUILoggingStorage = fresh.devModeUILoggingStorage
        devModeDataLoggingStorage = fresh.devModeDataLoggingStorage
        devModeSchedulerLoggingStorage = fresh.devModeSchedulerLoggingStorage
        devModePerformanceStorage = fresh.devModePerformanceStorage
        if let keepICloudSync {
            enableICloudSyncStorage = keepICloudSync
        } else {
            enableICloudSyncStorage = fresh.enableICloudSyncStorage
        }
        suppressICloudRestoreStorage = keepSuppression
        enableSpotlightIndexingStorage = fresh.enableSpotlightIndexingStorage
        enableRaycastIntegrationStorage = fresh.enableRaycastIntegrationStorage
        enableAIPlannerStorage = fresh.enableAIPlannerStorage
        plannerHorizonStorage = fresh.plannerHorizonStorage
        enableFlashcardsStorage = fresh.enableFlashcardsStorage
        assignmentSwipeLeadingRaw = fresh.assignmentSwipeLeadingRaw
        assignmentSwipeTrailingRaw = fresh.assignmentSwipeTrailingRaw
        pomodoroFocusStorage = fresh.pomodoroFocusStorage
        pomodoroShortBreakStorage = fresh.pomodoroShortBreakStorage
        pomodoroLongBreakStorage = fresh.pomodoroLongBreakStorage
        pomodoroIterationsStorage = fresh.pomodoroIterationsStorage
        timerDurationStorage = fresh.timerDurationStorage
        longBreakCadenceStorage = fresh.longBreakCadenceStorage
        notificationsEnabledStorage = fresh.notificationsEnabledStorage
        assignmentRemindersEnabledStorage = fresh.assignmentRemindersEnabledStorage
        dailyOverviewEnabledStorage = fresh.dailyOverviewEnabledStorage
        affirmationsEnabledStorage = fresh.affirmationsEnabledStorage
        timerAlertsEnabledStorage = fresh.timerAlertsEnabledStorage
        pomodoroAlertsEnabledStorage = fresh.pomodoroAlertsEnabledStorage
        alarmKitTimersEnabledStorage = fresh.alarmKitTimersEnabledStorage
        assignmentLeadTimeStorage = fresh.assignmentLeadTimeStorage
        dailyOverviewTimeStorage = fresh.dailyOverviewTimeStorage
        dailyOverviewIncludeTasksStorage = fresh.dailyOverviewIncludeTasksStorage
        dailyOverviewIncludeEventsStorage = fresh.dailyOverviewIncludeEventsStorage
        dailyOverviewIncludeYesterdayCompletedStorage = fresh.dailyOverviewIncludeYesterdayCompletedStorage
        dailyOverviewIncludeYesterdayStudyTimeStorage = fresh.dailyOverviewIncludeYesterdayStudyTimeStorage
        dailyOverviewIncludeMotivationStorage = fresh.dailyOverviewIncludeMotivationStorage
        showOnlySchoolCalendarStorage = fresh.showOnlySchoolCalendarStorage
        lockCalendarPickerToSchoolStorage = fresh.lockCalendarPickerToSchoolStorage
        selectedSchoolCalendarID = fresh.selectedSchoolCalendarID
        starredTabsString = fresh.starredTabsString
        compactModeStorage = fresh.compactModeStorage
        largeTapTargetsStorage = fresh.largeTapTargetsStorage
        showSidebarByDefaultStorage = fresh.showSidebarByDefaultStorage
        reduceMotionStorage = fresh.reduceMotionStorage
        increaseContrastStorage = fresh.increaseContrastStorage
        reduceTransparencyStorage = fresh.reduceTransparencyStorage
        increaseTransparencyStorage = fresh.increaseTransparencyStorage
        glassIntensityStorage = fresh.glassIntensityStorage
        accentColorNameStorage = fresh.accentColorNameStorage
        showAnimationsStorage = fresh.showAnimationsStorage
        enableHapticsStorage = fresh.enableHapticsStorage
        showTooltipsStorage = fresh.showTooltipsStorage
        defaultFocusDurationStorage = fresh.defaultFocusDurationStorage
        defaultBreakDurationStorage = fresh.defaultBreakDurationStorage
        defaultEnergyLevelStorage = fresh.defaultEnergyLevelStorage
        energySelectionConfirmedStorage = fresh.energySelectionConfirmedStorage
        enableStudyCoachStorage = fresh.enableStudyCoachStorage
        smartNotificationsStorage = fresh.smartNotificationsStorage
        autoScheduleBreaksStorage = fresh.autoScheduleBreaksStorage
        trackStudyHoursStorage = fresh.trackStudyHoursStorage
        showProductivityInsightsStorage = fresh.showProductivityInsightsStorage
        weeklySummaryNotificationsStorage = fresh.weeklySummaryNotificationsStorage
        preferMorningSessionsStorage = fresh.preferMorningSessionsStorage
        preferEveningSessionsStorage = fresh.preferEveningSessionsStorage
        enableDeepWorkModeStorage = fresh.enableDeepWorkModeStorage
        use24HourTimeStorage = fresh.use24HourTimeStorage
        workdayStartHourStorage = fresh.workdayStartHourStorage
        workdayStartMinuteStorage = fresh.workdayStartMinuteStorage
        workdayEndHourStorage = fresh.workdayEndHourStorage
        workdayEndMinuteStorage = fresh.workdayEndMinuteStorage
        workdayWeekdaysStorage = fresh.workdayWeekdaysStorage
        showEnergyPanelStorage = fresh.showEnergyPanelStorage
        highContrastModeStorage = fresh.highContrastModeStorage
        startOfWeekStorage = fresh.startOfWeekStorage
        defaultViewStorage = fresh.defaultViewStorage
        isSchoolModeStorage = fresh.isSchoolModeStorage
        // aiEnabledStorage now uses @AppStorage, not part of Codable
        loadLowThresholdStorage = fresh.loadLowThresholdStorage
        loadMediumThresholdStorage = fresh.loadMediumThresholdStorage
        loadHighThresholdStorage = fresh.loadHighThresholdStorage
        categoryEffortProfilesStorage = fresh.categoryEffortProfilesStorage
        save()
    }
}
