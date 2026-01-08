#if os(macOS)
import SwiftUI
import Combine
import AppKit

// MARK: - Settings Navigation

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case appearance
    case interface
    case accounts
    case courses
    case calendar
    case planner
    case semesters
    case profiles
    case ai
    case integrations
    case notifications
    case privacy
    case storage
    case developer

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .interface: return "rectangle.3.offgrid"
        case .accounts: return "person.crop.circle"
        case .courses: return "books.vertical"
        case .calendar: return "calendar"
        case .planner: return "calendar.badge.clock"
        case .semesters: return "calendar.circle"
        case .profiles: return "person.text.rectangle"
        case .ai: return "brain"
        case .integrations: return "puzzlepiece.extension"
        case .notifications: return "bell.badge"
        case .privacy: return "hand.raised"
        case .storage: return "externaldrive"
        case .developer: return "hammer"
        }
    }
}

// MARK: - Comprehensive Settings Root View

struct SettingsRootView: View {
    @Binding var selection: SettingsToolbarIdentifier
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    
    var body: some View {
        contentView
            .frame(minWidth: 700, minHeight: 500)
            .navigationTitle(selection.label)
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selection {
                case .subscription:
                    MacOSSubscriptionView()
                case .general:
                    GeneralSettingsView()
                case .calendar:
                    CalendarSettingsView()
                case .planner:
                    PlannerSettingsView()
                case .courses:
                    CoursesSettingsView()
                case .semesters:
                    SemestersSettingsView()
                case .interface:
                    InterfaceSettingsView()
                case .profiles:
                    ProfilesSettingsView()
                case .ai:
                    AISettingsView()
                case .integrations:
                    IntegrationsSettingsView()
                case .notifications:
                    NotificationsSettingsView()
                case .privacy:
                    PrivacySettingsView()
                case .storage:
                    StorageSettingsView()
                case .developer:
                    DeveloperSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .padding(20)
        }
    }
}

// MARK: - ItoriSettingsWindow (Legacy Simple View - Deprecated)

struct RootsSettingsWindow: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    @Environment(\.dismiss) private var dismiss
    @State private var selection: SettingsSection = .general
    @State private var paneSelectionCancellableHolder: AnyCancellable? = nil
    @State private var query: String = ""

    private var accentColor: Color { .accentColor }

    @State private var sidebarExpanded: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // Constrain the sidebar to a slimmer range (min 180, ideal 200, max 220)
            let sidebarWidth = min(max(180, size.width * (sidebarExpanded ? 0.20 : 0.14)), 220)

            ZStack {
                // Removed blue-tinted background overlay

                VStack(spacing: 0) {
                    // Empty top spacer to align content under traffic lights
                    Spacer().frame(height: 8)

                    HStack(spacing: 0) {
                        SettingsSidebar(selection: $selection, query: $query, accentColor: accentColor)
                            .frame(width: sidebarWidth, height: size.height - 56) // account for header
                            .frame(minWidth: 180, idealWidth: 200, maxWidth: 220, alignment: .leading)

                        Divider()

                        SettingsDetail(selection: selection, accentColor: accentColor)
                            .frame(width: size.width - sidebarWidth, height: size.height - 56)
                    }
                    .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .tint(accentColor)
        .frame(minWidth: 820, idealWidth: 820, maxWidth: 1200, minHeight: 520, idealHeight: 560, maxHeight: 900)
        .onReceive(settings.objectWillChange) { _ in
            DispatchQueue.main.async {
                settings.save()
            }
        }
        .onAppear {
            paneSelectionCancellableHolder = NotificationCenter.default.publisher(for: .selectSettingsPane)
                .compactMap { $0.userInfo?["pane"] as? String }
                .receive(on: DispatchQueue.main)
                .sink { raw in
                    if let match = SettingsSection.allCases.first(where: { $0.rawValue == raw }) {
                        selection = match
                    }
                }
        }
        .onDisappear {
            paneSelectionCancellableHolder?.cancel()
            paneSelectionCancellableHolder = nil
        }
    }
}

// MARK: - Sidebar

private struct SettingsSidebar: View {
    @Binding var selection: SettingsSection
    @Binding var query: String
    var accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            TextField("Search Settings", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 10)
                .padding(.top, 12)

            List(selection: $selection) {
                ForEach(SettingsSection.allCases, id: \.id) { section in
                    HStack { sidebarRow(for: section) }
                        .tag(section)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.sidebar)
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func sidebarRow(for section: SettingsSection) -> some View {
        let isSelected = selection == section
        HStack(spacing: DesignSystem.Layout.spacing.small) {
            Image(systemName: section.iconName)
                .font(DesignSystem.Typography.body)
            Text(section.title)
                .font(DesignSystem.Typography.body)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous)
                .fill(isSelected ? accentColor.opacity(0.9) : Color.clear)
        )
        .foregroundColor(isSelected ? .white : .primary)
        .contentShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusStandard, style: .continuous))
    }
}

// MARK: - Detail Container

private struct SettingsDetail: View {
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var coursesStore: CoursesStore
    var selection: SettingsSection
    var accentColor: Color

    var body: some View {
        VStack {
            switch selection {
            case .general:
                LegacyGeneralSettingsView(accentColor: accentColor)
            case .appearance:
                AppearanceSettingsView(accentColor: accentColor)
            case .interface:
                LegacyInterfaceSettingsView(accentColor: accentColor)
            case .courses:
                // Note: Legacy courses settings - use SettingsRootView for new settings system
                CoursesSettingsView()
                    .environmentObject(coursesStore)
            case .accounts:
                AccountsSettingsView(accentColor: accentColor)
            default:
                // Legacy view - unimplemented sections use new SettingsRootView
                Text(verbatim: "Use new Settings window for \(selection.title)")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Group Container Helper

private struct SettingsBreadcrumbView: View {
    let segments: [String]
    let activeIndex: Int
    var onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            if segments.count >= 2 {
                Button {
                    onTap(0)
                } label: {
                    Text(segments[0])
                        .font(activeIndex == 0 ? .body : .caption)
                        .foregroundColor(activeIndex == 0 ? RootsColor.textPrimary : RootsColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .disabled(activeIndex == 0)

                Text(NSLocalizedString("settings.", value: ">", comment: ">"))
                    .rootsCaption()
                    .foregroundColor(RootsColor.textSecondary)

                Button {
                    onTap(1)
                } label: {
                    Text(segments[1])
                        .font(activeIndex == 1 ? .body : .caption)
                        .foregroundColor(activeIndex == 1 ? RootsColor.textPrimary : RootsColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .disabled(activeIndex == 1)
            } else {
                Text(segments.first ?? "")
                    .font(.body)
            }
        }
    }
}

// MARK: - Group Container Helper

private struct SettingsRow<Content: View>: View {
    let title: String
    let description: String?
    @ViewBuilder let control: () -> Content

    private let labelWidth: CGFloat = 180

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: RootsSpacing.l) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .rootsBodySecondary()
                    .frame(width: labelWidth, alignment: Alignment.leading)

                if let description {
                    Text(description)
                        .rootsCaption()
                        .frame(width: labelWidth, alignment: Alignment.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            control()
                .frame(maxWidth: .infinity, alignment: Alignment.leading)
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let accent: Color
    let content: Content

    init(title: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .rootsSectionHeader()
                .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(DesignSystem.Layout.padding.card)
            .rootsCardBackground(radius: 18)
        }
    }
}

// MARK: - Sections

private struct LegacyGeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    var accentColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.large) {
                Text(NSLocalizedString("settings.general", value: "General", comment: "General"))
                    .font(.title2.weight(.semibold))

                SettingsGroup(title: "Interaction", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Enable hover wiggle", description: nil) {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.wiggleOnHover)
                                .labelsHidden()
                                .onChange(of: settings.wiggleOnHover) { _, _ in settings.save() }
                        }
                        SettingsRow(title: "Keep glass accents active", description: "Prevents cards from desaturating when idle.") {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.enableGlassEffects)
                                .labelsHidden()
                                .onChange(of: settings.enableGlassEffects) { _, _ in settings.save() }
                        }
                    }
                }

                SettingsGroup(title: "Layout", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Tab bar mode", description: nil) {
                            Picker("", selection: $settings.tabBarMode) {
                                Text(NSLocalizedString("settings.icons", value: "Icons", comment: "Icons")).tag(TabBarMode.iconsOnly)
                                Text(NSLocalizedString("settings.text", value: "Text", comment: "Text")).tag(TabBarMode.textOnly)
                                Text(NSLocalizedString("settings.icons.text", value: "Icons & Text", comment: "Icons & Text")).tag(TabBarMode.iconsAndText)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        SettingsRow(title: "Sidebar behavior", description: "Automatic keeps the sidebar responsive to window size while still letting it stay pinned when you want it.") {
                            Picker("", selection: $settings.sidebarBehavior) {
                                Text(NSLocalizedString("settings.autocollapse", value: "Auto-collapse", comment: "Auto-collapse")).tag(SidebarBehavior.automatic)
                                Text(NSLocalizedString("settings.always.visible", value: "Always visible", comment: "Always visible")).tag(SidebarBehavior.expanded)
                                Text(NSLocalizedString("settings.always.hidden", value: "Always hidden", comment: "Always hidden")).tag(SidebarBehavior.compact)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(DesignSystem.Layout.spacing.large)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(accentColor)
    }
}

private struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    var accentColor: Color

    private let swatches: [(choice: AppAccentColor, color: Color)] = [
        (.blue, .blue),
        (.purple, .purple),
        (.green, .green),
        (.pink, .pink),
        (.orange, .orange),
        (.yellow, .yellow)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.large) {
                Text(NSLocalizedString("settings.appearance", value: "Appearance", comment: "Appearance"))
                    .font(.title2.weight(.semibold))

                SettingsGroup(title: "Theme", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Follow system appearance", description: nil) {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: Binding(get: { settings.interfaceStyle == .system }, set: { newValue in
                                settings.interfaceStyle = newValue ? .system : .light
                            }))
                            .labelsHidden()
                        }

                        SettingsRow(title: "Mode", description: "Choose how Itori reacts to system appearance changes.") {
                            Picker("", selection: $settings.interfaceStyle) {
                                ForEach(InterfaceStyle.allCases) { style in
                                    Text(style.label).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }

                SettingsGroup(title: "Accent Color", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Accent color", description: nil) {
                            HStack(spacing: 12) {
                                ForEach(swatches, id: \.choice) { swatch in
                                    ZStack {
                                        Circle()
                                            .fill(swatch.color)
                                            .frame(width: 32, height: 32)
                                        if settings.accentColorChoice == swatch.choice {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.25)))
                                        }
                                    }
                                    .onTapGesture {
                                        settings.accentColorChoice = swatch.choice
                                        settings.save()
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityLabel("\(swatch.name) color")
                                    .accessibilityHint("Set accent color")
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(DesignSystem.Layout.spacing.large)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(accentColor)
    }
}

private struct LegacyInterfaceSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    var accentColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.large) {
                Text(NSLocalizedString("settings.interface", value: "Interface", comment: "Interface"))
                    .font(.title2.weight(.semibold))

                SettingsGroup(title: "Display", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Show hover wiggle on cards", description: nil) {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.wiggleOnHover)
                                .labelsHidden()
                        }
                        SettingsRow(title: "Use compact mode for Dashboard", description: nil) {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.highContrastMode)
                                .labelsHidden()
                        }
                        SettingsRow(title: "Use 24-hour time", description: nil) {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.use24HourTime)
                                .labelsHidden()
                        }
                        SettingsRow(
                            title: NSLocalizedString("settings.toggle.hide_gpa_dashboard", value: "Hide GPA on dashboard", comment: "Hide GPA on dashboard toggle"),
                            description: NSLocalizedString("settings.toggle.hide_gpa_dashboard.description", value: "Remove numeric GPA values from the dashboard charts.", comment: "Hide GPA description")
                        ) {
                            Toggle(NSLocalizedString("", value: "", comment: "Hidden toggle label"), isOn: $settings.hideGPAOnDashboard)
                                .labelsHidden()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(DesignSystem.Layout.spacing.large)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(accentColor)
    }
}

private struct AccountsSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    var accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(NSLocalizedString("settings.accounts", value: "Accounts", comment: "Accounts"))
                .font(.title2.weight(.semibold))

            SettingsGroup(title: "Primary Account", accent: accentColor) {
                HStack {
                    Text(NSLocalizedString("settings.email", value: "Email", comment: "Email"))
                    Spacer()
                    Text(NSLocalizedString("settings.not.set", value: "Not set", comment: "Not set"))
                        .foregroundColor(.secondary)
                }
                Button(NSLocalizedString("settings.button.manage", value: "Manage…", comment: "Manage…")) { }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
            }

            SettingsGroup(title: "Sync", accent: accentColor) {
                Text(NSLocalizedString("settings.manage.icloud.sync.in.storage.settings", value: "Manage iCloud sync in Storage settings.", comment: "Manage iCloud sync in Storage settings."))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .tint(accentColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct LegacyCoursesSettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    var accentColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.large) {
                Text(NSLocalizedString("settings.courses", value: "Courses", comment: "Courses"))
                    .font(.title2.weight(.semibold))

                SettingsGroup(title: "Course Management", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("settings.manage.all.your.courses.semesters", value: "Manage all your courses, semesters, and academic settings from the Courses page.", comment: "Manage all your courses, semesters, and academic s..."))
                            .rootsBody()
                            .foregroundColor(.secondary)

                        Text(NSLocalizedString("settings.use.the.courses.page.to", value: "Use the Courses page to add, edit, and organize your academic schedule.", comment: "Use the Courses page to add, edit, and organize yo..."))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                SettingsGroup(title: "Academic Settings", accent: accentColor) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Default grade scale", description: nil) {
                            Picker("", selection: Binding(get: {
                                "standard"
                            }, set: { _ in })) {
                                Text(NSLocalizedString("settings.standard.af", value: "Standard (A-F)", comment: "Standard (A-F)")).tag("standard")
                                Text(NSLocalizedString("settings.percentage", value: "Percentage", comment: "Percentage")).tag("percentage")
                                Text(NSLocalizedString("settings.points", value: "Points", comment: "Points")).tag("points")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        SettingsRow(title: "Show course codes", description: "Display course codes in sidebar lists.") {
                            Toggle(NSLocalizedString("settings.toggle.", value: "", comment: ""), isOn: $settings.wiggleOnHover) // placeholder
                                .labelsHidden()
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(DesignSystem.Layout.spacing.large)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(accentColor)
    }
}
#endif
