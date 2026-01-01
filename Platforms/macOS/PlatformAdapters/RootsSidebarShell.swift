#if os(macOS)
import SwiftUI

/// Root shell view with persistent sidebar and glass content area
struct RootsSidebarShell: View {
    @State private var selection: RootTab = .dashboard
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var appModel: AppModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // Persistent left sidebar (never collapses)
            SidebarColumn(selection: $selection)
                .frame(width: 260)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
            
            Divider()
                .opacity(0.3)
            
            // Main content area with glass panel
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
                
                GlassPanel(material: .hudWindow, cornerRadius: 18, showBorder: true) {
                    currentPageView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(20)
            }
        }
        .frame(minWidth: RootsWindowSizing.minMainWidth, minHeight: RootsWindowSizing.minMainHeight)
        .globalContextMenu()
        .onAppear {
            setupWindow()
            // Sync selection with appModel
            if let tab = RootTab(rawValue: appModel.selectedPage.rawValue) {
                selection = tab
            }
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
                FlashcardDashboard()
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
            Text("Flashcards are turned off")
                .font(DesignSystem.Typography.subHeader)
            Text("Enable flashcards in Settings → Flashcards to study decks.")
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
    @EnvironmentObject var settings: AppSettingsModel
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @State private var settingsRotation: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // App header
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .font(.title2)
                    .foregroundStyle(settings.activeAccentColor)
                
                Text("Roots")
                    .font(.title2.weight(.semibold))
                
                Spacer()
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
                    
                    Text("Settings")
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

#endif
