import SwiftUI

enum DashboardCardMode: Equatable {
    case full
    case compactEmpty
}

enum EmptyStatePolicy {
    static func mode(hasData: Bool) -> DashboardCardMode {
        hasData ? .full : .compactEmpty
    }
}

struct DashboardCompactState {
    let title: String
    let description: String
    let actionTitle: String
    let action: () -> Void
}

/// Unified dashboard card - enforces consistent styling
/// Hero cards get more grid space, not different style
struct DashboardCard<Content: View, HeaderContent: View, FooterContent: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> HeaderContent
    @ViewBuilder let footer: () -> FooterContent

    var isLoading: Bool = false
    var mode: DashboardCardMode = .full
    var compactState: DashboardCompactState?

    init(
        title: String,
        isLoading: Bool = false,
        mode: DashboardCardMode = .full,
        compactState: DashboardCompactState? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> HeaderContent = { EmptyView() },
        @ViewBuilder footer: @escaping () -> FooterContent = { EmptyView() }
    ) {
        self.title = title
        self.isLoading = isLoading
        self.mode = mode
        self.compactState = compactState
        self.content = content
        self.header = header
        self.footer = footer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.cardContentSpacing) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                if mode == .full {
                    header()
                }
            }

            if isLoading {
                loadingState
            } else if mode == .compactEmpty, let compactState {
                DashboardCompactEmptyState(state: compactState)
            } else {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if mode == .full, !(footer() is EmptyView) {
                footer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Space.cardPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Space.cardCornerRadius))
        .animation(.easeInOut(duration: 0.25), value: mode)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary)
                    .frame(height: 20)
            }
        }
        .redacted(reason: .placeholder)
    }
}

// Convenience initializer without header/footer
extension DashboardCard where HeaderContent == EmptyView, FooterContent == EmptyView {
    init(
        title: String,
        isLoading: Bool = false,
        mode: DashboardCardMode = .full,
        compactState: DashboardCompactState? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isLoading = isLoading
        self.mode = mode
        self.compactState = compactState
        self.content = content
        self.header = { EmptyView() }
        self.footer = { EmptyView() }
    }
}

// MARK: - Dashboard Grid

struct AdaptiveDashboardGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.layoutMetrics) private var metrics

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300, maximum: 600), spacing: 20)
                ],
                spacing: 20
            ) {
                content()
            }
            .padding(metrics.cardPadding)
            .padding(.bottom, 100) // Dock clearance
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Empty State View

struct DashboardEmptyState: View {
    let title: String
    let systemImage: String
    let description: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.tertiary.opacity(0.35))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.tertiary.opacity(0.25))
                    .frame(width: 140, height: 6)
            }

            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
    }
}

struct DashboardCompactEmptyState: View {
    let state: DashboardCompactState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(state.description)
                .font(.caption)
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.tertiary.opacity(0.35))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.tertiary.opacity(0.25))
                    .frame(width: 120, height: 6)
            }
            Button(state.actionTitle, action: state.action)
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stat Row

struct DashboardStatRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
    }
}

// MARK: - Quick Action Button

struct DashboardQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ButtonStyle = .borderedProminent

    enum ButtonStyle {
        case borderedProminent
        case bordered
        case plain
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyleForType(style)
        .controlSize(.small)
    }
}

extension View {
    func buttonStyleForType(_ type: DashboardQuickAction.ButtonStyle) -> some View {
        Group {
            switch type {
            case .borderedProminent:
                self.buttonStyle(.itoriLiquidProminent)
            case .bordered:
                self.buttonStyle(.itariLiquid)
            case .plain:
                self.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Row 3: Operational Cards

/// Compact list of upcoming assignments (max 5)
struct UpcomingAssignmentsCard: View {
    let assignments: [Assignment]
    let courseTitles: [UUID: String]
    let onSelect: (Assignment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if assignments.isEmpty {
                Text(NSLocalizedString(
                    "ui.no.upcoming.assignments",
                    value: "No upcoming assignments",
                    comment: "No upcoming assignments"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                ForEach(Array(assignments.prefix(5))) { assignment in
                    Button(action: { onSelect(assignment) }) {
                        AssignmentRowCompact(
                            assignment: assignment,
                            courseTitle: assignment.courseId.flatMap { courseTitles[$0] }
                        )
                    }
                    .buttonStyle(.plain)

                    if assignment.id != assignments.prefix(5).last?.id {
                        Divider()
                            .padding(.leading, 0)
                    }
                }
            }
        }
    }
}

struct AssignmentRowCompact: View {
    let assignment: Assignment
    let courseTitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let course = courseTitle {
                        Text(course)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(NSLocalizedString("ui.", value: "•", comment: "•"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(assignment.dueDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if assignment.estimatedMinutes > 0 {
                Text(verbatim: "\(assignment.estimatedMinutes)m")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

/// Mini calendar or next event display
struct CalendarTimeCard: View {
    let nextEvent: DashboardCalendarEvent?
    let onOpenCalendar: () -> Void

    var body: some View {
        Button(action: onOpenCalendar) {
            VStack(alignment: .leading, spacing: 8) {
                if let event = nextEvent {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(event.startDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                } else {
                    HStack {
                        Text(NSLocalizedString(
                            "ui.no.upcoming.events",
                            value: "No upcoming events",
                            comment: "No upcoming events"
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Energy selector or planner action
struct EnergyActionsCard: View {
    @Binding var energyLevel: EnergyLevel
    let onOpenPlanner: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("ui.energy.level", value: "Energy Level", comment: "Energy Level"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            energySelector

            Divider()
                .padding(.vertical, 4)

            plannerButton
        }
    }

    private var energySelector: some View {
        HStack(spacing: 8) {
            ForEach(EnergyLevel.allCases, id: \.self) { level in
                energyButton(for: level)
            }
        }
    }

    private func energyButton(for level: EnergyLevel) -> some View {
        Button(action: { energyLevel = level }) {
            Text(level.label)
                .font(.subheadline)
                .foregroundStyle(energyLevel == level ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(energyLevel == level ? level.color : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var plannerButton: some View {
        Button(action: onOpenPlanner) {
            HStack {
                Label(
                    NSLocalizedString("ui.label.open.planner", value: "Open Planner", comment: "Open Planner"),
                    systemImage: "calendar.badge.plus"
                )
                .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

struct DashboardCalendarEvent: Identifiable {
    let id: UUID
    let title: String
    let startDate: Date
}

// MARK: - Preview

#if !DISABLE_PREVIEWS
    #Preview("Dashboard Components") {
        PreviewWrapper()
    }

    private struct PreviewWrapper: View {
        @Environment(\.layoutMetrics) private var metrics

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic card
                    DashboardCard(title: "Overview") {
                        VStack(alignment: .leading, spacing: 8) {
                            DashboardStatRow(label: "Events", value: "5", icon: "calendar")
                            DashboardStatRow(label: "Tasks", value: "12", icon: "checkmark.circle")
                        }
                    }

                    // Card with footer actions
                    DashboardCard(
                        title: "Assignments"
                    ) {
                        Text(NSLocalizedString(
                            "ui.3.assignments.due.today",
                            value: "3 assignments due today",
                            comment: "3 assignments due today"
                        ))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    } header: {
                        Button {
                            DebugLogger.log("Add tapped")
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add assignment")
                        .buttonStyle(.plain)
                        .font(.headline)
                    } footer: {
                        DashboardQuickAction(
                            title: "View All",
                            icon: "arrow.right",
                            action: {},
                            style: .bordered
                        )
                    }

                    // Loading state
                    DashboardCard(title: "Loading", isLoading: true) {
                        EmptyView()
                    }

                    // Empty state
                    DashboardCard(title: "Events") {
                        DashboardEmptyState(
                            title: "No Events",
                            systemImage: "calendar.badge.exclamationmark",
                            description: "Add your first event to get started",
                            action: { DebugLogger.log("Add event") },
                            actionTitle: "Add Event"
                        )
                    }
                }
                .padding(metrics.cardPadding)
            }
            .frame(width: 400, height: 800)
        }
    }
#endif
