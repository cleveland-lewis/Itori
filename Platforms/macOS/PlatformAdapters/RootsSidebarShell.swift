#if os(macOS)
import SwiftUI

/// Root shell view with persistent sidebar and glass content area
struct RootsSidebarShell: View {
    @State private var selection: RootTab = .dashboard
    @AppStorage("sidebarVisible") private var sidebarVisible: Bool = true
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var appModel: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCoursesSyncConflict = false
    
    private var preferredColorScheme: ColorScheme? {
        switch settings.interfaceStyle {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 19 || hour < 7) ? .dark : .light
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Persistent left sidebar (card style)
            if sidebarVisible {
                GlassPanel(material: .hudWindow, cornerRadius: 18, showBorder: true) {
                    SidebarColumn(selection: $selection, sidebarVisible: $sidebarVisible)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: 260)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Main content area
            VStack(spacing: 0) {
                // Toolbar with quick add and energy indicator
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Menu {
                            Button(action: {
                                NotificationCenter.default.post(name: .addAssignmentRequested, object: nil)
                            }) {
                                Label(NSLocalizedString("ui.label.assignment", value: "Assignment", comment: "Assignment"), systemImage: "doc.text")
                            }
                            
                            Button(action: {
                                NotificationCenter.default.post(name: .addEventRequested, object: nil)
                            }) {
                                Label(NSLocalizedString("ui.label.event", value: "Event", comment: "Event"), systemImage: "calendar.badge.plus")
                            }
                            
                            Button(action: {
                                NotificationCenter.default.post(name: .addCourseRequested, object: nil)
                            }) {
                                Label(NSLocalizedString("ui.label.course", value: "Course", comment: "Course"), systemImage: "books.vertical")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                NotificationCenter.default.post(name: .addGradeRequested, object: nil)
                            }) {
                                Label(NSLocalizedString("ui.label.grade", value: "Grade", comment: "Grade"), systemImage: "chart.bar")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Quick Add")
                        .menuIndicator(.hidden)
                        .menuStyle(.borderlessButton)
                        
                        Divider()
                            .frame(height: 18)
                            .overlay(Color.primary.opacity(0.12))
                        
                        EnergyIndicatorButton(settings: settings, showsBackground: false)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(DesignSystem.Materials.card)
                            .opacity(0.85)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Page content
                currentPageView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.appBackground)
        }
        .padding(16)
        .background(DesignSystem.Colors.appBackground)
        .frame(minWidth: RootsWindowSizing.minMainWidth, minHeight: RootsWindowSizing.minMainHeight)
        .preferredColorScheme(preferredColorScheme)
        .globalContextMenu()
        .onAppear {
            setupWindow()
            // Sync selection with appModel
            if let tab = RootTab(rawValue: appModel.selectedPage.rawValue) {
                selection = tab
            }
        }
        .alert(
            NSLocalizedString("sync.conflict.courses.title", value: "Courses Sync Conflict", comment: "Courses sync conflict title"),
            isPresented: $showingCoursesSyncConflict
        ) {
            Button(NSLocalizedString("sync.conflict.courses.keep_local", value: "Keep Local", comment: "Keep local data")) {
                CoursesStore.shared?.resolveSyncConflict(useCloud: false)
            }
            Button(NSLocalizedString("sync.conflict.courses.use_icloud", value: "Use iCloud", comment: "Use iCloud data"), role: .destructive) {
                CoursesStore.shared?.resolveSyncConflict(useCloud: true)
            }
        } message: {
            Text(NSLocalizedString("sync.conflict.courses.message", value: "Courses and semesters differ between this device and iCloud. Choose which data to keep.", comment: "Courses sync conflict message"))
        }
        .onChange(of: selection) { _, newTab in
            if let page = AppPage(rawValue: newTab.rawValue), appModel.selectedPage != page {
                appModel.selectedPage = page
            }
        }
        .onReceive(appModel.$selectedPage) { page in
            if let tab = RootTab(rawValue: page.rawValue), selection != tab {
                selection = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .coursesSyncConflict)) { _ in
            showingCoursesSyncConflict = true
        }
    }
    
    @ViewBuilder
    private var currentPageView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .calendar:
            CalendarPageView()
        case .planner:
            PlannerPageView()
        case .assignments:
            AssignmentsPageView()
        case .courses:
            CoursesPageView()
        case .grades:
            GradesPageView()
        case .timer:
            TimerPageView()
        case .flashcards:
            if settings.enableFlashcards {
                FlashcardsView()
            } else {
                emptyFlashcardsView
            }
        case .practice:
            PracticeTestPageView()
        }
    }
    
    private var emptyFlashcardsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.person.crop")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("ui.flashcards.are.turned.off", value: "Flashcards are turned off", comment: "Flashcards are turned off"))
                .font(DesignSystem.Typography.subHeader)
            Text(NSLocalizedString("ui.enable.flashcards.in.settings.flashcards", value: "Enable flashcards in Settings → Flashcards to study decks.", comment: "Enable flashcards in Settings → Flashcards to stud..."))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func setupWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                window.title = ""
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.backgroundColor = NSColor.windowBackgroundColor
            }
        }
    }
}

/// Sidebar column with navigation items
struct SidebarColumn: View {
    @Binding var selection: RootTab
    @Binding var sidebarVisible: Bool
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @State private var settingsRotation: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // App header with toggle
            HStack {
                Text(NSLocalizedString("ui.itori", value: "Itori", comment: "Itori"))
                    .font(.title2.weight(.semibold))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sidebarVisible.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Hide Sidebar")
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)
            
            // Navigation items
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(RootTab.allCases, id: \.self) { tab in
                        SidebarItem(
                            tab: tab,
                            isSelected: selection == tab,
                            action: { selection = tab }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            Divider()
                .opacity(0.3)
                .padding(.horizontal, 12)
            
            // Settings button at bottom
            Button(action: {
                withAnimation(.easeInOut(duration: DesignSystem.Motion.deliberate)) {
                    settingsRotation += 360
                }
                settingsCoordinator.show()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .rotationEffect(.degrees(settingsRotation))
                    
                    Text(NSLocalizedString("ui.settings", value: "Settings", comment: "Settings"))
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

/// Individual sidebar navigation item
struct SidebarItem: View {
    let tab: RootTab
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var settings: AppSettingsModel
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.systemImage)
                    .font(.body)
                    .frame(width: 20)
                
                Text(tab.title)
                    .font(.body)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundForState)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var backgroundForState: Color {
        if isSelected {
            return settings.activeAccentColor.opacity(0.15)
        } else if isHovered {
            return Color.white.opacity(0.08)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Energy Indicator Button

struct EnergyIndicatorButton: View {
    @ObservedObject var settings: AppSettingsModel
    var showsBackground: Bool = true
    @State private var showPopover = false
    
    var body: some View {
        Button(action: {
            showPopover.toggle()
        }) {
            Image(systemName: energyIcon)
                .font(.body)
                .foregroundStyle(energyColor)
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if showsBackground {
                            Circle()
                                .fill(DesignSystem.Materials.hud.opacity(0.5))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .help("Energy Level: \(settings.defaultEnergyLevel)")
        .popover(isPresented: $showPopover) {
            EnergyPickerPopover(settings: settings, showPopover: $showPopover)
        }
    }
    
    private var energyIcon: String {
        switch settings.defaultEnergyLevel {
        case "High":
            return "bolt.fill"
        case "Low":
            return "bolt.slash"
        default: // Medium
            return "bolt"
        }
    }
    
    private var energyColor: Color {
        switch settings.defaultEnergyLevel {
        case "High":
            return .green
        case "Low":
            return .orange
        default: // Medium
            return .yellow
        }
    }
}

struct EnergyPickerPopover: View {
    @ObservedObject var settings: AppSettingsModel
    @Binding var showPopover: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("ui.energy.level", value: "Energy Level", comment: "Energy Level"))
                .font(.headline)
            
            VStack(spacing: 8) {
                energyOption(title: "High", icon: "bolt.fill", color: .green)
                energyOption(title: "Medium", icon: "bolt", color: .yellow)
                energyOption(title: "Low", icon: "bolt.slash", color: .orange)
            }
        }
        .padding(16)
        .frame(width: 200)
    }
    
    private func energyOption(title: String, icon: String, color: Color) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                settings.defaultEnergyLevel = title
                settings.energySelectionConfirmed = true
            }
            showPopover = false
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if settings.defaultEnergyLevel == title {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.defaultEnergyLevel == title ? 
                          color.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#endif
