#if os(macOS)
import SwiftUI

struct GradesView: View {
    // Empty model collections for now
    private let gradesSummary: [Any] = []
    private let courseGrades: [Any] = []
    private let gradeComponents: [Any] = []
    private let analytics: [Any] = []

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Title removed

                    LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                        // Overall Status
                        Section(header: Text(NSLocalizedString("grades.overall.status", value: "Overall Status", comment: "Overall Status")).font(DesignSystem.Typography.body)) {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "chart.bar")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("grades.overall.status", value: "Overall Status", comment: "Overall Status"))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        }

                        // By Course
                        Section(header: Text(NSLocalizedString("grades.by.course", value: "By Course", comment: "By Course")).font(DesignSystem.Typography.body)) {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "list.bullet")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("grades.by.course", value: "By Course", comment: "By Course"))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        }

                        // Grade Components
                        Section(header: Text(NSLocalizedString("grades.grade.components", value: "Grade Components", comment: "Grade Components")).font(DesignSystem.Typography.body)) {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "list.bullet.rectangle")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("grades.grade.components", value: "Grade Components", comment: "Grade Components"))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        }

                        // Trends & Analytics
                        Section(header: Text(NSLocalizedString("grades.trends.analytics", value: "Trends & Analytics", comment: "Trends & Analytics")).font(DesignSystem.Typography.body)) {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("grades.trends.analytics", value: "Trends & Analytics", comment: "Trends & Analytics"))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        }
                    }
                }
                .frame(maxWidth: min(geometry.size.width, 900))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, responsivePadding(for: geometry.size.width))
                .padding(.vertical, DesignSystem.Spacing.large)
            }
        }
        .rootsSystemBackground()
    }

    private func responsivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<600: return 16
        case 600..<900: return 20
        case 900..<1200: return 24
        case 1200..<1600: return 32
        default: return 40
        }
    }
}

struct GradesView_Previews: PreviewProvider {
    static var previews: some View {
        GradesView()
    }
}
#endif
