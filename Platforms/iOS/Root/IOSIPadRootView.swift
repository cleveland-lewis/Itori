#if os(iOS)
import SwiftUI

struct IOSIPadRootView: View {
    enum IPadSection: String, CaseIterable, Identifiable {
        case core
        case planning
        case focus

        var id: String { rawValue }
        var title: String {
            switch self {
            case .core: return NSLocalizedString("ipad.section.core", value: "Core", comment: "iPad sidebar section")
            case .planning: return NSLocalizedString("ipad.section.planning", value: "Planning", comment: "iPad sidebar section")
            case .focus: return NSLocalizedString("ipad.section.focus", value: "Focus", comment: "iPad sidebar section")
            }
        }
    }

    @State private var selectedSection: IPadSection? = .core
    @State private var selectedPage: AppPage? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(IPadSection.allCases, selection: $selectedSection) { section in
                Text(section.title)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle(NSLocalizedString("navigation.menu", value: "Menu", comment: "Sidebar menu title"))
        } detail: {
            NavigationSplitView {
                List(sectionPages, selection: $selectedPage) { page in
                    Label(page.title, systemImage: page.systemImage)
                        .tag(page)
                }
                .listStyle(.sidebar)
                .navigationTitle(NSLocalizedString("navigation.pages", value: "Pages", comment: "Sidebar pages title"))
            } detail: {
                if let page = selectedPage {
                    detailView(for: page)
                } else {
                    IOSPlaceholderView(
                        title: NSLocalizedString("navigation.select_page", value: "Select a page", comment: "iPad placeholder title"),
                        subtitle: NSLocalizedString("navigation.select_page.subtitle", value: "Choose a page from the middle column.", comment: "iPad placeholder subtitle")
                    )
                }
            }
        }
        .background(DesignSystem.Colors.appBackground)
    }

    private var sectionPages: [AppPage] {
        switch selectedSection ?? .core {
        case .core:
            return [.dashboard, .calendar]
        case .planning:
            return [.planner, .grades]
        case .focus:
            return [.timer]
        }
    }

    @ViewBuilder
    private func detailView(for page: AppPage) -> some View {
        switch page {
        case .dashboard:
            IOSDashboardView()
        case .calendar:
            IOSCalendarView()
        case .planner:
            IOSPlannerView()
        case .grades:
            IOSGradesView()
        case .timer:
            IOSTimerPageView()
        default:
            IOSPlaceholderView(
                title: page.title,
                subtitle: NSLocalizedString("navigation.ipad.unavailable", value: "This view is not available on iPad yet.", comment: "iPad unavailable view message")
            )
        }
    }
}
#endif
