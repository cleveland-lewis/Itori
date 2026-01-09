#if os(macOS)
    import Charts
    import SwiftUI

    struct TimerRightPane: View {
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var appModel: AppModel
        var activities: [LocalTimerActivity]

        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
                    Text(NSLocalizedString("ui.study.summary", value: "Study Summary", comment: "Study Summary"))
                        .font(.headline)

                    TodayStudyStackedBarChart(activities: activities)
                        .frame(height: 220)
                }
                .padding(DesignSystem.Layout.padding.card)
                .glassCard(cornerRadius: 24)

                AssignmentsDueTodayCompactList(assignmentsStore: assignmentsStore) { task in
                    // navigate to Assignments page and focus date
                    appModel.selectedPage = .assignments
                    if let due = task.due {
                        appModel.requestedAssignmentDueDate = due
                    }
                }

                Spacer()
            }
        }
    }
#endif
