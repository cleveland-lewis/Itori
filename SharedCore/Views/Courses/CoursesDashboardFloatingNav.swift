import SwiftUI

struct CoursesDashboardFloatingNav: View {
    @Binding var selectedTab: DashboardTab

    enum DashboardTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case calendar = "Calendar"
        case assignments = "Assignments"
        case planner = "Planner"
        case courses = "Courses"
        case grades = "Grades"
        case timer = "Timer"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: "square.grid.2x2"
            case .calendar: "calendar"
            case .assignments: "doc.text"
            case .planner: "slider.horizontal.3"
            case .courses: "book.closed"
            case .grades: "chart.bar"
            case .timer: "timer"
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing.small) {
            ForEach(DashboardTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        #if os(macOS)
            .background {
                DesignSystem.Colors.sidebarBackground
            }
            .clipShape(Capsule())
        #else
            .background(DesignSystem.Materials.hud)
            .clipShape(Capsule())
        #endif
            .overlay(
                Capsule()
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
            )
        #if !os(macOS)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        #endif
    }

    private func tabButton(for tab: DashboardTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: tab.icon)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(selectedTab == tab ? .white : .primary)
                .frame(width: 44, height: 36)
                .background(
                    Capsule()
                        .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(tab.rawValue)
    }
}
